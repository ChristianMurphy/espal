/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Effect

/-!
# Programs that only read

`ReadOnly x` says that the program `x` never asks for `statement`, whichever way it branches and
whatever the database answers. It may still read with `query`. `ReadOnly.written_eq` shows that a
run of such a program against any `World` records no statement that may write.

The claim is about which operation a program asks for. A `query` whose SQL text writes is outside
it, since the text is a string here.

The lemmas give the claim for each way to build a program. `EspalCore.Budget` walks a handler once
and combines them, as it does for a budget. A loop needs no bound on its length here.
-/

@[expose] public section

namespace Espal

open LeanLinq

/-- On every path, the program asks only for operations that leave the database as it was. -/
def ReadOnly : {α : Type} → {w : Wp α} → FreerD Op opWp α w → Prop
  | _, _, .pure _ => True
  | _, _, .bindE e f => e.reads = true ∧ ∀ b, ReadOnly (f b)
  | _, _, .weaken _ x => ReadOnly x

/-- A sequence only reads when its first part and every rest do. -/
theorem ReadOnly.bindS {α β : Type} {w₂ : α → Wp β} :
    {w : Wp α} →
      (x : FreerD Op opWp α w) →
      (k : (a : α) → FreerD Op opWp β (w₂ a)) →
      ReadOnly x → (∀ a, ReadOnly (k a)) → ReadOnly (FreerD.bindS x k)
  | _, .pure a, _, _, hk => hk a
  | _, .bindE e f, k, h, hk => by
    have h' : e.reads = true ∧ ∀ b, ReadOnly (f b) := h
    exact
      show e.reads = true ∧ ∀ b, ReadOnly (FreerD.bindS (f b) k) from
        ⟨h'.1, fun b => ReadOnly.bindS (f b) k (h'.2 b) hk⟩
  | _, .weaken _ x, k, h, hk => ReadOnly.bindS x k h hk

