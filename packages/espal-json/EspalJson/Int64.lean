/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalJson.Decimal
public import EspalJson.Lawful

/-!
# `Int64` as a decimal string

lean-json has no codec for `Int64`. Espal writes one as a decimal string such as `"-42"`, since a
JavaScript number holds integers exactly only up to 2^53 - 1. The decoder reads only the spelling
the encoder writes, and refuses an integer outside `Int64`'s range.
-/

@[expose] public section

namespace Espal

open Json

instance : ToJson Int64 :=
  ⟨fun x => .str (toString x.toInt)⟩

/-- Reads the one decimal spelling of an `Int64`, and refuses an integer outside its range. -/
def int64FromJson? (j : Json) : Except String Int64 := do
  let s ← getStr? j
  match decimalInt? s 20 with
  | none =>
    throw "expected a string holding a decimal integer"
  | some i =>
    if h : Int64.minValue.toInt ≤ i ∧ i ≤ Int64.maxValue.toInt then
      pure (Int64.ofIntLE i h.1 h.2)
    else
      throw "expected an integer from -9223372036854775808 to 9223372036854775807"

instance : FromJson Int64 :=
  ⟨int64FromJson?⟩

/-- An `Int64` prints in at most 20 characters, the length of its minimum. -/
theorem length_toString_toInt (x : Int64) : (toString x.toInt).length ≤ 20 := by
  have hlo : (-9223372036854775808 : Int) ≤ x.toInt := Int64.le_toInt x
  have hhi : x.toInt < 9223372036854775808 := Int64.toInt_lt x
  rw [Int.toString_eq_repr, Int.repr_eq_ite]
  split
  · exact (Nat.length_repr_le_iff (by decide)).2 (by omega)
  · rw [String.length_append]
    have := (Nat.length_repr_le_iff (n := (-x.toInt).toNat) (k := 19) (by decide)).2 (by omega)
    simp only [show "-".length = 1 from rfl]
    omega

instance : LawfulJson Int64 where
  fromJson?_toJson x := by
    show int64FromJson? (.str (toString x.toInt)) = .ok x
    have hcond : Int64.minValue.toInt ≤ x.toInt ∧ x.toInt ≤ Int64.maxValue.toInt :=
      ⟨x.minValue_le_toInt, x.toInt_le⟩
    unfold int64FromJson?
    simp only [getStr?, bind, Except.bind, decimalInt?_toString _ _ (length_toString_toInt x)]
    rw [dite_eq_left hcond, Int64.ofIntLE_toInt]
    rfl

instance : NotNullJson Int64 :=
  ⟨fun _ => nofun⟩

/-- The decoder for `Int64` takes only the spelling that its encoder writes. -/
theorem Int64.toJson_of_fromJson? {j : Json} {x : Int64}
    (h : (fromJson? j : Except String Int64) = .ok x) : toJson x = j := by
  change int64FromJson? j = .ok x at h
  unfold int64FromJson? at h
  cases j with
  | str s =>
    simp only [getStr?, bind, Except.bind] at h
    split at h
    · exact absurd h nofun
    · rename_i i hi
      split at h
      · rename_i hr
        simp only [pure, Except.pure, Except.ok.injEq] at h
        subst h
        show Json.str (toString (Int64.ofIntLE i hr.1 hr.2).toInt) = .str s
        rw [Int64.toInt_ofIntLE, toString_of_decimalInt? hi]
      · exact absurd h nofun
  | _ => simp [getStr?, bind, Except.bind] at h

end Espal
