/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalJson.Lawful
import EspalJson.Number

/-!
# Counts below 2^53

JavaScript reads every integer below 2^53 exactly, but not every larger one. `Small` holds a
natural number below that limit, so it travels as a JSON number that a JavaScript client reads
unchanged.
It has no `+`, so a sum can't pass the limit without the code saying what happens there.
-/

@[expose] public section

namespace Espal

open Json

/-- A natural number below 2^53, which travels as a JSON number. -/
structure Small where
  /-- The number. -/
  val : Nat
  /-- The number is below 2^53. -/
  lt : val < 2 ^ 53
  deriving DecidableEq, Repr

instance : LE Small :=
  ⟨fun a b => a.val ≤ b.val⟩

instance : LT Small :=
  ⟨fun a b => a.val < b.val⟩

instance (a b : Small) : Decidable (a ≤ b) :=
  inferInstanceAs (Decidable (a.val ≤ b.val))

instance (a b : Small) : Decidable (a < b) :=
  inferInstanceAs (Decidable (a.val < b.val))

@[simp]
theorem Small.le_def (a b : Small) : a ≤ b ↔ a.val ≤ b.val :=
  Iff.rfl

@[simp]
theorem Small.lt_def (a b : Small) : a < b ↔ a.val < b.val :=
  Iff.rfl

instance : ToJson Small :=
  ⟨fun s => .num (Number.ofNat s.val)⟩

/-- Reads a natural number, and refuses one of 2^53 or more. -/
def smallFromJson? (j : Json) : Except String Small := do
  let n ← getNat? j
  if h : n < 2 ^ 53 then
    pure ⟨n, h⟩
  else
    throw "expected a natural number below 2^53"

instance : FromJson Small :=
  ⟨smallFromJson?⟩

instance : LawfulJson Small where
  fromJson?_toJson s := by
    obtain ⟨n, hn⟩ := s
    have hexp : (Number.ofNat n).exponent ≤ ((1000 : Nat) : Int) := by
      have := Number.exponent_ofInt_le (i := (n : Int)) (k := 16) (by omega)
      simp only [Number.ofNat]
      omega
    have hget : getNat? (.num (Number.ofNat n)) = .ok n := by
      simp [getNat?, Number.toNat?_ofNat hexp]
    show smallFromJson? (.num (Number.ofNat n)) = .ok ⟨n, hn⟩
    unfold smallFromJson?
    rw [hget]
    dsimp only [bind, Except.bind]
    rw [dite_eq_left hn]
    rfl

instance : NotNullJson Small :=
  ⟨fun _ => nofun⟩

end Espal
