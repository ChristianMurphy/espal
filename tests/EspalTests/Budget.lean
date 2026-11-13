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
  let rows ← statement (select id)
  if rows.isEmpty then
    log "missing"
    return "none"
  let more ← statement ⟨"select count(*) from users", #[]⟩
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
  let rows ← statement (select id)
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
  let rows ← statement (select id)
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
  let rows ← statement ⟨"select count(*) from users", #[]⟩
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
  statement (select id)

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
  let rows ← statement (select id)
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

/-! A loop over statements has no bound the walk can find. The error shows the loop. -/

/--
error: `@[budget]` found no bound for `BudgetTests.perItem`, because it can't follow
  List.mapM (fun id => statement (select id)) ids
A loop over statements needs a bound that is proved by hand.
-/
#guard_msgs in
@[budget]
def perItem (_ : Public) (ids : List Nat) : Handler Nat := do
  let rows ← ids.mapM fun id => statement (select id)
  return rows.length

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
  let rows ← statement ⟨"select 1", #[]⟩
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
  let a ← statement ⟨"a", #[]⟩
  return a.size

/--
error: `BudgetTests.heavy` may send 12 database statements, and this route's limit is 10.
Raise the limit on the row with `limit 12`, or send fewer.
-/
#guard_msgs in
api Heavy where
  GET "/heavy" => heavy

def eleven (_ : Public) : Handler Nat := do
  let _ ← statement ⟨"1", #[]⟩
  let _ ← statement ⟨"2", #[]⟩
  let _ ← statement ⟨"3", #[]⟩
  let _ ← statement ⟨"4", #[]⟩
  let _ ← statement ⟨"5", #[]⟩
  let _ ← statement ⟨"6", #[]⟩
  let _ ← statement ⟨"7", #[]⟩
  let _ ← statement ⟨"8", #[]⟩
  let _ ← statement ⟨"9", #[]⟩
  let _ ← statement ⟨"10", #[]⟩
  let last ← statement ⟨"11", #[]⟩
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
  GET "/branchy/:id" => branchy limit 3
  GET "/twice/:id" => twice
  GET "/eleven" => eleven
  GET "/greeting" => greeting

/--
info: method  path          handler               budget  limit
GET     /users/:id    BudgetTests.find      2       20
PUT     /users/:id    BudgetTests.rename    2       20
GET     /unmarked     BudgetTests.unmarked  1       20
GET     /branchy/:id  BudgetTests.branchy   3       3
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
