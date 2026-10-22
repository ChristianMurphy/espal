module

import EspalRoute
meta import EspalRoute

/-! Tests for the decimal path codec in `Espal.Route`. -/

open Espal Route

#guard natSeg 0 = "0"

#guard natSeg 1234 = "1234"

#guard parseNatSeg "0042" = some 42

#guard parseNatSeg "" = none

#guard parseNatSeg "12a" = none

#guard parseNatSeg "-1" = none

example (n : Nat) : parseNatSeg (natSeg n) = some n := by simp

example (n : Nat) : natSeg n ≠ "new" :=
  natSeg_ne_of_parseNatSeg_none (by decide) n
