/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalJson.Lawful

/-!
# Decoding with every failure

lean-json's `FromJson` stops at the first failure and returns a string. A `422` response names
every failing field by its JSON Pointer, so Espal decodes through `JsonDecode`, which returns
every failure with its position. `LawfulDecode` says decoding reads back what `toJson` writes.

A type with only a `FromJson` instance gets a `JsonDecode` that reports its one failure at the
current position. Arrays and lists decode their elements themselves, so a failure inside one
carries its index.
-/

@[expose] public section

universe u v

namespace Espal

open Json

/-- One failure while decoding, at a JSON Pointer into the body. -/
structure DecodeError where
  /-- The reference tokens, such as `["items", "1", "price"]` for `#/items/1/price`. -/
  pointer : List String
  /-- What went wrong there, such as "missing" or "expected a number". -/
  detail : String
  deriving Repr, BEq, DecidableEq, Inhabited

/-- Reads a value at `pointer`, or every failure in it. -/
class JsonDecode (α : Type u) where
  /-- The value at `pointer`, or every failure found in it. -/
  decode (pointer : List String) : Json → Except (Array DecodeError) α

/-- `decode` reads back what `toJson` writes, from any position. -/
class LawfulDecode (α : Type u) [ToJson α] [JsonDecode α] : Prop where
  /-- Decoding an encoded value gives that value back, wherever it sits. -/
  decode_toJson (pointer : List String) (x : α) : JsonDecode.decode pointer (toJson x) = .ok x

export JsonDecode (decode)
export LawfulDecode (decode_toJson)

instance (priority := low) instJsonDecodeOfFromJson {α : Type u} [FromJson α] : JsonDecode α where
  decode pointer j := (fromJson? j).mapError fun e => #[⟨pointer, e⟩]

instance (priority := low) {α : Type u} [ToJson α] [FromJson α] [LawfulJson α] : LawfulDecode α
    where
  decode_toJson pointer x := by simp [decode, fromJson?_toJson, Except.mapError]

/-! ## Combining results -/

/-- Both values, or every failure in either. -/
def both {α : Type u} {β : Type v} :
    Except (Array DecodeError) α → Except (Array DecodeError) β → Except (Array DecodeError) (α × β)
  | .ok a, .ok b => .ok (a, b)
  | .ok _, .error e => .error e
  | .error e, .ok _ => .error e
  | .error e, .error e' => .error (e ++ e')

@[simp]
theorem both_ok {α : Type u} {β : Type v} (a : α) (b : β) : both (.ok a) (.ok b) = .ok (a, b) :=
  rfl

/-- The elements of a JSON array from index `i` on, or every failure among them. -/
def decodeElems {α : Type u} [JsonDecode α] (pointer : List String) :
    Nat → List Json → Except (Array DecodeError) (List α)
  | _, [] => .ok []
  | i, j :: js =>
    (both (decode (pointer ++ [toString i]) j) (decodeElems pointer (i + 1) js)).map fun (a, as) =>
      a :: as

theorem decodeElems_map {α : Type u} [ToJson α] [JsonDecode α] [LawfulDecode α]
    (pointer : List String) :
    ∀ (i : Nat) (xs : List α), decodeElems pointer i (xs.map toJson) = .ok xs
  | _, [] => rfl
  | i, x :: xs => by
    simp only [List.map_cons, decodeElems, decode_toJson, decodeElems_map pointer (i + 1) xs,
      both_ok]
    rfl

instance {α : Type u} [JsonDecode α] : JsonDecode (Array α) where
  decode pointer
    | .arr elems => (decodeElems pointer 0 elems.toList).map List.toArray
    | _ => .error #[⟨pointer, "expected an array"⟩]

instance {α : Type u} [ToJson α] [JsonDecode α] [LawfulDecode α] : LawfulDecode (Array α) where
  decode_toJson pointer xs := by
    show (decodeElems pointer 0 (xs.map toJson).toList).map List.toArray = .ok xs
    rw [Array.toList_map, decodeElems_map]
    rfl

instance {α : Type u} [JsonDecode α] : JsonDecode (List α) where
  decode pointer
    | .arr elems => decodeElems pointer 0 elems.toList
    | _ => .error #[⟨pointer, "expected an array"⟩]

instance {α : Type u} [ToJson α] [JsonDecode α] [LawfulDecode α] : LawfulDecode (List α) where
  decode_toJson pointer xs := by
    show decodeElems pointer 0 (xs.toArray.map toJson).toList = .ok xs
    rw [Array.toList_map, decodeElems_map]

instance {α : Type u} [JsonDecode α] : JsonDecode (Option α) where
  decode pointer j := if j.isNull then .ok none else some <$> decode pointer j

@[simp]
theorem isNull_toJson {α : Type u} [ToJson α] [NotNullJson α] (x : α) :
    (toJson x).isNull = false := by
  have := toJson_ne_null x
  cases h : toJson x <;> simp_all [Json.isNull]

instance {α : Type u} [ToJson α] [JsonDecode α] [LawfulDecode α] [NotNullJson α] :
    LawfulDecode (Option α)
    where
  decode_toJson pointer
    | none => rfl
    | some x => by
      show (if (toJson x).isNull then .ok none else some <$> decode pointer (toJson x)) = _
      rw [isNull_toJson, decode_toJson]
      rfl

/-! ## Reporting -/

/-- The JSON Pointer of RFC 6901, such as `/items/1/price`. The root is the empty string. -/
def DecodeError.pointerString (e : DecodeError) : String :=
  String.join (e.pointer.map fun t => "/" ++ (t.replace "~" "~0").replace "/" "~1")

/-- Every failure, each as its pointer and what went wrong there. -/
def renderErrors (errors : Array DecodeError) : String :=
  "; ".intercalate
    (errors.toList.map fun e =>
      if e.pointer.isEmpty then e.detail else s!"{e.pointerString}: {e.detail}")

/-- A `FromJson` that reads through `decode` and puts every failure in its message. -/
abbrev JsonDecode.toFromJson (α : Type u) [JsonDecode α] : FromJson α where
  fromJson? j := (decode [] j).mapError renderErrors

theorem JsonDecode.lawfulJson (α : Type u) [ToJson α] [JsonDecode α] [LawfulDecode α] :
    @LawfulJson α _ (JsonDecode.toFromJson α) :=
  @LawfulJson.mk α _ (JsonDecode.toFromJson α) fun x => by
    show (decode [] (toJson x)).mapError renderErrors = .ok x
    rw [decode_toJson]
    rfl

end Espal
