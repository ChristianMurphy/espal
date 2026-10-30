/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import Init.Data.Int.ToString

/-!
# Integers as decimal strings

Integers of 64 bits travel as decimal strings, since a JavaScript number holds integers exactly
only up to 2^53 - 1. `decimalInt?` reads such a string strictly. It reads the digits, prints the
integer again, and keeps it only if the two spellings match. So `"007"`, `"-0"` and `"+5"` all
fail, and each integer has one spelling that reads back.
-/

@[expose] public section

namespace Espal

/-- Reads the digits, with an optional leading `-`. It doesn't check the spelling. -/
def readInt? : List Char → Option Int
  | [] => none
  | c :: cs =>
    if c = '-' then
      if !cs.isEmpty && cs.all Char.isDigit then some (-Int.ofNat (Nat.ofDigitChars 10 cs 0))
      else none
    else
      if (c :: cs).all Char.isDigit then some (Int.ofNat (Nat.ofDigitChars 10 (c :: cs) 0))
      else none

/--
The integer `s` spells in the one form `toString` writes: an optional `-`, then digits with no
leading zero, and never `-0`. Refuses a string longer than `maxLength` before reading it.
-/
def decimalInt? (s : String) (maxLength : Nat) : Option Int :=
  if s.length ≤ maxLength then (readInt? s.toList).filter fun i => toString i == s else none

theorem readInt?_toDigits (n : Nat) : readInt? (Nat.toDigits 10 n) = some (Int.ofNat n) := by
  have hdigits : ∀ c ∈ Nat.toDigits 10 n, c.isDigit = true := fun _ hc =>
    Nat.isDigit_of_mem_toDigits (by decide) (by decide) hc
  match h : Nat.toDigits 10 n with
  | [] => exact absurd h Nat.toDigits_ne_nil
  |
  c :: cs =>
    have hc : c ≠ '-' := by
      intro hc
      have := hdigits c (by simp [h])
      simp [hc] at this
    have hall : (c :: cs).all Char.isDigit = true := by
      rw [List.all_eq_true]
      exact fun x hx => hdigits x (h ▸ hx)
    simp only [readInt?, hc, ↓reduceIte, hall]
    rw [← h, Nat.ofDigitChars_ten_toDigits]

theorem readInt?_toString (i : Int) : readInt? (toString i).toList = some i := by
  rw [Int.toString_eq_repr, Int.repr_eq_ite]
  split
  · rw [Nat.toList_repr, readInt?_toDigits]
    congr 1
    simp only [Int.ofNat_eq_natCast]
    omega
  · have hdigits : ∀ c ∈ Nat.toDigits 10 (-i).toNat, c.isDigit = true := fun _ hc =>
      Nat.isDigit_of_mem_toDigits (by decide) (by decide) hc
    have hne : (Nat.toDigits 10 (-i).toNat).isEmpty = false := by
      cases h : Nat.toDigits 10 (-i).toNat with
      | nil => exact absurd h Nat.toDigits_ne_nil
      | cons => rfl
    have hall : (Nat.toDigits 10 (-i).toNat).all Char.isDigit = true := by
      rw [List.all_eq_true]
      exact hdigits
    rw [String.toList_append, Nat.toList_repr]
    simp only [show "-".toList = ['-'] from rfl, List.cons_append, List.nil_append, readInt?,
      ↓reduceIte, hne, hall, Nat.ofDigitChars_ten_toDigits, Bool.not_false, Bool.true_and]
    congr 1
    simp only [Int.ofNat_eq_natCast]
    omega

theorem decimalInt?_toString (i : Int) (maxLength : Nat) (h : (toString i).length ≤ maxLength) :
    decimalInt? (toString i) maxLength = some i := by
  simp only [decimalInt?, h, ↓reduceIte, readInt?_toString]
  simp

theorem toString_of_decimalInt? {s : String} {maxLength : Nat} {i : Int}
    (h : decimalInt? s maxLength = some i) : toString i = s := by
  unfold decimalInt? at h
  split at h
  · simp only [Option.filter_eq_some_iff, beq_iff_eq] at h
    exact h.2
  · exact absurd h nofun

end Espal
