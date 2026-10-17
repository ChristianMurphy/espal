/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

/-!
# Typed routes

A `Routable` type maps each value to URL path segments and back, and carries a proof that parsing
a rendered path yields the same value. Links and redirects are built from route values, so a link
the application emits always dispatches to the route it was built from.

The guarantee is at the level of path segments. Splitting a raw URL into segments and
percent-decoding them is done by the HTTP layer and is trusted.
-/

@[expose] public section

namespace Espal

/-- A type whose values correspond one-to-one with URL paths. -/
class Routable (R : Type) where
  /-- The path segments for a route value. -/
  toPath : R → List String
  /-- The route value for path segments, if they name one. -/
  ofPath : List String → Option R
  /-- Parsing a printed path recovers the route. -/
  roundTrip : ∀ r, ofPath (toPath r) = some r

namespace Route

/-! ## Decimal codec for path parameters -/

/-- The ASCII digit for `d < 10`. -/
def digitChar (d : Nat) : Char := Char.ofNat (48 + d)

/-- The decimal digits of `n`, most significant first, without leading zeros. -/
def natToDigits (n : Nat) : List Char :=
  if n < 10 then [digitChar n] else natToDigits (n / 10) ++ [digitChar (n % 10)]
termination_by n
decreasing_by omega

/-- The number a list of decimal digits denotes. -/
def digitsValue (l : List Char) : Nat := l.foldl (fun acc c => acc * 10 + (c.toNat - 48)) 0

/-- Parses a non-empty list of decimal digits. -/
def parseDigits (l : List Char) : Option Nat :=
  if !l.isEmpty && l.all Char.isDigit then some (digitsValue l) else none

theorem digitChar_spec : ∀ d, d < 10 → (digitChar d).toNat - 48 = d ∧ (digitChar d).isDigit = true := by
  decide

theorem natToDigits_spec (n : Nat) :
    (natToDigits n).all Char.isDigit = true ∧ natToDigits n ≠ [] ∧ digitsValue (natToDigits n) = n := by
  induction n using Nat.strongRecOn with
  | ind n ih =>
    rw [natToDigits]
    split
    · have := digitChar_spec n ‹_›
      simp [digitsValue, this]
    · have ⟨hall, _, hval⟩ := ih (n / 10) (by omega)
      have := digitChar_spec (n % 10) (Nat.mod_lt _ (by omega))
      refine ⟨by simp [hall, this], by simp, ?_⟩
      simp only [digitsValue, List.foldl_append, List.foldl_cons, List.foldl_nil] at hval ⊢
      rw [hval, this.1]
      omega

theorem parseDigits_natToDigits (n : Nat) : parseDigits (natToDigits n) = some n := by
  have ⟨hall, hne, hval⟩ := natToDigits_spec n
  simp [parseDigits, hall, hne, hval]

/-- A natural number as a path segment. -/
def natSeg (n : Nat) : String := String.ofList (natToDigits n)

/-- Parses a path segment as a natural number. -/
def parseNatSeg (s : String) : Option Nat := parseDigits s.toList

@[simp] theorem parseNatSeg_natSeg (n : Nat) : parseNatSeg (natSeg n) = some n := by
  simp [parseNatSeg, natSeg, parseDigits_natToDigits]

/-- A printed number never equals a segment that does not parse as one, such as a literal route
segment like `"new"`. -/
theorem natSeg_ne_of_parseNatSeg_none {s : String} (h : parseNatSeg s = none) (n : Nat) :
    natSeg n ≠ s := by
  intro heq
  rw [← heq, parseNatSeg_natSeg] at h
  cases h

end Route
end Espal
