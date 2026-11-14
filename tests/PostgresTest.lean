module

import Espal
meta import Espal

/-!
Tests for `espal-postgres` against a real server. `lake exe postgres-test` reads a libpq
connection string from `ESPAL_TEST_DATABASE`, and fails when the variable is missing, so a run
that tested nothing can't pass. The role must be allowed to end its own other sessions, as a
superuser or a member of `pg_signal_backend` is.

`lake test` doesn't run these, since it needs no services.
-/

open Espal Espal.Postgres Std.Async Routing

/-- Fails the run with `message` unless `ok`. -/
def check (message : String) (ok : Bool) : IO Unit :=
  unless ok do
    throw (IO.userError message)

/-- The error message of `action`, or `none` when it succeeds. -/
def failure? {α : Type} (action : Async α) : IO (Option String) := do
  match ← (Async.block action).toBaseIO with
  | .ok _ =>
    return none
  | .error error =>
    return some (toString error)

/-- Whether `needle` occurs in `text`. -/
def mentions (text needle : String) : Bool :=
  (text.splitOn needle).length > 1

/-! ## A table served from the database -/

def listItems (_ : Public) : Handler Text := do
  let rows ← query ⟨"select name from espal_test_items order by id", #[]⟩
  return ", ".intercalate (rows.toList.map fun row => ((row[0]?).getD none).getD "null")

def addItem (_ : Public) (name : String) : Handler Text := do
  let rows ← statement ⟨"insert into espal_test_items (name) values ($1) returning id", #[name]⟩
  return s!"added {rows.size}"

def sneakyDelete (_ : Public) : Handler Text := do
  let _ ← query ⟨"delete from espal_test_items", #[]⟩
  return "deleted"

api Items where
  GET "/items" => listItems
  POST "/items/:name" => addItem
  GET "/sneaky" => sneakyDelete

/-- The status and body of `Items`' answer to a request, served with `database`. -/
def request (database : Database) (method : Std.Http.Method) (path : List String) :
    IO (Option (UInt16 × String)) := do
  match Items.reply? method path [] none .empty with
  | none =>
    return none
  | some _ =>
    match matchTable Items.routes method path with
    | some (_, endpoint) =>
      match endpoint with
      | .noBody run =>
        match ← (Async.block ((run []).run database)).toBaseIO with
        | .ok reply =>
          return some (reply.status, (String.fromUTF8? reply.body).getD "")
        | .error _ =>
          return some (500, "")
      | .withBody .. =>
        return none
    | none =>
      return none

