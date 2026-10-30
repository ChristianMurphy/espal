module

public import EspalJson
meta import EspalJson
public import Json
meta import Json

/-!
Tests for `deriving Json` on inductive types. Constructors without arguments become strings. Any
other type becomes objects whose `kind` key names the constructor. The decoder reports a missing,
mistyped or unknown tag at `/kind`, and decodes the rest of the object as a structure.
-/

open Json Espal

public section

namespace DeriveInductive

/-- The message from decoding `j` as `α`, or "ok". -/
def outcome (α : Type) [FromJson α] (j : Json) : String :=
  match (fromJson? j : Except String α) with
  | .ok _ => "ok"
  | .error e => e

inductive Colour where
  | red
  | green
  | blue
  deriving Json

inductive Shape where
  | circle (radius : Small)
  | rect (w h : Int32) (label? : Option String) (wide : h ≤ w)
  | point
  deriving Json

structure Holder where
  shape : Shape
  colour : Colour
  deriving Json

/-! A constructor without arguments is a string when every constructor is one, and an object with
only `kind` otherwise. Proofs stay out of the object. -/

#guard compress (toJson Colour.green) == "\"green\""

#guard compress (toJson (Shape.rect 3 2 none (by decide))) == "{\"kind\":\"rect\",\"w\":3,\"h\":2}"

#guard compress (toJson Shape.point) == "{\"kind\":\"point\"}"

#guard outcome Colour "blue" == "ok"

#guard outcome Shape (mkObj [("kind", "point")]) == "ok"

#guard outcome Shape "point" == "expected an object"

/-! A tag the type doesn't have, or one that isn't a string, fails at the tag. -/

#guard outcome Colour "pink" == "expected one of red, green, blue"

#guard outcome Colour 3 == "expected a string"

#guard outcome Shape (mkObj [("kind", "triangle")]) == "/kind: expected one of circle, rect, point"

#guard outcome Shape (mkObj [("kind", 3)]) == "/kind: expected a string"

#guard outcome Shape (mkObj [("radius", 3)]) == "/kind: missing"

/-! Once the tag decodes, the decoder reads the constructor's fields as it reads a structure's. -/

#guard outcome Shape (mkObj [("kind", "rect"), ("w", "a")]) == "/w: expected a number; /h: missing"

#guard
  outcome Shape (mkObj [("kind", "rect"), ("w", 1), ("h", 2), ("x", 0)]) ==
    "fails the check wide; /x: unknown key"

#guard
  outcome Holder
      (mkObj [("shape", mkObj [("kind", "circle"), ("radius", "big")]), ("colour", "teal")]) ==
    "/shape/radius: expected a number; /colour: expected one of red, green, blue"

/-! The handler refuses what it can't encode or prove a round trip for. -/

/--
error: cannot derive Json for Anon: an argument of Anon.a has no name to use as its key. Name it, as in `circle (radius : Small)`
-/
#guard_msgs in
inductive Anon where
  | a : Int32 → Anon
  deriving Json

/-- error: cannot derive Json for Kinded: the field kind uses the key kind, which names the constructor -/
#guard_msgs in
inductive Kinded where
  | c (kind : String)
  deriving Json

/-- error: cannot derive Json for NoCtor: it has no constructors, so no value has an encoding -/
#guard_msgs in
inductive NoCtor where
  deriving Json

/-- error: cannot derive Json for Tree: the handler can't yet take a type that contains itself -/
#guard_msgs in
inductive Tree where
  | leaf
  | node (kids : Array Tree)
  deriving Json

/-- error: cannot derive Json for Vec: the handler can't yet take a type with indices -/
#guard_msgs in
inductive Vec : Nat → Type where
  | nil : Vec 0
  deriving Json

/-! The derived proofs use only the standard axioms. -/

/-- info: 'DeriveInductive.instLawfulJsonColour' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms instLawfulJsonColour

/-- info: 'DeriveInductive.instLawfulJsonShape' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms instLawfulJsonShape

end DeriveInductive
