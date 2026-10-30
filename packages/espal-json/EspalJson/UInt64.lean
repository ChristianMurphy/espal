/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalJson.Lawful

/-!
# `UInt64` as a decimal string

lean-json writes a `UInt64` as a decimal string, and its decoder reads one back. This module
proves that round trip. The decoder also accepts leading zeros, so `"007"` reads as 7, and no
theorem here says each value has one spelling.
-/

@[expose] public section

namespace Espal

open Json

/-- lean-json's decimal reader gives back every natural number that `toString` prints. -/
theorem decodeNat?_toString (n : Nat) (maxDigits : Nat) (h : (toString n).length ≤ maxDigits) :
    decodeNat? (toString n) maxDigits = some n := by
  have hne : (toString n).isEmpty = false := by
    rw [String.isEmpty_eq_false_iff]
    intro he
    have := Nat.length_repr_pos (n := n)
    rw [← Nat.toString_eq_repr, he] at this
    exact absurd this (by decide)
  unfold decodeNat?
  rw [ite_eq_right
      (by
        simp only [hne, Bool.false_or, decide_eq_true_eq]; omega),
    String.foldl_eq_foldl_toList, Nat.toString_eq_repr, Nat.toList_repr]
  have hdigits : ∀ c ∈ Nat.toDigits 10 n, c.isDigit = true := fun _ hc =>
    Nat.isDigit_of_mem_toDigits (by decide) (by decide) hc
  generalize hcs : Nat.toDigits 10 n = cs at hdigits ⊢
  have hn : some n = some (Nat.ofDigitChars 10 cs 0) := by rw [← hcs, Nat.ofDigitChars_ten_toDigits]
  rw [hn]
  clear hcs hn h hne
  generalize 0 = v
  induction cs generalizing v with
  | nil => simp [Nat.ofDigitChars_nil]
  | cons c cs ih =>
    have hc := hdigits c List.mem_cons_self
    have hc' : ('0' ≤ c && c ≤ '9') = true := by simpa [Char.isDigit, Char.le_def] using hc
    simp only [List.foldl_cons, hc', ↓reduceIte, Nat.ofDigitChars_cons]
    rw [Nat.mul_comm v 10]
    exact ih (fun x hx => hdigits x (List.mem_cons_of_mem c hx)) _

instance : LawfulJson UInt64 where
  fromJson?_toJson x := by
    have hlen : (toString x.toNat).length ≤ 1000 := by
      rw [Nat.toString_eq_repr]
      have :=
        (Nat.length_repr_le_iff (n := x.toNat) (k := 20) (by decide)).2
          (Nat.lt_trans x.toNat_lt (by decide))
      omega
    show
      (do
          let n ← bignumFromJson? (bignumToJson x.toNat)
          if h : n < UInt64.size then
            .ok (UInt64.ofNatLT n h)
          else
            .error "value is too large for UInt64") =
        (.ok x : Except String UInt64)
    simp only [bignumFromJson?, bignumToJson, getStr?, bind, Except.bind,
      decodeNat?_toString _ _ hlen]
    rw [dite_eq_left x.toNat_lt, UInt64.ofNatLT_toNat]

instance : NotNullJson UInt64 :=
  ⟨fun _ => nofun⟩

end Espal
