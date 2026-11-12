module

import EspalJson
meta import EspalJson
import EspalRoute
meta import EspalRoute

/-!
Tests for statement budgets. `@[budget n]` proves where a handler is defined that it sends at most
`n` database statements, and `Costs.sent_le` carries that bound to every run. An `api` table
refuses a handler that may send more than ten.
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

/-! A budget below what the handler can send is an error that names the statement it stopped
at. -/

/--
error: `BudgetTests.tooMany` may send more than 1 database statement. The budget ran out at:
  statement { sql := "b" }
-/
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

/-! The attribute is only for handlers that return a program. -/

/--
error: `@[budget 3]` is for a handler that returns `Handler α` or `Fails ε α`, and `BudgetTests.plain` returns `Text`.
-/
#guard_msgs in
@[budget 3]
def plain (_ : Public) : Text :=
  "x"

/-! ## Budgets in a table

A table accepts a handler with a budget within ten, and proves the budget itself for a handler
that has none. -/

def unmarked (_ : Public) : Handler Text := do
  let rows ← statement ⟨"select 1", #[]⟩
  return s!"{rows.size}"

api Users where
  GET "/users/:id" => find
  PUT "/users/:id" => rename
  GET "/unmarked" => unmarked

/-- info: BudgetTests.unmarked.budget (x✝ : Public) : Costs (unmarked x✝) 10 -/
#guard_msgs in
#check unmarked.budget

#guard
  (Users.reply? .get ["users", "7"] (world := { clock := 1, rows := [#[#[some "Ada"]]] })).map
      (fun reply => String.fromUTF8? reply.body) ==
    some (some "1 1 0")

#guard (Users.reply? .put ["users", "7"]).map (·.status) == some 404

/-! A handler whose budget is over ten, stated or not, is refused. -/

@[budget 12]
def heavy (_ : Public) : Handler Nat := do
  let a ← statement ⟨"a", #[]⟩
  return a.size

/--
error: `BudgetTests.heavy` has `@[budget 12]`, and a route may send at most 10 database statements.
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
error: `BudgetTests.eleven` may send more than 10 database statements. The budget ran out at:
  statement { sql := "11" }
-/
#guard_msgs in
api Eleven where
  GET "/eleven" => eleven

end BudgetTests
