module

import EspalJson
meta import EspalJson
import EspalRoute
meta import EspalRoute

/-!
Tests for statement budgets. `@[budget n]` proves where a handler is defined that it sends at most
`n` database statements, and `@[budget]` infers the least such `n`. `Costs.sent_le` carries the
bound to every run. An `api` table refuses a handler that may send more than its limit.
-/

open Espal Routing Json

namespace BudgetTests

inductive FindError where
  | notFound
  | gone
  deriving Problem

def select (id : Nat) : Statement :=
  ⟨"select name from users where id = $1", #[toString id]⟩

@[budget 2]
def find (_ : Public) (id : Nat) : Handler Text := do
  let t ← now
  let rows ← query (select id)
  if rows.isEmpty then
    log "missing"
    return "none"
  let more ← query ⟨"select count(*) from users", #[]⟩
  return s!"{t} {rows.size} {more.size}"

/-- info: BudgetTests.find.budget (x✝ : Public) (id : Nat) : Costs (find x✝ id) 2 -/
#guard_msgs in
#check find.budget

/--
info: '_private.EspalTests.Budget.0.BudgetTests.find.budget' depends on axioms: [propext, Quot.sound]
-/
#guard_msgs in
#print axioms find.budget

/-! A handler that can fail gets the theorem about the program under it. The budget covers the
path that fails early and the path that doesn't. -/

@[budget 2]
def rename (_ : Public) (id : Nat) : Fails FindError Text := do
  let rows ← query (select id)
  if rows.isEmpty then
    throw .notFound
  let t ← now
  if t > 100 then
    log "too late"
    throw .gone
  let _ ← statement ⟨"update users set name = $2 where id = $1", #[toString id, "Ada"]⟩
  return "renamed"

/--
info: BudgetTests.rename.budget (x✝ : Public) (id : Nat) : Costs (ExceptT.run (rename x✝ id)) 2
-/
#guard_msgs in
#check rename.budget

/-! A run sends what the program asks for, in order, and gets the rows the world holds. -/

