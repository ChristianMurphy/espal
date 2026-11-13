module

import EspalJson
meta import EspalJson
import EspalRoute
meta import EspalRoute

/-!
Tests for `ReadOnly`. A handler behind a `GET` row must leave the database as it was. It reads
with `query`, and the `api` command refuses one that sends a statement with `statement`.
`ReadOnly.written_eq` carries the claim to every run.
-/

open Espal Routing Json

namespace ReadOnlyTests

inductive FindError where
  | notFound
  deriving Problem

def select (id : Nat) : Statement :=
  ⟨"select name from users where id = $1", #[toString id]⟩

def touch (id : Nat) : Statement :=
  ⟨"update users set seen = now() where id = $1", #[toString id]⟩

/-! A run records every statement in `sent`, and only those from `statement` in `written`. -/

#guard ((query (select 1)).eval { clock := 0 }).2 == { clock := 0, sent := [select 1] }

#guard
  ((statement (touch 1)).eval { clock := 0 }).2 ==
    { clock := 0, sent := [touch 1], written := [touch 1] }

/-! A handler that reads through sequences, branches, loops, helpers and failures passes. -/

def findName (id : Nat) : Fails FindError String := do
  let rows ← query (select id)
  if rows.isEmpty then
    throw .notFound
  return s!"user {rows.size}"

def show_ (_ : Public) (id : Nat) : Fails FindError Text := do
  let name ← findName id
  if name.isEmpty then
    log "empty name"
  return name

def list (_ : Public) (count : Clamp 1 50) : Handler Text := do
  let t ← now
  let mut total := 0
  for i in List.range count.val do
    let rows ← query (select i)
    total := total + rows.size
  let names ← (List.range count.val).mapM fun i => query (select i)
  return s!"{t} {total} {names.length}"

def touchUser (_ : Public) (id : Nat) : Handler Text := do
  let _ ← statement (touch id)
  return "ok"

api Users where
  GET "/users/:id" => show_
  GET "/users" => list limit 100
  POST "/users/:id/touch" => touchUser

/--
info: ReadOnlyTests.show_.readOnly (x✝ : Public) (id : Nat) : ReadOnly (ExceptT.run (show_ x✝ id))
-/
#guard_msgs in
#check show_.readOnly

/-- info: ReadOnlyTests.list.readOnly (x✝ : Public) (count : Clamp 1 50) : ReadOnly (list x✝ count) -/
#guard_msgs in
#check list.readOnly

/--
info: '_private.EspalTests.ReadOnly.0.ReadOnlyTests.list.readOnly' depends on axioms: [propext, Quot.sound]
-/
#guard_msgs in
#print axioms list.readOnly

/-! `ReadOnly.written_eq` turns the proof into a claim about every run. -/

example (count : Clamp 1 50) (world : World) :
    ((list {} count).eval world).2.written = world.written :=
  (list.readOnly {} count).written_eq world

example (id : Nat) (world : World) : ((show_ {} id).run.eval world).2.written = world.written :=
  (show_.readOnly {} id).written_eq world

/-! A row with another method may write. -/

#guard ((touchUser {} 3).eval { clock := 0 }).2.written == [touch 3]

/-! A `GET` handler that writes is an error that shows the statement. -/

/--
error: `ReadOnlyTests.touchUser` answers a `GET` request, which must leave the database as it was, and it sends
  statement (touch id)
which may write.
Read with `query`, or give the route another method.
-/
#guard_msgs in
api Writes where
  GET "/users/:id/touch" => touchUser

/-! The write is found inside a helper, a branch and a loop. -/

def audit (id : Nat) : Handler Unit := do
  let _ ← statement ⟨"insert into audit values ($1)", #[toString id]⟩

def viaHelper (_ : Public) (id : Nat) : Fails FindError Text := do
  let name ← findName id
  if name == "admin" then
    audit id
  return name

/--
error: `ReadOnlyTests.viaHelper` answers a `GET` request, which must leave the database as it was, and it sends
  statement { sql := "insert into audit values ($1)", params := #[toString id] }
which may write.
Read with `query`, or give the route another method.
-/
#guard_msgs in
api WritesInHelper where
  GET "/users/:id" => viaHelper

def inLoop (_ : Public) (count : Clamp 1 5) : Handler Text := do
  for i in List.range count.val do
    let _ ← statement (touch i)
  return "ok"

/--
error: `ReadOnlyTests.inLoop` answers a `GET` request, which must leave the database as it was, and it sends
  statement (touch i)
which may write.
Read with `query`, or give the route another method.
-/
#guard_msgs in
api WritesInLoop where
  GET "/touch" => inLoop

/-! A handler with a plain result sends nothing, so a `GET` row takes it as it is. -/

def greeting (_ : Public) : Text :=
  "hello"

api Plain where
  GET "/greeting" => greeting

end ReadOnlyTests
