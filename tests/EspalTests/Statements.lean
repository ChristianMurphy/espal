module

import EspalRoute

/-!
Pins the statement and the axioms of each headline theorem, so a change to either fails the build.
Change a pin only in a commit that says why the statement changed.
-/

/--
info: @Espal.Routable.roundTrip : ∀ {R : Type} [self : Espal.Routable R] (r : R),
  Espal.Routable.ofPath (Espal.Routable.toPath r) = some r
-/
#guard_msgs in
#check @Espal.Routable.roundTrip

/-- info: 'Espal.Routable.roundTrip' does not depend on any axioms -/
#guard_msgs in
#print axioms Espal.Routable.roundTrip

/--
info: Espal.Route.parseNatSeg_natSeg : ∀ (n : Nat), Espal.Route.parseNatSeg (Espal.Route.natSeg n) = some n
-/
#guard_msgs in
#check @Espal.Route.parseNatSeg_natSeg

/-- info: 'Espal.Route.parseNatSeg_natSeg' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.Route.parseNatSeg_natSeg

/--
info: @Espal.Route.natSeg_ne_of_parseNatSeg_none : ∀ {s : String},
  Espal.Route.parseNatSeg s = none → ∀ (n : Nat), Espal.Route.natSeg n ≠ s
-/
#guard_msgs in
#check @Espal.Route.natSeg_ne_of_parseNatSeg_none

/--
info: 'Espal.Route.natSeg_ne_of_parseNatSeg_none' depends on axioms: [propext, Classical.choice, Quot.sound]
-/
#guard_msgs in
#print axioms Espal.Route.natSeg_ne_of_parseNatSeg_none