/-- Every check, against the pool's database. -/
def checks (pool : Pool) : IO Unit := do
  let database := pool.database
  let run (s : Statement) : IO Rows := Async.block (database.statement s)
  let read (s : Statement) : IO Rows := Async.block (database.query s)
  -- A wrong connection string fails at startup, and the error holds no password.
  match
    ←
      (Pool.connect
            (.wrap "host=127.0.0.1 port=1 password=hunter2 connect_timeout=2")).toBaseIO with
  | .ok _ =>
    throw (IO.userError "a pool connected to a port nobody listens on")
  | .error error =>
    check s!"a failed connection should not print the password, got {error}"
        !(mentions (toString error) "hunter2")
  discard <| run ⟨"drop table if exists espal_test_items", #[]⟩
  discard <| run ⟨"create table espal_test_items (id serial primary key, name text)", #[]⟩
  -- Parameters travel beside the SQL, so text that looks like SQL is stored as text.
  let tricky := ["plain", "it's", "'; drop table espal_test_items; --", "ünïcödé ✓", "", "$1"]
  for name in tricky do
    discard <| run ⟨"insert into espal_test_items (name) values ($1)", #[name]⟩
  discard <| run ⟨"insert into espal_test_items (name) values (null)", #[]⟩
  let rows ← read ⟨"select name from espal_test_items order by id", #[]⟩
  check s!"the rows should hold what was sent, got {repr rows}"
      (rows == (tricky.map fun name => #[some name]).toArray ++ #[#[none]])
  -- A statement with no rows gives none, and several columns arrive in order.
  let rows ← read ⟨"select id, name from espal_test_items where name = $1", #["it's"]⟩
  check s!"one row with two columns, got {repr rows}" (rows == #[#[some "2", some "it's"]])
  let rows ← read ⟨"select name from espal_test_items where id = $1", #["999"]⟩
  check s!"no rows, got {repr rows}" (rows == #[])
  -- The read-only sessions refuse a write, whatever the handler called it.
  let refused ← failure? (database.query ⟨"delete from espal_test_items", #[]⟩)
  check s!"a query that deletes should be refused with 25006, got {repr refused}"
      ((refused.map (mentions · "25006")).getD false)
  let refused ← failure? (database.query ⟨"insert into espal_test_items (name) values ('x')", #[]⟩)
  check s!"a query that inserts should be refused with 25006, got {repr refused}"
      ((refused.map (mentions · "25006")).getD false)
  -- A `select` that calls a function which writes is refused too.
  discard <|
      run
        ⟨"create or replace function espal_test_add() returns int language sql as $$ insert into espal_test_items (name) values ('sneaked') returning id $$",
          #[]⟩
  let refused ← failure? (database.query ⟨"select espal_test_add()", #[]⟩)
  check s!"a query that calls a writing function should be refused with 25006, got {repr refused}"
      ((refused.map (mentions · "25006")).getD false)
  discard <| run ⟨"drop function espal_test_add()", #[]⟩
  let rows ← read ⟨"select count(*) from espal_test_items", #[]⟩
  check s!"the refused writes should change nothing, got {repr rows}" (rows == #[#[some "7"]])
  -- A refused statement fails alone, and its connection keeps working.
  for _ in [0:4] do
    let refused ← failure? (database.statement ⟨"select from where", #[]⟩)
    check s!"a syntax error should be refused with 42601, got {repr refused}"
        ((refused.map (mentions · "42601")).getD false)
    let rows ← run ⟨"select 1", #[]⟩
    check s!"the connection should still answer, got {repr rows}" (rows == #[#[some "1"]])
  -- One statement per call: a second statement in the text is refused, and nothing runs.
  let refused ← failure? (database.statement ⟨"select 1; delete from espal_test_items", #[]⟩)
  check s!"two statements in one text should be refused, got {repr refused}" refused.isSome
  let rows ← read ⟨"select count(*) from espal_test_items", #[]⟩
  check s!"the refused text should change nothing, got {repr rows}" (rows == #[#[some "7"]])
  -- Many statements in flight at once each get their own answer.
  let tasks ←
    (List.range 400).mapM fun i =>
        IO.asTask
          (Async.block
            (if i % 2 == 0 then database.query ⟨"select $1::int, pg_sleep(0.001)", #[toString i]⟩
            else database.statement ⟨"select $1::int", #[toString i]⟩))
  for (task, i) in tasks.zip (List.range 400) do
    match ← IO.wait task with
    | .ok rows =>
      check s!"statement {i} should get its own answer, got {repr rows}"
          (((rows[0]?).bind (·[0]?)) == some (some (toString i)))
    | .error error =>
      throw (IO.userError s!"statement {i} failed: {error}")
  -- When the server ends every other session, the pool replaces them. No statement sent after
  -- that fails, since each connection notices the loss while it is idle.
  discard <|
      run
        ⟨"select pg_terminate_backend(pid) from pg_stat_activity where usename = current_user and pid <> pg_backend_pid()",
          #[]⟩
  IO.sleep 500
  for i in [0:16] do
    let rows ← read ⟨"select $1::int", #[toString i]⟩
    check s!"read {i} after the sessions ended, got {repr rows}" (rows == #[#[some (toString i)]])
    let rows ← run ⟨"select $1::int", #[toString i]⟩
    check s!"write {i} after the sessions ended, got {repr rows}" (rows == #[#[some (toString i)]])
  let refused ← failure? (database.query ⟨"delete from espal_test_items", #[]⟩)
  check s!"a replaced read-only session should still refuse a write, got {repr refused}"
      ((refused.map (mentions · "25006")).getD false)
  -- A statement in flight when its session ends fails, and the pool doesn't send it again.
  let slow ← IO.asTask (Async.block (database.statement ⟨"select pg_sleep(5)", #[]⟩))
  IO.sleep 300
  discard <|
      (Async.block
          (database.statement
            ⟨"select pg_terminate_backend(pid) from pg_stat_activity where usename = current_user and pid <> pg_backend_pid()",
              #[]⟩)).toBaseIO
  match ← IO.wait slow with
  | .ok rows =>
    throw (IO.userError s!"a statement on an ended session answered {repr rows}")
  | .error _ =>
    pure ()
  IO.sleep 500
  let rows ← run ⟨"select 1", #[]⟩
  check s!"the pool should answer after the loss, got {repr rows}" (rows == #[#[some "1"]])
  -- A served table reads and writes through the pool.
  let added ← request database .post ["items", "served"]
  check s!"POST /items/served should add a row, got {repr added}" (added == some (200, "added 1"))
  let listed ← request database .get ["items"]
  check s!"GET /items should list the rows, got {repr listed}"
      (listed == some (200, ", ".intercalate (tricky ++ ["null", "served"])))
  -- The table accepts this handler, since it calls `query`. Postgres refuses its SQL.
  let sneaky ← request database .get ["sneaky"]
  check s!"GET /sneaky should fail, got {repr sneaky}" (sneaky == some (500, ""))
  let listed ← request database .get ["items"]
  check s!"the rows should survive GET /sneaky, got {repr listed}"
      (listed == some (200, ", ".intercalate (tricky ++ ["null", "served"])))
  discard <| run ⟨"drop table espal_test_items", #[]⟩

public def main : IO UInt32 := do
  let some conninfo ←
    IO.getEnv
        "ESPAL_TEST_DATABASE" | throw (IO.userError "set ESPAL_TEST_DATABASE to a libpq connection string")
  let pool ← Pool.connect (.wrap conninfo) (size := 2)
  let outcome ← (checks pool).toBaseIO
  -- The pool is closed on a failure too, since its tasks would keep the process alive.
  pool.close
  match outcome with
  | .ok () =>
    IO.println "postgres-test: every check passed"
    return 0
  | .error error =>
    IO.eprintln s!"postgres-test failed: {error}"
    return 1
