module

import EspalCore
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
info: @Espal.Route.matchTable_pathOf : ∀ {α : Type u_1} {routes : List (Routing.Route α)},
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
info: @Espal.Route.keysDisjoint_map_routeKey : ∀ {α : Type u_1} (routes : List (Routing.Route α)),
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
info: @Espal.Api.matchTable_pathOf : ∀ {α : Type u_1} (t : Espal.Api α) (i : Fin t.routes.length)
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

/--
info: @Espal.Route.unshadowed_of_linksDisjoint : ∀ {α : Type u_1} {routes : List (Routing.Route α)},
  Espal.Route.linksDisjoint routes = true → Routing.Internal.unshadowed (List.map Routing.Route.key routes) = true
-/
#guard_msgs in
#check @Espal.Route.unshadowed_of_linksDisjoint

/--
info: 'Espal.Route.unshadowed_of_linksDisjoint' depends on axioms: [propext, Classical.choice, Quot.sound]
-/
#guard_msgs in
#print axioms Espal.Route.unshadowed_of_linksDisjoint

/-- info: 'Espal.Api.index' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.Api.index

/--
info: @Espal.Route.linksDisjoint_map : ∀ {α : Type u_1} {β : Type u_2} (f : α → β) (routes : List (Routing.Route α)),
  Espal.Route.linksDisjoint (List.map (Espal.Route.mapRoute f) routes) = Espal.Route.linksDisjoint routes
-/
#guard_msgs in
#check @Espal.Route.linksDisjoint_map

/-- info: 'Espal.Route.linksDisjoint_map' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.Route.linksDisjoint_map

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
info: @Espal.decode_toJson : ∀ {α : Type u_1} {inst : Json.ToJson α} {inst_1 : Espal.JsonDecode α}
  [self : Espal.LawfulDecode α] (pointer : List String) (x : α), Espal.decode pointer (Json.toJson x) = Except.ok x
-/
#guard_msgs in
#check @Espal.LawfulDecode.decode_toJson

/--
info: Espal.JsonDecode.lawfulJson : ∀ (α : Type u_1) [inst : Json.ToJson α] [inst_1 : Espal.JsonDecode α]
  [@Espal.LawfulDecode α inst inst_1], @Espal.LawfulJson α inst (@Espal.JsonDecode.toFromJson α inst_1)
-/
#guard_msgs in
set_option pp.explicit true in
#check @Espal.JsonDecode.lawfulJson

/-- info: 'Espal.JsonDecode.lawfulJson' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.JsonDecode.lawfulJson

/-- info: 'Espal.instLawfulDecodeOptionOfNotNullJson' depends on axioms: [propext] -/
#guard_msgs in
#print axioms Espal.instLawfulDecodeOptionOfNotNullJson

/-- info: 'Espal.instLawfulDecodeArray' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in
#print axioms Espal.instLawfulDecodeArray

/-- info: 'Espal.instLawfulDecodeOfLawfulJson' depends on axioms: [propext] -/
#guard_msgs in
#print axioms Espal.instLawfulDecodeOfLawfulJson

/--
info: Espal.decimalInt?_toString : ∀ (i : Int) (maxLength : Nat),
  (toString i).length ≤ maxLength → Espal.decimalInt? (toString i) maxLength = some i
-/
#guard_msgs in
#check @Espal.decimalInt?_toString

/--
info: @Espal.toString_of_decimalInt? : ∀ {s : String} {maxLength : Nat} {i : Int},
  Espal.decimalInt? s maxLength = some i → toString i = s
-/
#guard_msgs in
#check @Espal.toString_of_decimalInt?

/--
info: @Espal.Int64.toJson_of_fromJson? : ∀ {j : Json} {x : Int64}, Json.fromJson? j = Except.ok x → Json.toJson x = j
-/
#guard_msgs in
#check @Espal.Int64.toJson_of_fromJson?

/--
info: 'Espal.Int64.toJson_of_fromJson?' depends on axioms: [propext, Classical.choice, Quot.sound]
-/
#guard_msgs in
#print axioms Espal.Int64.toJson_of_fromJson?

/-- info: 'Espal.instLawfulJsonInt64' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.instLawfulJsonInt64

/-- info: 'Espal.instLawfulJsonUInt64' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.instLawfulJsonUInt64

/--
info: @Espal.status_of_decodeBody_error : ∀ {α : Type} [inst : Espal.JsonDecode α] {body : ByteArray} {p : Espal.Problem},
  Espal.decodeBody α body = Except.error p →
    p.status = 400 ∧ (Json.parseBytes body).toOption = none ∨
      p.status = 422 ∧ ∃ j, Json.parseBytes body = Except.ok j ∧ Espal.decode [] j = Except.error p.errors
-/
#guard_msgs in
#check @Espal.status_of_decodeBody_error

