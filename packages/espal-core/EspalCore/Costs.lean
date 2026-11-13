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

The lemmas here give the cost of each way to build a program. A value costs nothing, and a
statement costs one. A sequence costs its first part plus the most its rest can cost, and a branch
costs the dearer of its sides. `EspalCore.Budget` walks a handler once and combines them, so the
bound it finds is the worst case over every path.

A handler that loops over statements needs a bound on the loop, which that walk doesn't find.
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

/-! ## The cost of each way to build a program

`EspalCore.Budget` walks a handler and combines these into a proof of its bound. -/

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

/-- A sequence costs at most its first part plus the most its rest can cost. -/
theorem costs_bind {α β : Type} (x : Eff α) (k : α → Eff β) {m j : Nat} (hx : Costs x m)
    (hk : ∀ a, Costs (k a) j) : Costs (x >>= k) (m + j) :=
  Costs.bindS x k hx hk

theorem costs_map {α β : Type} (f : α → β) (x : Eff α) {n : Nat} (h : Costs x n) :
    Costs (f <$> x) n :=
  Costs.mono _ (costs_bind x _ h fun _ => costs_pure _ 0) (Nat.le_refl n)

/-- A branch costs at most the dearer of its two sides. -/
theorem costs_ite {α : Type} (c : Prop) [Decidable c] (t e : Eff α) {a b : Nat} (ht : Costs t a)
    (he : Costs e b) : Costs (if c then t else e) (max a b) := by
  by_cases h : c
  · simpa [h] using Costs.mono _ ht (Nat.le_max_left a b)
  · simpa [h] using Costs.mono _ he (Nat.le_max_right a b)

theorem costs_dite {α : Type} (c : Prop) [Decidable c] (t : c → Eff α) (e : ¬c → Eff α) {a b : Nat}
    (ht : ∀ h, Costs (t h) a) (he : ∀ h, Costs (e h) b) : Costs (dite c t e) (max a b) := by
  by_cases h : c
  · simpa [h] using Costs.mono _ (ht h) (Nat.le_max_left a b)
  · simpa [h] using Costs.mono _ (he h) (Nat.le_max_right a b)

/-! The same for a program that can fail, stated about the `Eff` program under it. -/

theorem costsT_pure {ε α : Type} (a : α) : Costs (pure a : ExceptT ε Eff α).run 0 :=
  trivial

theorem costsT_throw {ε α : Type} (e : ε) : Costs (throw e : ExceptT ε Eff α).run 0 :=
  trivial

theorem costsT_lift {ε α : Type} (y : Eff α) {m : Nat} (h : Costs y m) :
    Costs (ExceptT.lift y : ExceptT ε Eff α).run m :=
  costs_map _ y h

theorem costsT_bind {ε α β : Type} (x : ExceptT ε Eff α) (k : α → ExceptT ε Eff β) {m j : Nat}
    (hx : Costs x.run m) (hk : ∀ a, Costs (k a).run j) : Costs (x >>= k).run (m + j) := by
  rw [ExceptT.run_bind]
  refine costs_bind _ _ hx fun r => ?_
  cases r with
  | ok a => exact hk a
  | error e => exact costs_pure _ _

theorem costsT_map {ε α β : Type} (f : α → β) (x : ExceptT ε Eff α) {n : Nat} (h : Costs x.run n) :
    Costs (f <$> x).run n :=
  Costs.mono _ (costsT_bind x _ h fun _ => costsT_pure _) (Nat.le_refl n)

theorem costsT_ite {ε α : Type} (c : Prop) [Decidable c] (t e : ExceptT ε Eff α) {a b : Nat}
    (ht : Costs t.run a) (he : Costs e.run b) : Costs (if c then t else e).run (max a b) := by
  by_cases h : c
  · simpa [h] using Costs.mono _ ht (Nat.le_max_left a b)
  · simpa [h] using Costs.mono _ he (Nat.le_max_right a b)

theorem costsT_dite {ε α : Type} (c : Prop) [Decidable c] (t : c → ExceptT ε Eff α)
    (e : ¬c → ExceptT ε Eff α) {a b : Nat} (ht : ∀ h, Costs (t h).run a)
    (he : ∀ h, Costs (e h).run b) : Costs (dite c t e).run (max a b) := by
  by_cases h : c
  · simpa [h] using Costs.mono _ (ht h) (Nat.le_max_left a b)
  · simpa [h] using Costs.mono _ (he h) (Nat.le_max_right a b)

end Espal
