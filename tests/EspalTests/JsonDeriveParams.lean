module

public import EspalJson
meta import EspalJson
public import Json
meta import Json

/-!
Tests for `deriving Json` on types with parameters. A parameter that a data field's type mentions
takes codec instances, and `NotNullJson` only when a field needs it. A phantom parameter takes
none. The handler refuses a parameter it can't give a codec, and a check it can't decide.
-/

open Json Espal

public section

namespace DeriveParams

/-- The message from decoding `j` as `α`, or "ok". -/
def outcome (α : Type) [FromJson α] (j : Json) : String :=
  match (fromJson? j : Except String α) with
  | .ok _ => "ok"
  | .error e => e

structure Page (α : Type) where
  items : Array α
  next? : Option String
  deriving Json

structure Maybe (α : Type) where
  value? : Option α
  deriving Json

structure Key (α : Type) where
  id : Int32
  deriving Json

structure Bounded (n : Nat) where
  x : Int32
  ok : x.toInt < n
  deriving Json

universe u in
structure Box (α : Type u) where
  val : α
  deriving Json

inductive Result (ε α : Type) where
  | ok (value : α)
  | err (error : ε)
  deriving Json

/-- A type with no codec, which a phantom parameter can still name. -/
structure Opaque where
  x : Int32

/-! Each derived instance takes codecs only for the parameters its fields use. -/

/--
info: @instLawfulDecodePage : ∀ {α : Type} [inst : ToJson α] [inst_1 : JsonDecode α] [LawfulDecode α], LawfulDecode (Page α)
-/
#guard_msgs in
#check @instLawfulDecodePage

/--
info: @instLawfulDecodeMaybeOfNotNullJson : ∀ {α : Type} [inst : ToJson α] [inst_1 : JsonDecode α] [LawfulDecode α]
  [NotNullJson α], LawfulDecode (Maybe α)
-/
#guard_msgs in
#check @instLawfulDecodeMaybeOfNotNullJson

/-- info: @instLawfulDecodeKey : ∀ {α : Type}, LawfulDecode (Key α) -/
#guard_msgs in
#check @instLawfulDecodeKey

example : LawfulJson (Key Opaque) :=
  inferInstance

example : LawfulJson (Page (Key Opaque)) :=
  inferInstance

example : LawfulJson (Result String (Page Int32)) :=
  inferInstance

example : LawfulJson (Box.{0} Small) :=
  inferInstance

/-! The decoders work through the parameters' own decoders, with the same pointers. -/

#guard outcome (Page Int32) (mkObj [("items", .arr #[1, "x"])]) == "/items/1: expected a number"

#guard outcome (Bounded 3) (mkObj [("x", 5)]) == "fails the check ok"

#guard outcome (Bounded 3) (mkObj [("x", 2)]) == "ok"

#guard
  outcome (Result String (Page Int32))
      (mkObj [("kind", "ok"), ("value", mkObj [("items", .arr #["a"])])]) ==
    "/value/items/0: expected a number"

#guard compress (toJson (Result.ok (ε := String) (3 : Int32))) == "{\"kind\":\"ok\",\"value\":3}"

/-! The handler refuses a parameter it can't give a codec, and a check it can't decide. -/

/-- error: cannot derive Json for HK: a field's type mentions the parameter f, which isn't a type -/
#guard_msgs in
structure HK (f : Type → Type) where
  x : f Int32
  deriving Json

/--
error: cannot derive Json for NestedOpt: the field x? has type Option α, which has no NotNullJson instance
-/
#guard_msgs in
structure NestedOpt (α : Type) where
  x? : Option (Option α)
  deriving Json

/-- error: cannot derive Json for PropParam: the check h has no Decidable instance, so the decoder can't decide it -/
#guard_msgs in
structure PropParam (p : Prop) where
  x : Int32
  h : p
  deriving Json

/-- error: cannot derive Json for Distinct: the check ne has no Decidable instance, so the decoder can't decide it -/
#guard_msgs in
structure Distinct (α : Type) where
  x : α
  y : α
  ne : x ≠ y
  deriving Json

/-! The derived proofs use only the standard axioms. -/

/-- info: 'DeriveParams.instLawfulDecodePage' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms instLawfulDecodePage

/-- info: 'DeriveParams.instLawfulDecodeResult' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms instLawfulDecodeResult

end DeriveParams
