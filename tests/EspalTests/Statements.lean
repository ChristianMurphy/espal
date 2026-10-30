module

import EspalJson
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

/--
info: @Espal.Route.matchTable_pathOf : ∀ {α : Type} {routes : List (Routing.Route α)},
  Espal.Route.linksDisjoint routes = true →
    ∀ (i : Fin routes.length) (args : Espal.Route.Args routes[i].segs),
      Espal.Route.Linkable routes[i].segs args →
        Routing.matchTable routes routes[i].method (Espal.Route.pathOf routes[i].segs args) =
          some
            ({ method := routes[i].method, segs := routes[i].segs },
              Espal.Route.applyHandler routes[i].segs routes[i].handler args)
-/
#guard_msgs in
#check @Espal.Route.matchTable_pathOf

/-- info: 'Espal.Route.matchTable_pathOf' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.Route.matchTable_pathOf

/--
info: Espal.Route.natAccepts_eq : ∀ (s : String), Espal.Route.natAccepts s = (Routing.Internal.parseNat? s).isSome
-/
#guard_msgs in
#check @Espal.Route.natAccepts_eq

/-- info: 'Espal.Route.natAccepts_eq' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.Route.natAccepts_eq

/--
info: @Espal.fromJson?_toJson : ∀ {α : Type u_1} {inst : Json.ToJson α} {inst_1 : Json.FromJson α} [self : Espal.LawfulJson α]
  (x : α), Json.fromJson? (Json.toJson x) = Except.ok x
-/
#guard_msgs in
#check @Espal.LawfulJson.fromJson?_toJson

/--
info: @Espal.toJson_ne_null : ∀ {α : Type u_1} {inst : Json.ToJson α} [self : Espal.NotNullJson α] (x : α),
  Json.toJson x ≠ Json.null
-/
#guard_msgs in
#check @Espal.NotNullJson.toJson_ne_null

/--
info: @Espal.instLawfulJsonOptionOfNotNullJson : ∀ {α : Type u_1} [inst : Json.ToJson α] [inst_1 : Json.FromJson α]
  [Espal.LawfulJson α] [Espal.NotNullJson α], Espal.LawfulJson (Option α)
-/
#guard_msgs in
#check @Espal.instLawfulJsonOptionOfNotNullJson

/-- info: 'Espal.instLawfulJsonOptionOfNotNullJson' depends on axioms: [propext] -/
#guard_msgs in
#print axioms Espal.instLawfulJsonOptionOfNotNullJson

/-- info: 'Espal.instLawfulJsonArray' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.instLawfulJsonArray

/-- info: 'Espal.instLawfulJsonProd' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in
#print axioms Espal.instLawfulJsonProd

/-- info: 'Espal.instLawfulJsonInt32' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.instLawfulJsonInt32

/-- info: 'Espal.instLawfulJsonSmall' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.instLawfulJsonSmall

/--
info: @Json.Number.exponent_ofInt_le : ∀ {i : Int} {k : Nat}, i.natAbs < 10 ^ k → (Json.Number.ofInt i).exponent ≤ ↑k
-/
#guard_msgs in
#check @Json.Number.exponent_ofInt_le

/-- info: 'Json.Number.exponent_ofInt_le' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Json.Number.exponent_ofInt_le
