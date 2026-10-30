module

public import EspalJson
meta import EspalJson
public import Json
meta import Json

/-!
Tests for `deriving Json` on recursive types. A field can hold the type itself, or an `Array`,
`List` or `Option` of it, in a structure or a constructor. The decoder reports failures inside
nested values at their full pointers, and the handler refuses other shapes.
-/

open Json Espal

public section

namespace DeriveRecursive

/-- The message from decoding `j` as `α`, or "ok". -/
def outcome (α : Type) [FromJson α] (j : Json) : String :=
  match (fromJson? j : Except String α) with
  | .ok _ => "ok"
  | .error e => e

inductive Tree where
  | leaf (value : Int32)
  |
  node (label : String) (kids : Array Tree) (first : Option Tree) (next? : Option Tree)
    (lst : List Tree) (short : label.length ≤ 3)
  | wrap (inner : Tree)
  deriving Json

structure Base where
  text : String
  deriving Json

structure Comment extends Base where
  replies : Array Comment
  parent? : Option Comment
  deriving Json

inductive Rose (α : Type) where
  | rose (value : α) (kids : List (Rose α))
  deriving Json

/-- A tree that uses every kind of recursive field. -/
def sample : Tree :=
  .node "a" #[.leaf 1] (some (.leaf 2)) (some (.wrap (.leaf 3))) [.leaf 4] (by decide)

/-- A chain of `n` wrappers around a leaf. -/
def chain : Nat → Tree
  | 0 => .leaf 0
  | n + 1 => .wrap (chain n)

/-! The encoder writes each recursive field as the type's own encoding would. -/

#guard
  compress (toJson sample) ==
    "{\"kind\":\"node\",\"label\":\"a\",\"kids\":[{\"kind\":\"leaf\",\"value\":1}],\
      \"first\":{\"kind\":\"leaf\",\"value\":2},\"next\":{\"kind\":\"wrap\",\"inner\":\
      {\"kind\":\"leaf\",\"value\":3}},\"lst\":[{\"kind\":\"leaf\",\"value\":4}]}"

#guard
  compress
      (toJson ({ text := "a", replies := #[⟨⟨"b"⟩, #[], none⟩], parent? := none } : Comment)) ==
    "{\"text\":\"a\",\"replies\":[{\"text\":\"b\",\"replies\":[]}]}"

/-! The decoder reads encoded values back, however deep. It reports a failure inside a nested
value at its full pointer. -/

#guard outcome Tree (toJson sample) == "ok"

#guard outcome Tree (toJson (chain 200)) == "ok"

#guard
  outcome Tree
      (mkObj
        [("kind", "node"), ("label", "a"),
          ("kids", .arr #[mkObj [("kind", "leaf"), ("value", "x")]]), ("first", .null),
          ("lst", .arr #[])]) ==
    "/kids/0/value: expected a number"

#guard
  outcome Tree
      (mkObj
        [("kind", "node"), ("label", "long"), ("kids", .arr #[]), ("first", .null),
          ("lst", .arr #[])]) ==
    "fails the check short"

#guard
  outcome Comment
      (mkObj [("text", "hi"), ("replies", .arr #[mkObj [("text", 3), ("replies", .arr #[])]])]) ==
    "/replies/0/text: expected a string"

#guard
  outcome (Rose Int32)
      (mkObj
        [("kind", "rose"), ("value", 1),
          ("kids", .arr #[mkObj [("kind", "rose"), ("value", "x"), ("kids", .arr #[])]])]) ==
    "/kids/0/value: expected a number"

example : LawfulJson (Rose (Array Int32)) :=
  inferInstance

/-! The handler refuses a recursive field in any other shape. -/

/--
error: cannot derive Json for Bad: the field kids has type Array
  (Option
    Bad), which contains Bad in a shape the handler doesn't cover. It covers Bad itself, and an Array, List or Option of it
-/
#guard_msgs in
inductive Bad where
  | leaf
  | node (kids : Array (Option Bad))
  deriving Json

/-! The derived proofs use only the standard axioms. -/

/-- info: 'DeriveRecursive.instLawfulJsonTree' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms instLawfulJsonTree

/--
info: 'DeriveRecursive.instLawfulJsonComment' depends on axioms: [propext, Classical.choice, Quot.sound]
-/
#guard_msgs in
#print axioms instLawfulJsonComment

end DeriveRecursive
