module

public import EspalJson
meta import EspalJson
public import Json
meta import Json

/-!
Tests for `deriving Json`. The derived decoder reports every failure with its JSON Pointer. It
decides proof fields once the data fields decode, rejects unknown keys and follows the
optional-field convention. The handler refuses the structures and field types it can't prove a
round trip for.
-/

open Json Espal

public section

/-- The message from decoding `j` as `α`, or "ok". -/
def outcome (α : Type) [FromJson α] (j : Json) : String :=
  match (fromJson? j : Except String α) with
  | .ok _ => "ok"
  | .error e => e

structure Range where
  lo : Int32
  hi : Int32
  note? : Option String := none
  ok : lo ≤ hi
  deriving Json

structure Tags where
  tags : Array String
  range : Range
  limit : Option Small
  few : tags.size ≤ 3
  low : range.lo ≤ 5
  deriving Json

structure Unit' where
  deriving Json

structure Base where
  x : Int32
  deriving Json

structure Child extends Base where
  y : Int32
  ok : x ≤ y
  deriving Json

/-! The encoder writes data fields in order, leaves out a `none` optional field and drops the `?`
from its key. A required `Option` field writes `null`. -/

#guard compress (toJson ({ lo := 1, hi := 2, ok := by decide } : Range)) == "{\"lo\":1,\"hi\":2}"

#guard
  compress (toJson ({ lo := 1, hi := 2, note? := some "a", ok := by decide } : Range)) ==
    "{\"lo\":1,\"hi\":2,\"note\":\"a\"}"

/-- A value with no tags and no limit. -/
def noTags : Tags :=
  { tags := #[], range := ⟨0, 1, none, by decide⟩, limit := none, few := by decide,
    low := by decide }

#guard compress (toJson noTags) == "{\"tags\":[],\"range\":{\"lo\":0,\"hi\":1},\"limit\":null}"

#guard compress (toJson ({ x := 1, y := 2, ok := by decide } : Child)) == "{\"x\":1,\"y\":2}"

/-! A missing key and `null` both decode an optional field to `none`. A required `Option` field
takes `null` but not a missing key. -/

#guard
  (do
      let j ← (parse "{\"lo\":1,\"hi\":2,\"note\":null}").toOption
      (fromJson? j : Except String Range).toOption.map (·.note?)) ==
    some none

#guard
  (do
      let j ← (parse "{\"lo\":1,\"hi\":2}").toOption
      (fromJson? j : Except String Range).toOption.map (·.note?)) ==
    some none

#guard
  outcome Tags (mkObj [("tags", .arr #[]), ("range", mkObj [("lo", 0), ("hi", 1)])]) ==
    "/limit: missing"

/-! The decoder reports every failing field with its pointer, in field order. Then it reports each
unknown key in the order the object lists it. -/

#guard
  outcome Range (mkObj [("lo", "x"), ("extra", .null), ("note", 3)]) ==
    "/lo: expected a number; /hi: missing; /note: expected a string; /extra: unknown key"

#guard
  outcome Tags
      (mkObj
        [("tags", .arr #["a", 1, "b", .null]), ("range", mkObj [("lo", 1), ("hi", 0)]),
          ("limit", .num (Number.ofInt (-1)))]) ==
    "/tags/1: expected a string; /tags/3: expected a string; /range: fails the check ok; \
    /limit: number is not a natural number of a workable size"

#guard outcome Range (.arr #[]) == "expected an object"

#guard outcome Unit' (mkObj []) == "ok"

/-! The decoder decides proof fields once every data field decodes, and reports each one that
fails. It reports unknown keys beside them. -/

#guard
  outcome Range (mkObj [("lo", 2), ("hi", 1), ("zz", 0)]) == "fails the check ok; /zz: unknown key"

#guard
  outcome Tags
      (mkObj
        [("tags", .arr #["a", "b", "c", "d"]), ("range", mkObj [("lo", 6), ("hi", 7)]),
          ("limit", .null)]) ==
    "fails the check few; fails the check low"

#guard outcome Child (mkObj [("x", 3), ("y", 2)]) == "fails the check ok"

/-! A pointer escapes `~` and `/` as RFC 6901 says, and a nested decoder extends the pointer its
caller passes. -/

#guard outcome Unit' (mkObj [("a/b~c", 1)]) == "/a~1b~0c: unknown key"

#guard
  match (decode ["items", "0"] (mkObj [("hi", 1)]) : Except _ Range) with
  | .error e => e.map (·.pointerString) == #["/items/0/lo"]
  | .ok _ => false

/-! The handler refuses what it can't prove a round trip for. -/

/--
error: cannot derive Json for HasNat: the field n has type Nat, which has no LawfulDecode instance
-/
#guard_msgs in
structure HasNat where
  n : Nat
  deriving Json

/--
error: cannot derive Json for NestedOption: the field x? has type Option Int32, which has no NotNullJson instance
-/
#guard_msgs in
structure NestedOption where
  x? : Option (Option Int32)
  deriving Json

/-- error: cannot derive Json for NotOption: the optional field x? needs an Option type, not Int32 -/
#guard_msgs in
structure NotOption where
  x? : Int32
  deriving Json

/-- error: cannot derive Json for SameKey: two fields use the key x -/
#guard_msgs in
structure SameKey where
  x : Int32
  x? : Option Int32
  deriving Json

/-- error: cannot derive Json for Param: the handler can't yet take a type with parameters -/
#guard_msgs in
structure Param (α : Type) where
  x : α
  deriving Json

/-- error: cannot derive Json for Tree: the handler can't yet take a type that contains itself -/
#guard_msgs in
structure Tree where
  kids : Array Tree
  deriving Json

/-! The derived proofs use only the standard axioms. -/

/-- info: 'instLawfulJsonTags' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms instLawfulJsonTags

/-- info: 'instLawfulJsonChild' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms instLawfulJsonChild