/-- A run of a program that only reads records no statement that may write, from any world. -/
theorem ReadOnly.run_written_eq :
    {α : Type} →
      {w : Wp α} →
      (x : FreerD Op opWp α w) →
      ReadOnly x → (world : World) → (run x world).2.written = world.written
  | _, _, .pure _, _, _ => rfl
  | _, _, .bindE e f, h, world => by
    have h' : e.reads = true ∧ ∀ b, ReadOnly (f b) := h
    have step :
      run (FreerD.bindE e f) world = run (f (Op.answer e world).1) (Op.answer e world).2 := rfl
    rw [step, ReadOnly.run_written_eq (f (Op.answer e world).1) (h'.2 _) (Op.answer e world).2]
    have hreads := h'.1
    cases e <;> simp_all [Op.answer, Op.reads]
  | _, _, .weaken _ x, h, world => ReadOnly.run_written_eq x h world

/-- A run of `x` records no statement that may write, from any world. -/
theorem ReadOnly.written_eq {α : Type} {x : Eff α} (h : ReadOnly x) (world : World) :
    (x.eval world).2.written = world.written :=
  ReadOnly.run_written_eq x h world

/-! ## Each way to build a program

`EspalCore.Budget` walks a handler and combines these into a proof that it only reads. -/

theorem readOnly_pure {α : Type} (a : α) : ReadOnly (pure a : Eff α) :=
  trivial

theorem readOnly_now : ReadOnly now :=
  ⟨rfl, fun _ => trivial⟩

theorem readOnly_random (lo hi : Nat) : ReadOnly (random lo hi) :=
  ⟨rfl, fun _ => trivial⟩

theorem readOnly_log (line : String) : ReadOnly (log line) :=
  ⟨rfl, fun _ => trivial⟩

theorem readOnly_query (s : Statement) : ReadOnly (query s) :=
  ⟨rfl, fun _ => trivial⟩

theorem readOnly_bind {α β : Type} (x : Eff α) (k : α → Eff β) (hx : ReadOnly x)
    (hk : ∀ a, ReadOnly (k a)) : ReadOnly (x >>= k) :=
  ReadOnly.bindS x k hx hk

theorem readOnly_map {α β : Type} (f : α → β) (x : Eff α) (h : ReadOnly x) : ReadOnly (f <$> x) :=
  readOnly_bind x _ h fun _ => readOnly_pure _

theorem readOnly_ite {α : Type} (c : Prop) [Decidable c] (t e : Eff α) (ht : ReadOnly t)
    (he : ReadOnly e) : ReadOnly (if c then t else e) := by
  by_cases h : c
  · simpa [h] using ht
  · simpa [h] using he

theorem readOnly_dite {α : Type} (c : Prop) [Decidable c] (t : c → Eff α) (e : ¬c → Eff α)
    (ht : ∀ h, ReadOnly (t h)) (he : ∀ h, ReadOnly (e h)) : ReadOnly (dite c t e) := by
  by_cases h : c
  · simpa [h] using ht h
  · simpa [h] using he h

/-! The same for a program that can fail, stated about the `Eff` program under it. -/

theorem readOnlyT_pure {ε α : Type} (a : α) : ReadOnly (pure a : ExceptT ε Eff α).run :=
  trivial

theorem readOnlyT_throw {ε α : Type} (e : ε) : ReadOnly (throw e : ExceptT ε Eff α).run :=
  trivial

theorem readOnlyT_lift {ε α : Type} (y : Eff α) (h : ReadOnly y) :
    ReadOnly (ExceptT.lift y : ExceptT ε Eff α).run :=
  readOnly_map _ y h

theorem readOnlyT_bind {ε α β : Type} (x : ExceptT ε Eff α) (k : α → ExceptT ε Eff β)
    (hx : ReadOnly x.run) (hk : ∀ a, ReadOnly (k a).run) : ReadOnly (x >>= k).run := by
  rw [ExceptT.run_bind]
  refine readOnly_bind _ _ hx fun r => ?_
  cases r with
  | ok a => exact hk a
  | error e => exact readOnly_pure _

theorem readOnlyT_map {ε α β : Type} (f : α → β) (x : ExceptT ε Eff α) (h : ReadOnly x.run) :
    ReadOnly (f <$> x).run :=
  readOnlyT_bind x _ h fun _ => readOnlyT_pure _

theorem readOnlyT_ite {ε α : Type} (c : Prop) [Decidable c] (t e : ExceptT ε Eff α)
    (ht : ReadOnly t.run) (he : ReadOnly e.run) : ReadOnly (if c then t else e).run := by
  by_cases h : c
  · simpa [h] using ht
  · simpa [h] using he

theorem readOnlyT_dite {ε α : Type} (c : Prop) [Decidable c] (t : c → ExceptT ε Eff α)
    (e : ¬c → ExceptT ε Eff α) (ht : ∀ h, ReadOnly (t h).run) (he : ∀ h, ReadOnly (e h).run) :
    ReadOnly (dite c t e).run := by
  by_cases h : c
  · simpa [h] using ht h
  · simpa [h] using he h

/-! ## Loops -/

theorem readOnly_mapM_loop {α β : Type} (f : α → Eff β) (hf : ∀ a, ReadOnly (f a)) :
    ∀ (xs : List α) (acc : List β), ReadOnly (List.mapM.loop f xs acc)
  | [], _ => by simpa [List.mapM.loop] using readOnly_pure _
  | a :: as, acc =>
    readOnly_bind (f a) (fun b => List.mapM.loop f as (b :: acc)) (hf a) fun b =>
      readOnly_mapM_loop f hf as (b :: acc)

/-- Mapping a program that only reads over a list only reads. -/
theorem readOnly_mapM {α β : Type} (f : α → Eff β) (xs : List α) (hf : ∀ a, ReadOnly (f a)) :
    ReadOnly (xs.mapM f) :=
  readOnly_mapM_loop f hf xs []

/-- A `for` loop over a list only reads when each pass does. -/
theorem readOnly_forIn {α σ : Type} (xs : List α) (init : σ) (f : α → σ → Eff (ForInStep σ))
    (hf : ∀ a s, ReadOnly (f a s)) : ReadOnly (forIn xs init f) := by
  induction xs generalizing init with
  | nil => simpa using readOnly_pure _
  | cons a as ih =>
    rw [List.forIn_cons]
    refine readOnly_bind _ _ (hf a init) fun step => ?_
    cases step with
    | done s => exact readOnly_pure _
    | yield s => exact ih s

theorem readOnlyT_mapM_loop {ε α β : Type} (f : α → ExceptT ε Eff β)
    (hf : ∀ a, ReadOnly (f a).run) :
    ∀ (xs : List α) (acc : List β), ReadOnly (List.mapM.loop f xs acc).run
  | [], _ => by simpa [List.mapM.loop] using readOnlyT_pure _
  | a :: as, acc =>
    readOnlyT_bind (f a) (fun b => List.mapM.loop f as (b :: acc)) (hf a) fun b =>
      readOnlyT_mapM_loop f hf as (b :: acc)

theorem readOnlyT_mapM {ε α β : Type} (f : α → ExceptT ε Eff β) (xs : List α)
    (hf : ∀ a, ReadOnly (f a).run) : ReadOnly (xs.mapM f).run :=
  readOnlyT_mapM_loop f hf xs []

theorem readOnlyT_forIn {ε α σ : Type} (xs : List α) (init : σ)
    (f : α → σ → ExceptT ε Eff (ForInStep σ)) (hf : ∀ a s, ReadOnly (f a s).run) :
    ReadOnly (forIn xs init f).run := by
  induction xs generalizing init with
  | nil => simpa using readOnlyT_pure _
  | cons a as ih =>
    rw [List.forIn_cons]
    refine readOnlyT_bind _ _ (hf a init) fun step => ?_
    cases step with
    | done s => exact readOnlyT_pure s
    | yield s => exact ih s

end Espal
