/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import Json.Number

/-!
# Exponents of lean-json numbers

lean-json decodes an integer only when its number's exponent is at most 1,000. These lemmas bound
the exponent of `Number.ofInt i` by the count of decimal digits of `i`, so a codec for a bounded
integer type can meet that limit. They are written in the form lean-json would take.
-/

@[expose] public section

namespace Json.Number

/-- Each step of `normalizeAux` divides the mantissa by ten, so ten to the number of steps divides
into the starting mantissa. -/
theorem pow_exponent_normalizeAux_le (m e : Int) (hm : m ≠ 0) :
    10 ^ ((normalizeAux m e).exponent - e).toNat ≤ m.natAbs := by
  fun_induction normalizeAux m e with
  | case1 m e h ih =>
    have hq : m / 10 ≠ 0 := by omega
    have hle := le_exponent_normalizeAux (m / 10) (e + 1)
    have key := ih hq
    have hsplit :
      ((normalizeAux (m / 10) (e + 1)).exponent - e).toNat =
        ((normalizeAux (m / 10) (e + 1)).exponent - (e + 1)).toNat + 1 := by
      omega
    rw [hsplit, Nat.pow_succ]
    have hdiv : (m / 10).natAbs * 10 = m.natAbs := by omega
    calc
      10 ^ ((normalizeAux (m / 10) (e + 1)).exponent - (e + 1)).toNat * 10 ≤ (m / 10).natAbs * 10 :=
        Nat.mul_le_mul_right 10 key
      _ = m.natAbs := hdiv
  | case2 m e h =>
    simp only [Int.sub_self, Int.toNat_zero, Nat.pow_zero]
    omega

/-- An integer below `10 ^ k` in size has an exponent of at most `k`. -/
theorem exponent_ofInt_le {i : Int} {k : Nat} (h : i.natAbs < 10 ^ k) : (ofInt i).exponent ≤ k := by
  unfold ofInt normalize
  split
  · simp
  · rename_i hi
    have hpow := pow_exponent_normalizeAux_le i 0 hi
    have hnn := le_exponent_normalizeAux i 0
    have hlt : 10 ^ ((normalizeAux i 0).exponent - 0).toNat < 10 ^ k := Nat.lt_of_le_of_lt hpow h
    have := (Nat.pow_lt_pow_iff_right (by decide : 1 < 10)).mp hlt
    omega

end Json.Number
