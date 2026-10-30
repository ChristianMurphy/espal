/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalJson.Lawful
import EspalJson.Number

/-!
# `Int32` as a JSON number

lean-json has no codec for `Int32`. Espal writes one as a JSON number, since JavaScript reads every
`Int32` exactly. The decoder refuses an integer outside `Int32`'s range.
-/

@[expose] public section

namespace Espal

open Json

instance : ToJson Int32 :=
  ⟨fun x => .num (Number.ofInt x.toInt)⟩

/-- Reads an integer, and refuses one outside `Int32`'s range. -/
def int32FromJson? (j : Json) : Except String Int32 := do
  let i ← getInt? j
  if h : Int32.minValue.toInt ≤ i ∧ i ≤ Int32.maxValue.toInt then
    pure (Int32.ofIntLE i h.1 h.2)
  else
    throw "expected an integer from -2147483648 to 2147483647"

instance : FromJson Int32 :=
  ⟨int32FromJson?⟩

instance : LawfulJson Int32 where
  fromJson?_toJson x := by
    have hlo := Int32.le_toInt x
    have hhi := Int32.toInt_lt x
    have hexp : (Number.ofInt x.toInt).exponent ≤ ((1000 : Nat) : Int) := by
      have := Number.exponent_ofInt_le (i := x.toInt) (k := 10) (by omega)
      omega
    have hcond : Int32.minValue.toInt ≤ x.toInt ∧ x.toInt ≤ Int32.maxValue.toInt := by
      rw [Int32.toInt_minValue]
      exact ⟨hlo, Int32.toInt_le x⟩
    have hget : getInt? (.num (Number.ofInt x.toInt)) = .ok x.toInt := by
      simp [getInt?, Number.toInt?_ofInt hexp]
    show int32FromJson? (.num (Number.ofInt x.toInt)) = .ok x
    unfold int32FromJson?
    rw [hget]
    dsimp only [bind, Except.bind]
    rw [dite_eq_left hcond, Int32.ofIntLE_eq_ofInt, Int32.ofInt_toInt]
    rfl

instance : NotNullJson Int32 :=
  ⟨fun _ => nofun⟩

end Espal
