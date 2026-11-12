/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Effect

/-!
# Statement budgets

`Costs x n` says that the program `x` sends at most `n` database statements, whichever way it
branches and whatever the database answers. `Costs.sent_le` shows that a run against any `World`
sends no more than a proved bound.

The lemmas here follow a program's structure. A value costs nothing, and a statement costs one.
A sequence costs its first part plus the most its rest can cost. The `budget` tactic applies them
until it reaches the end of the program. It stops at the first statement that the remaining budget can't
pay for, so the goal it leaves shows which statement goes over.

A handler that loops over statements needs a bound on the loop, which `budget` doesn't find.
-/

@[expose] public section

namespace Espal

open LeanLinq

/-- On every path, the program sends at most `n` statements. -/
def Costs : {α : Type} → {w : Wp α} → FreerD Op opWp α w → Nat → Prop
  | _, _, .pure _, _ => True
  | _, _, .bindE e f, n => e.cost ≤ n ∧ ∀ b, Costs (f b) (n - e.cost)
  | _, _, .weaken _ x, n => Costs x n

/-- A bound that holds also holds when raised. -/
theorem Costs.mono :
    {α : Type} → {w : Wp α} → (x : FreerD Op opWp α w) → {m n : Nat} → Costs x m → m ≤ n → Costs x n
  | _, _, .pure _, _, _, _, _ => trivial
  | _, _, .bindE e f, m, n, h, hmn => by
    have h' : e.cost ≤ m ∧ ∀ b, Costs (f b) (m - e.cost) := h
    exact
      show e.cost ≤ n ∧ ∀ b, Costs (f b) (n - e.cost) from
        ⟨Nat.le_trans h'.1 hmn, fun b => Costs.mono (f b) (h'.2 b) (by omega)⟩
  | _, _, .weaken _ x, _, _, h, hmn => Costs.mono x h hmn

/-- A sequence costs at most its first part plus the most its rest can cost. -/
theorem Costs.bindS {α β : Type} {w₂ : α → Wp β} :
    {w : Wp α} →
      (x : FreerD Op opWp α w) →
      (k : (a : α) → FreerD Op opWp β (w₂ a)) →
      {m j : Nat} → Costs x m → (∀ a, Costs (k a) j) → Costs (FreerD.bindS x k) (m + j)
  | _, .pure a, k, m, j, _, hk => Costs.mono (k a) (hk a) (by omega)
  | _, .bindE e f, k, m, j, h, hk => by
    have h' : e.cost ≤ m ∧ ∀ b, Costs (f b) (m - e.cost) := h
    exact
      show e.cost ≤ m + j ∧ ∀ b, Costs (FreerD.bindS (f b) k) (m + j - e.cost) from
        ⟨by omega, fun b => Costs.mono _ (Costs.bindS (f b) k (h'.2 b) hk) (by omega)⟩
  | _, .weaken _ x, k, _, _, h, hk => Costs.bindS x k h hk

/-- A run sends no more statements than a proved bound, from any world. -/
theorem Costs.run_sent_le :
    {α : Type} →
      {w : Wp α} →
      (x : FreerD Op opWp α w) →
      {n : Nat} → Costs x n → (world : World) → (run x world).2.sent.length ≤ world.sent.length + n
  | _, _, .pure _, _, _, _ => Nat.le_add_right _ _
  | _, _, .bindE e f, n, h, world => by
    have h' : e.cost ≤ n ∧ ∀ b, Costs (f b) (n - e.cost) := h
    have step :
      run (FreerD.bindE e f) world = run (f (Op.answer e world).1) (Op.answer e world).2 := rfl
    rw [step]
    have ih := Costs.run_sent_le (f (Op.answer e world).1) (h'.2 _) (Op.answer e world).2
    have hsent : (Op.answer e world).2.sent.length = world.sent.length + e.cost := by
      cases e <;> simp [Op.answer, Op.cost]
    omega
  | _, _, .weaken _ x, _, h, world => Costs.run_sent_le x h world

/-- A run of `x` sends no more statements than a proved bound, from any world. -/
theorem Costs.sent_le {α : Type} {x : Eff α} {n : Nat} (h : Costs x n) (world : World) :
    (x.eval world).2.sent.length ≤ world.sent.length + n :=
  Costs.run_sent_le x h world

/-! ## Lemmas the `budget` tactic applies -/

theorem costs_pure {α : Type} (a : α) (n : Nat) : Costs (pure a : Eff α) n :=
  trivial

theorem costs_now : Costs now 0 :=
  ⟨Nat.le_refl 0, fun _ => trivial⟩

theorem costs_random (lo hi : Nat) : Costs (random lo hi) 0 :=
  ⟨Nat.le_refl 0, fun _ => trivial⟩

theorem costs_log (line : String) : Costs (log line) 0 :=
  ⟨Nat.le_refl 0, fun _ => trivial⟩

theorem costs_statement (s : Statement) : Costs (statement s) 1 :=
  ⟨Nat.le_refl 1, fun _ => trivial⟩

/-- A step that costs `m` fits a budget of `n` when the rest fits what is left. -/
theorem costs_step {α β : Type} (x : Eff α) (k : α → Eff β) {m n : Nat} (hx : Costs x m)
    (hm : m ≤ n) (hk : ∀ a, Costs (k a) (n - m)) : Costs (x >>= k) n :=
  Costs.mono _ (Costs.bindS x k hx hk) (by omega)

theorem costs_ite {α : Type} (c : Prop) [Decidable c] (t e : Eff α) {n : Nat} (ht : Costs t n)
    (he : Costs e n) : Costs (if c then t else e) n := by by_cases h : c <;> simp [h, ht, he]

theorem costs_map {α β : Type} (f : α → β) (x : Eff α) {n : Nat} (h : Costs x n) :
    Costs (f <$> x) n :=
  costs_step x _ h (Nat.le_refl n) fun _ => costs_pure _ _

/-- Running an `if` in `ExceptT` runs the branch it takes. -/
theorem run_ite {ε α : Type} (c : Prop) [Decidable c] (a b : ExceptT ε Eff α) :
    (if c then a else b).run = if c then a.run else b.run := by split <;> rfl

/-- Proves a step of a sequence that sends no statement. -/
macro "budget_free" : tactic =>
  `(tactic|
    first
    | exact costs_pure _ _
    | exact costs_now
    | exact costs_random _ _
    | exact costs_log _
    | exact costs_map _ _ costs_now
    | exact costs_map _ _ (costs_random _ _)
    | exact costs_map _ _ (costs_log _))

/-- Proves a step of a sequence that sends one statement. -/
macro "budget_paid" : tactic =>
  `(tactic|
    first
    | exact costs_statement _
    | exact costs_map _ _ (costs_statement _))

/-- Proves `Costs x n` by following the structure of `x`. It leaves the goal at the first
statement that the remaining budget can't pay for. A program in `ExceptT` is first rewritten into
the steps of the `Eff` program under it. -/
macro "budget" : tactic =>
  `(tactic|
    ((try
          simp only [ExceptT.run_bind, ExceptT.run_pure, ExceptT.run_throw, ExceptT.run_lift,
            run_ite, liftM, monadLift, MonadLift.monadLift]);
      repeat'
        first
        | exact costs_pure _ _
        | exact Costs.mono _ (by budget_free) (by omega)
        | exact Costs.mono _ (by budget_paid) (by omega)
        | apply costs_ite
        | apply costs_map
        | refine costs_step _ _ (m := 1) (by budget_paid) (by omega) fun _ => ?_
        | refine costs_step _ _ (m := 0) (by budget_free) (by omega) fun _ => ?_
        | split))

end Espal
