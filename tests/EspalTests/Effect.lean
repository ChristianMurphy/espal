module

import EspalCore
meta import EspalCore

/-!
Tests for effects as data. A handler built from `now`, `random` and `log` runs against a supplied
`World` with no `IO`, and against the machine with `Eff.run`. A program over a test signature with
one paid operation stays within the bound in its type.
-/

open Espal LeanLinq

namespace EffectTests

def greet (name : String) : Eff String := do
  let t ← now
  log s!"greeting {name} at {t}"
  if t % 2 == 0 then
    let roll ← random 1 6
    return s!"Hello, {name}! Roll {roll}."
  return s!"Hello, {name}! It is {t}."

/-! The same program gives each world its own answer, and the log records what it wrote. -/

#guard
  (greet "Ada").eval { clock := 7 } ==
    ("Hello, Ada! It is 7.", { clock := 7, logs := ["greeting Ada at 7"] })

#guard
  (greet "Ada").eval { clock := 8, dice := [5, 2] } ==
    ("Hello, Ada! Roll 5.", { clock := 8, dice := [2], logs := ["greeting Ada at 8"] })

/-! A draw with no number left gives its lower bound. -/

#guard ((greet "Ada").eval { clock := 8 }).1 == "Hello, Ada! Roll 1."

/-! `ExceptT` adds errors, and a failing handler runs none of the steps after the failure. -/

def greetNamed (name : String) : ExceptT String Eff String := do
  if name.isEmpty then
    throw "no name"
  let t ← liftM (m := Eff) now
  liftM (m := Eff) (log "greeted")
  return s!"{name} {t}"

/-- A run's result, error and world, in a form `#guard` can compare. -/
def shown (run : Except String String × World) : Option String × Option String × World :=
  match run with
  | (.ok value, world) => (some value, none, world)
  | (.error message, world) => (none, some message, world)

#guard
  shown ((greetNamed "Bo").run.eval { clock := 3 }) ==
    (some "Bo 3", none, { clock := 3, logs := ["greeted"] })

#guard shown ((greetNamed "").run.eval { clock := 3 }) == (none, some "no name", { clock := 3 })

/-! `Eff.eval_bind` lets a proof follow a program step by step. -/

def twoLines : Eff Unit := do
  log "a"
  log "b"

example (world : World) : (twoLines.eval world).2.logs = world.logs ++ ["a", "b"] := by
  simp [twoLines, Eff.eval_bind]

/-! The machine answers the same program through `Eff.run`. -/

#eval
  show IO Unit from do
    let (t, roll) ←
      (do
            let t ← now
            let roll ← random 3 3
            return (t, roll) : Eff (Nat × Nat)).run
    unless t > 1700000000000 && roll == 3 do
      throw (IO.userError s!"the machine answered {t} and {roll}")

/-! ## A paid operation

A test signature with one free operation and one that costs a unit. -/

inductive TestOp : Type → Type 1 where
  | free : TestOp Unit
  | paid (n : Nat) : TestOp Nat

def testWp : EffWp TestOp
  | _, .free => fun post σ k => post () σ k
  | _, .paid n => fun post σ k => post n σ (k + 1)

def testCost : {β : Type} → TestOp β → Nat
  | _, .free => 0
  | _, .paid _ => 1

instance : HasBill (testWp .free) 0 :=
  ⟨fun _ σ k h => h () σ k (by simp)⟩

instance (n : Nat) : HasBill (testWp (.paid n)) 1 :=
  ⟨fun _ σ k h => h n σ (k + 1) (by simp [Grade.eval, Grade.nat])⟩

abbrev Test (α : Type) (w : Wp α) : Type 1 :=
  FreerD TestOp testWp α w

def free : Test Unit (testWp .free) :=
  FreerD.liftE TestOp.free

def paid (n : Nat) : Test Nat (testWp (.paid n)) :=
  FreerD.liftE (TestOp.paid n)

def seq {α β : Type} {w : Wp α} {w₂ : α → Wp β} (x : Test α w) (k : (a : α) → Test β (w₂ a))
    {m n : Grade} [hm : HasBill w m] [hn : HasBillF w₂ n]
    (hns : Grade.Stable n := by
      intro σ σ'; exact Nat.le_refl _) :
    Test β (Wp.bill (m + n)) :=
  FreerD.weaken (Wp.bill_bind_of_le hm.le hn.le hns) (FreerD.bindS x k)

/-- The handler counts in its state how often `paid` ran. -/
def testHandler : CostHandler TestOp testWp testCost Empty Nat fun _ _ => 0 := fun e s =>
  match e with
  | .free => .ok ⟨((), s), fun _ _ h => h⟩
  | .paid n => .ok ⟨(n, s + 1), fun _ _ h => h⟩

/-- Two paid operations around a free one. -/
def twoPaid : Test Nat (Wp.bill (1 + (0 + 1))) :=
  seq (paid 2) fun _ => seq free fun _ => paid 3

/-- The value, the handler's own count of paid runs, and the cost `runCost` reports. -/
def outcome : Option (Nat × Nat × Nat) :=
  match runCost testHandler twoPaid 0 with
  | .ok result => some result.val

/-! The reported cost is the number of paid runs, and the free operation adds nothing. -/

#guard outcome == some (3, 2, 2)

/-! The bound in the type holds for the run, by `runCost_cost_le`. -/

example {res : _} (h : runCost testHandler twoPaid 0 = .ok res) : res.val.2.2 ≤ 2 :=
  runCost_cost_le h

/-! A program doesn't fit a bound below its cost. -/

example : True := by
  fail_if_success
    have : Test Nat (Wp.bill 1) :=
      FreerD.weaken
        (Wp.le_trans (HasBill.le (w := Wp.bill (1 + (0 + 1))))
          (Wp.bill_mono
            (by
              intro σ
              exact Nat.le_of_ble_eq_true rfl)))
        twoPaid
  trivial

end EffectTests