/--
info: 'Espal.status_of_decodeBody_error' depends on axioms: [propext, Classical.choice, Quot.sound]
-/
#guard_msgs in
#print axioms Espal.status_of_decodeBody_error

/--
info: @Json.Number.exponent_ofInt_le : ∀ {i : Int} {k : Nat}, i.natAbs < 10 ^ k → (Json.Number.ofInt i).exponent ≤ ↑k
-/
#guard_msgs in
#check @Json.Number.exponent_ofInt_le

/-- info: 'Json.Number.exponent_ofInt_le' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Json.Number.exponent_ofInt_le

/--
info: Espal.Clamp.fromQuery_ok (lo hi : Nat) (h : lo ≤ hi) (s : Option String) : ∃ c, Espal.fromQuery s = Except.ok c
-/
#guard_msgs in
#check Espal.Clamp.fromQuery_ok

/-- info: 'Espal.Clamp.fromQuery_ok' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.Clamp.fromQuery_ok

/--
info: Espal.Api.mem_allowed_iff.{u} {α : Type u} (t : Espal.Api α) (path : List String) (m : Std.Http.Method) :
  m ∈ t.allowed path ↔ (Routing.matchTable t.routes m path).isSome = true
-/
#guard_msgs in
#check Espal.Api.mem_allowed_iff

/-- info: 'Espal.Api.mem_allowed_iff' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.Api.mem_allowed_iff

/--
info: Espal.LawfulQuery.fromQuery_toQuery {α : Type} {inst✝ : Espal.ToQuery α} {inst✝¹ : Espal.FromQuery α}
  [self : Espal.LawfulQuery α] (x : α) : Espal.fromQuery (Espal.toQuery x) = Except.ok x
-/
#guard_msgs in
#check Espal.LawfulQuery.fromQuery_toQuery

/-- info: 'Espal.instLawfulQueryNat' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.instLawfulQueryNat

/-- info: 'Espal.instLawfulQueryClamp' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.instLawfulQueryClamp

/-- info: 'Espal.instLawfulQueryOptionOfPresentQuery' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in
#print axioms Espal.instLawfulQueryOptionOfPresentQuery

/--
info: Espal.Costs.sent_le {α : Type} {x : Espal.Eff α} {n : Nat} (h : Espal.Costs x n) (world : Espal.World) :
  (x.eval world).snd.sent.length ≤ world.sent.length + n
-/
#guard_msgs in
#check Espal.Costs.sent_le

/-- info: 'Espal.Costs.sent_le' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in
#print axioms Espal.Costs.sent_le

/--
info: Espal.ReadOnly.written_eq {α : Type} {x : Espal.Eff α} (h : Espal.ReadOnly x) (world : Espal.World) :
  (x.eval world).snd.written = world.written
-/
#guard_msgs in
#check Espal.ReadOnly.written_eq

/-- info: 'Espal.ReadOnly.written_eq' depends on axioms: [propext] -/
#guard_msgs in
#print axioms Espal.ReadOnly.written_eq

/--
info: Espal.Link.toString_local (link : Espal.Link) :
  link.toString.toList.head? = some '/' ∧ link.toString.toList[1]? ≠ some '/' ∧ link.toString.toList[1]? ≠ some '\\'
-/
#guard_msgs in
#check Espal.Link.toString_local

/-- info: 'Espal.Link.toString_local' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Espal.Link.toString_local

/--
info: Espal.Eff.eval_bind {α β : Type} (x : Espal.Eff α) (f : α → Espal.Eff β) (world : Espal.World) :
  (x >>= f).eval world = (f (x.eval world).fst).eval (x.eval world).snd
-/
#guard_msgs in
#check Espal.Eff.eval_bind

/-- info: 'Espal.Eff.eval_bind' does not depend on any axioms -/
#guard_msgs in
#print axioms Espal.Eff.eval_bind

/--
info: Espal.Eff.eval_pure {α : Type} (a : α) (world : Espal.World) : (pure a).eval world = (a, world)
-/
#guard_msgs in
#check Espal.Eff.eval_pure

/--
info: Espal.costs_mapM {α β : Type} (f : α → Espal.Eff β) (xs : List α) {j : Nat} (hf : ∀ (a : α), Espal.Costs (f a) j) :
  Espal.Costs (List.mapM f xs) (xs.length * j)
-/
#guard_msgs in
#check Espal.costs_mapM

/-- info: 'Espal.costs_mapM' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in
#print axioms Espal.costs_mapM

/--
info: Espal.costs_forIn {α σ : Type} (xs : List α) (init : σ) (f : α → σ → Espal.Eff (ForInStep σ)) {j : Nat}
  (hf : ∀ (a : α) (s : σ), Espal.Costs (f a s) j) : Espal.Costs (forIn xs init f) (xs.length * j)
-/
#guard_msgs in
#check Espal.costs_forIn

/-- info: 'Espal.costs_forIn' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in
#print axioms Espal.costs_forIn
