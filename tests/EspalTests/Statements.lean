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
info: @Espal.Route.keysDisjoint_map_routeKey : ∀ {α : Type} (routes : List (Routing.Route α)),
  Espal.Route.keysDisjoint (List.map Espal.Route.routeKey routes) = Espal.Route.linksDisjoint routes
-/
#guard_msgs in
#check @Espal.Route.keysDisjoint_map_routeKey

/-- info: 'Espal.Route.keysDisjoint_map_routeKey' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.Route.keysDisjoint_map_routeKey

/--
info: Espal.Route.natAccepts_eq : ∀ (s : String), Espal.Route.natAccepts s = (Routing.Internal.parseNat? s).isSome
-/
#guard_msgs in
#check @Espal.Route.natAccepts_eq

/-- info: 'Espal.Route.natAccepts_eq' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.Route.natAccepts_eq

/--
info: @Espal.Api.matchTable_pathOf : ∀ {α : Type} (t : Espal.Api α) (i : Fin t.routes.length)
  (args : Espal.Route.Args t.routes[i].segs),
  Espal.Route.Linkable t.routes[i].segs args →
    Routing.matchTable t.routes t.routes[i].method (Espal.Route.pathOf t.routes[i].segs args) =
      some
        ({ method := t.routes[i].method, segs := t.routes[i].segs },
          Espal.Route.applyHandler t.routes[i].segs t.routes[i].handler args)
-/
#guard_msgs in
#check @Espal.Api.matchTable_pathOf

/-- info: 'Espal.Api.matchTable_pathOf' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.Api.matchTable_pathOf