#guard
  ((find {} 7).eval { clock := 5, rows := [#[#[some "Ada"]], #[#[some "3"]]] }) ==
    (("5 1 1" : Text), { clock := 5, sent := [select 7, ⟨"select count(*) from users", #[]⟩] })

#guard ((find {} 7).eval { clock := 5 }).2.sent == [select 7]

/-! `Costs.sent_le` turns the proved budget into a bound on every run. -/

example (id : Nat) (world : World) :
    ((find {} id).eval world).2.sent.length ≤ world.sent.length + 2 :=
  (find.budget {} id).sent_le world

example (id : Nat) (world : World) :
    ((rename {} id).run.eval world).2.sent.length ≤ world.sent.length + 2 :=
  (rename.budget {} id).sent_le world

/-! A budget below what the handler can send is an error that says how many it can send. -/

/-- error: `BudgetTests.tooMany` may send 2 database statements, and its budget is 1. -/
#guard_msgs in
@[budget 1]
def tooMany (_ : Public) : Handler Nat := do
  let a ← statement ⟨"a", #[]⟩
  let b ← statement ⟨"b", #[]⟩
  return a.size + b.size

/-! A larger budget than needed is accepted, and a handler that sends nothing fits zero. -/

@[budget 5]
def roomy (_ : Public) : Handler Nat := do
  let a ← statement ⟨"a", #[]⟩
  return a.size

@[budget 0]
def quiet (_ : Public) : Handler Nat := do
  let t ← now
  log "quiet"
  return t

/-! ## Inferred budgets

`@[budget]` with no number proves the least bound. For sequences and branches that is the exact
worst case, counted over the path that sends the most. -/

@[budget]
def branchy (_ : Public) (id : Nat) : Fails FindError Text := do
  let rows ← query (select id)
  if rows.isEmpty then
    throw .notFound
  let _ ← statement ⟨"insert into audit values ($1)", #[toString id]⟩
  let _ ← statement ⟨"update counters set n = n + 1", #[]⟩
  return "ok"

/--
info: BudgetTests.branchy.budget (x✝ : Public) (id : Nat) : Costs (ExceptT.run (branchy x✝ id)) 3
-/
#guard_msgs in
#check branchy.budget

@[budget]
def silent (_ : Public) : Handler Nat := do
  let t ← now
  return t + 1

/-- info: BudgetTests.silent.budget (x✝ : Public) : Costs (silent x✝) 0 -/
#guard_msgs in
#check silent.budget

/-! A call to a handler or helper with a proved budget costs that budget, so budgets add up
through calls. A `Fails` helper called from a `Fails` handler works the same way. -/

@[budget]
def twice (_ : Public) (id : Nat) : Handler Text := do
  let first ← find {} id
  let second ← find {} (id + 1)
  log "both found"
  return s!"{first.text} {second.text}"

/-- info: BudgetTests.twice.budget (x✝ : Public) (id : Nat) : Costs (twice x✝ id) 4 -/
#guard_msgs in
#check twice.budget

@[budget]
def renameThenCount (_ : Public) (id : Nat) : Fails FindError Text := do
  let renamed ← rename {} id
  let rows ← query ⟨"select count(*) from users", #[]⟩
  return s!"{renamed.text} {rows.size}"

/--
info: BudgetTests.renameThenCount.budget (x✝ : Public) (id : Nat) : Costs (ExceptT.run (renameThenCount x✝ id)) 3
-/
#guard_msgs in
#check renameThenCount.budget

#guard
  ((twice {} 7).eval
        { clock := 1, rows := [#[#[some "a"]], #[], #[#[some "b"]], #[]] }).2.sent.length ==
    4

/-! A pinned budget must still cover the helpers the handler calls. -/

/-- error: `BudgetTests.pinnedLow` may send 4 database statements, and its budget is 3. -/
#guard_msgs in
@[budget 3]
def pinnedLow (_ : Public) (id : Nat) : Handler Text := do
  let first ← find {} id
  let second ← find {} (id + 1)
  return first.text ++ second.text

/-! A helper with no `budget` theorem is unfolded, so its statements count too. -/

def helperNoBudget (id : Nat) : Handler Rows :=
  query (select id)

@[budget]
def viaUnmarked (_ : Public) (id : Nat) : Handler Nat := do
  let rows ← helperNoBudget id
  let more ← helperNoBudget (id + 1)
  return rows.size + more.size

/-- info: BudgetTests.viaUnmarked.budget (x✝ : Public) (id : Nat) : Costs (viaUnmarked x✝ id) 2 -/
#guard_msgs in
#check viaUnmarked.budget

/-! A `match` costs its dearest alternative. -/

@[budget]
def firstRow (_ : Public) (id : Nat) : Fails FindError Text := do
  let rows ← query (select id)
  match rows[0]? with
  | none =>
    throw .notFound
  | some row =>
    let _ ← statement ⟨"update users set seen = now() where id = $1", #[toString id]⟩
    return s!"{row.size}"

/--
info: BudgetTests.firstRow.budget (x✝ : Public) (id : Nat) : Costs (ExceptT.run (firstRow x✝ id)) 2
-/
#guard_msgs in
#check firstRow.budget

/-! ## Loops

A loop costs the bound on its list's length times the most one pass can send. A `Clamp` count
gives the bound through `List.range`. -/

abbrev Count :=
  Clamp 1 500

@[budget]
def queries (_ : Public) (count : Count) : Handler Text := do
  let rows ← (List.range count.val).mapM fun i => query (select i)
  return s!"{rows.length}"

/--
info: BudgetTests.queries.budget (x✝ : Public) (count : Count) : Costs (queries x✝ count) 500
-/
#guard_msgs in
#check queries.budget

/-! A run sends one statement for each item, which is within the bound. -/

#guard ((queries {} (.ofNat (by decide) 3)).eval { clock := 0 }).2.sent.length == 3

/-! `.take n` bounds a `for` loop, and each pass may send several statements. -/

@[budget]
def firstTwenty (_ : Public) (ids : List Nat) : Handler Nat := do
  let mut total := 0
  for id in ids.take 20 do
    let rows ← query (select id)
    let more ← query (select (id + 1))
    total := total + rows.size + more.size
  return total

/--
info: BudgetTests.firstTwenty.budget (x✝ : Public) (ids : List Nat) : Costs (firstTwenty x✝ ids) 40
-/
#guard_msgs in
#check firstTwenty.budget

#guard ((firstTwenty {} (List.range 50)).eval { clock := 0 }).2.sent.length == 40

/-! A proof field on the input bounds a loop over the field it names. The loop below can also
fail, and it sits after a statement of its own. -/

structure Batch where
  ids : List Int32
  small : ids.length ≤ 100
  deriving Json

@[budget]
def batch (_ : Public) (b : Batch) : Fails FindError Text := do
  let header ← statement ⟨"begin", #[]⟩
  for id in b.ids do
    let rows ← query ⟨"select name from users where id = $1", #[toString id.toInt]⟩
    if rows.isEmpty then
      throw .notFound
  return s!"{header.size}"

/--
info: BudgetTests.batch.budget (x✝ : Public) (b : Batch) : Costs (ExceptT.run (batch x✝ b)) 101
-/
#guard_msgs in
#check batch.budget

/--
info: '_private.EspalTests.Budget.0.BudgetTests.batch.budget' depends on axioms: [propext, Quot.sound]
-/
#guard_msgs in
#print axioms batch.budget

/-! A hypothesis in scope bounds a loop the same way. -/

@[budget]
def bounded (_ : Public) (ids : List Nat) (_ : ids.length ≤ 7) : Handler Nat := do
  let rows ← ids.mapM fun id => query (select id)
  return rows.length

/--
info: BudgetTests.bounded.budget (x✝ : Public) (ids : List Nat) (x✝¹ : ids.length ≤ 7) : Costs (bounded x✝ ids x✝¹) 7
-/
#guard_msgs in
#check bounded.budget

/-! Nested loops multiply. -/

@[budget]
def nested (_ : Public) (b : Batch) (count : Count) : Handler Nat := do
  let mut n := 0
  for _ in b.ids do
    for i in List.range count.val do
      let rows ← query (select i)
      n := n + rows.size
  return n

/--
info: BudgetTests.nested.budget (x✝ : Public) (b : Batch) (count : Count) : Costs (nested x✝ b count) 50000
-/
#guard_msgs in
#check nested.budget

/-! Lean can't split a `match` on an array pattern, so the walk stops there and says how to read
the cell another way. -/

/--
error: `@[budget]` found no bound for `BudgetTests.firstCell`, because Lean can't split
  match rows[0]? with
  | some #[some name] => pure name
  | x => throw FindError.notFound
That happens for an array pattern such as `#[a]`. Read the cell with `row[0]?` and match on what it gives.
-/
#guard_msgs in
@[budget]
def firstCell (_ : Public) (id : Nat) : Fails FindError String := do
  let rows ← query (select id)
  match rows[0]? with
  | some #[some name] =>
    return name
  | _ =>
    throw .notFound

@[budget]
def firstCellByIndex (_ : Public) (id : Nat) : Fails FindError String := do
  let rows ← query (select id)
  let some row := rows[0]? | throw .notFound
  let some (some name) := row[0]? | throw .notFound
  return name

/--
info: BudgetTests.firstCellByIndex.budget (x✝ : Public) (id : Nat) : Costs (ExceptT.run (firstCellByIndex x✝ id)) 1
-/
#guard_msgs in
#check firstCellByIndex.budget

/-! A loop over a list with no bound is an error that shows the list. That includes a statement
for each row of a result, which has no bound until queries carry their limit. -/

/--
error: `@[budget]` found no bound for `BudgetTests.perItem`, because the loop over
  ids
has no bound on its length. Take at most `n` items with `.take n`, count with a `Clamp`, or give the input a proof field such as `small : items.length ≤ n`.
-/
#guard_msgs in
@[budget]
def perItem (_ : Public) (ids : List Nat) : Handler Nat := do
  let rows ← ids.mapM fun id => query (select id)
  return rows.length

/--
error: `@[budget]` found no bound for `BudgetTests.perRow`, because the loop over
  rows.toList
has no bound on its length. Take at most `n` items with `.take n`, count with a `Clamp`, or give the input a proof field such as `small : items.length ≤ n`.
-/
#guard_msgs in
@[budget]
def perRow (_ : Public) : Handler Nat := do
  let rows ← query ⟨"select id from users", #[]⟩
  let mut n := 0
  for row in rows.toList do
    let more ← query ⟨"select name from users where id = $1", #[toString row.size]⟩
    n := n + more.size
  return n

/-! The `budget` tactic proves a bound stated by hand, and refuses one that is too small. -/

example (id : Nat) : Costs (find {} id) 5 := by budget

example (id : Nat) : Costs (rename {} id).run 2 := by budget

/-- error: the program may send 2 database statements, and the goal allows 1. -/
#guard_msgs in
example (id : Nat) : Costs (find {} id) 1 := by budget

/-! The attribute is only for handlers that return a program. -/

/--
error: `@[budget]` is for a handler that returns `Handler α` or `Fails ε α`, and `BudgetTests.plain` returns `Text`.
-/
#guard_msgs in
@[budget 3]
def plain (_ : Public) : Text :=
  "x"

/-! ## Budgets in a table

A table accepts a handler with a budget within its limit, and infers the budget of a handler
that has none. With no limit stated, the limit is the option `espal.statementLimit`, which is 10. -/

def unmarked (_ : Public) : Handler Text := do
  let rows ← query ⟨"select 1", #[]⟩
  return s!"{rows.size}"

api Users where
  GET "/users/:id" => find
  PUT "/users/:id" => rename
  GET "/unmarked" => unmarked

/-- info: BudgetTests.unmarked.budget (x✝ : Public) : Costs (unmarked x✝) 1 -/
#guard_msgs in
#check unmarked.budget

#guard
  (Users.reply? .get ["users", "7"] (world := { clock := 1, rows := [#[#[some "Ada"]]] })).map
      (fun reply => String.fromUTF8? reply.body) ==
    some (some "1 1 0")

#guard (Users.reply? .put ["users", "7"]).map (·.status) == some 404

/-! A handler whose budget is over the limit, stated or inferred, is refused. -/

@[budget 12]
def heavy (_ : Public) : Handler Nat := do
  let a ← query ⟨"a", #[]⟩
  return a.size

/--
error: `BudgetTests.heavy` may send 12 database statements, and this route's limit is 10.
Raise the limit on the row with `limit 12`, or send fewer.
-/
#guard_msgs in
api Heavy where
  GET "/heavy" => heavy

def eleven (_ : Public) : Handler Nat := do
  let _ ← query ⟨"1", #[]⟩
  let _ ← query ⟨"2", #[]⟩
  let _ ← query ⟨"3", #[]⟩
  let _ ← query ⟨"4", #[]⟩
  let _ ← query ⟨"5", #[]⟩
  let _ ← query ⟨"6", #[]⟩
  let _ ← query ⟨"7", #[]⟩
  let _ ← query ⟨"8", #[]⟩
  let _ ← query ⟨"9", #[]⟩
  let _ ← query ⟨"10", #[]⟩
  let last ← query ⟨"11", #[]⟩
  return last.size

/--
error: `BudgetTests.eleven` may send 11 database statements, and this route's limit is 10.
Raise the limit on the row with `limit 11`, or send fewer.
-/
#guard_msgs in
api Eleven where
  GET "/eleven" => eleven

/-! A row states its own limit, and a table states one for its rows. The row's limit wins. -/

api HeavyRow where
  GET "/heavy" => heavy limit 12
  GET "/eleven" => eleven limit 11
  GET "/unmarked" => unmarked

api Roomy (limit := 12) where
  GET "/heavy" => heavy
  GET "/eleven" => eleven

/--
error: `BudgetTests.find` may send 2 database statements, and this route's limit is 1.
Raise the limit on the row with `limit 2`, or send fewer.
-/
#guard_msgs in
api Tight (limit := 1) where
  GET "/unmarked" => unmarked
  GET "/users/:id" => find

api TightRow (limit := 1) where
  GET "/unmarked" => unmarked
  GET "/users/:id" => find limit 2

/-! A loop's budget goes through a table like any other, so the row raises its limit. -/

api Looping where
  GET "/queries" => queries limit 500
  POST "/batch" => batch limit 101

/--
error: `BudgetTests.queries` may send 500 database statements, and this route's limit is 10.
Raise the limit on the row with `limit 500`, or send fewer.
-/
#guard_msgs in
api LoopingTight where
  GET "/queries" => queries

/-! An oversized body fails its proof field, so the handler never runs. -/

#guard
  (Looping.reply? .post ["batch"] [] (some "application/json")
          ("{\"ids\":[" ++ ",".intercalate (List.replicate 101 "1") ++ "]}").toUTF8).map
      (·.status) ==
    some 422

/-! The option sets the limit for every table after it that states none. -/

set_option espal.statementLimit 12 in
api ByOption where
  GET "/heavy" => heavy

/--
error: `BudgetTests.find` may send 2 database statements, and this route's limit is 0.
Raise the limit on the row with `limit 2`, or send fewer.
-/
#guard_msgs in
set_option espal.statementLimit 0 in
api NoStatements where
  GET "/users/:id" => find

/-! `limit` stays an ordinary name outside a table. -/

def limit : Nat :=
  3

#guard limit + 1 == 4

/-! ## The route report

`#routes` lists each row with the budget its handler has, inferred or pinned, and the row's limit.
Pinning the report in a test makes a change to an inferred budget fail the build. -/

def greeting (_ : Public) : Text :=
  "hello"

api Reported (limit := 20) where
  GET "/users/:id" => find
  PUT "/users/:id" => rename
  GET "/unmarked" => unmarked
  POST "/branchy/:id" => branchy limit 3
  GET "/twice/:id" => twice
  GET "/eleven" => eleven
  GET "/greeting" => greeting

/--
info: method  path          handler               budget  limit
GET     /users/:id    BudgetTests.find      2       20
PUT     /users/:id    BudgetTests.rename    2       20
GET     /unmarked     BudgetTests.unmarked  1       20
POST    /branchy/:id  BudgetTests.branchy   3       3
GET     /twice/:id    BudgetTests.twice     4       20
GET     /eleven       BudgetTests.eleven    11      20
GET     /greeting     BudgetTests.greeting  -       20
-/
#guard_msgs in
#routes Reported

/-- error: `BudgetTests.limit` isn't a table that an `api` command declared. -/
#guard_msgs in
#routes limit

end BudgetTests
