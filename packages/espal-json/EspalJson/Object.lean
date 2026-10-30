/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalJson.Decode

/-!
# Objects with named fields

A derived codec writes a structure as an object with one key per field, and reads it back with
the functions here. The lemmas let the derived round-trip proof run as one `simp` call. Each
lookup reduces through the pushes that built the object, and no proof splits on whether an
optional field is present.

A field named with a trailing `?` is optional. The encoder leaves it out when it is `none`, and
the decoder reads both a missing key and `null` as `none`. The key drops the `?`.
-/

@[expose] public section

universe u

namespace Espal

open Json

/-- Appends the field `(key, toJson v)`. -/
def pushField {α : Type u} [ToJson α] (fields : Array (String × Json)) (key : String) (v : α) :
    Array (String × Json) :=
  fields.push (key, toJson v)

/-- Appends the field `(key, toJson v)` if the value is `some v`. -/
def pushOpt {α : Type u} [ToJson α] (fields : Array (String × Json)) (key : String) :
    Option α → Array (String × Json)
  | none => fields
  | some v => fields.push (key, toJson v)

/-- A required field's value from its lookup, or "missing". -/
def required {α : Type u} [JsonDecode α] (pointer : List String) :
    Option Json → Except (Array DecodeError) α
  | some j => decode pointer j
  | none => .error #[⟨pointer, "missing"⟩]

/-- An optional field's value from its lookup. A missing key and `null` both give `none`. -/
def optional {α : Type u} [JsonDecode α] (pointer : List String) :
    Option Json → Except (Array DecodeError) (Option α)
  | some j => decode pointer j
  | none => .ok none

/-- The field named `key`, or "missing" if the object has none. -/
def field {α : Type u} [JsonDecode α] (pointer : List String) (fields : Array (String × Json))
    (key : String) : Except (Array DecodeError) α :=
  required (pointer ++ [key]) (findLast? fields key)

/-- The optional field named `key`. -/
def optField {α : Type u} [JsonDecode α] (pointer : List String) (fields : Array (String × Json))
    (key : String) : Except (Array DecodeError) (Option α) :=
  optional (pointer ++ [key]) (findLast? fields key)

/-- A failure for each key not in `known`, in the order the object lists them. -/
def unknownKeys (pointer : List String) (fields : Array (String × Json)) (known : List String) :
    Array DecodeError :=
  fields.filterMap fun (k, _) =>
    if known.contains k then none else some ⟨pointer ++ [k], "unknown key"⟩

/-- A failure if the decoded fields fail a check, saying which. -/
def check (pointer : List String) (detail : String) (p : Prop) [Decidable p] : Array DecodeError :=
  if p then #[] else #[⟨pointer, detail⟩]

/-- The value, unless an earlier step found unknown keys. -/
def finish {α : Type u} (extra : Array DecodeError) (x : α) : Except (Array DecodeError) α :=
  if extra.isEmpty then .ok x else .error extra

/-! ## Lemmas for the derived proofs -/

@[simp]
theorem findLast?_empty {α : Type u} (k : String) : findLast? (#[] : Array (String × α)) k = none :=
  rfl

@[simp]
theorem findLast?_pushField {α : Type u} [ToJson α] (fields : Array (String × Json)) (key : String)
    (v : α) (k : String) :
    findLast? (pushField fields key v) k =
      if key == k then some (toJson v) else findLast? fields k :=
  findLast?_push fields key (toJson v) k

@[simp]
theorem findLast?_pushOpt {α : Type u} [ToJson α] (fields : Array (String × Json)) (key : String)
    (o : Option α) (k : String) :
    findLast? (pushOpt fields key o) k =
      if key == k then (o.map toJson).or (findLast? fields k) else findLast? fields k := by
  cases o <;> split <;> simp_all [pushOpt, findLast?_push]

@[simp]
theorem required_some_toJson {α : Type u} [ToJson α] [JsonDecode α] [LawfulDecode α]
    (pointer : List String) (x : α) : required pointer (some (toJson x)) = .ok x :=
  decode_toJson pointer x

@[simp]
theorem optional_map_toJson {α : Type u} [ToJson α] [JsonDecode α] [LawfulDecode α] [NotNullJson α]
    (pointer : List String) (o : Option α) : optional pointer (o.map toJson) = .ok o := by
  cases o with
  | none => rfl
  | some x => exact decode_toJson (α := Option α) pointer (some x)

@[simp]
theorem unknownKeys_empty (pointer : List String) (known : List String) :
    unknownKeys pointer #[] known = #[] :=
  rfl

@[simp]
theorem unknownKeys_push (pointer : List String) (fields : Array (String × Json))
    (known : List String) (k : String) (j : Json) (h : k ∈ known) :
    unknownKeys pointer (fields.push (k, j)) known = unknownKeys pointer fields known := by
  simp [unknownKeys, h]

@[simp]
theorem unknownKeys_pushField {α : Type u} [ToJson α] (pointer : List String)
    (fields : Array (String × Json)) (known : List String) (k : String) (v : α) (h : k ∈ known) :
    unknownKeys pointer (pushField fields k v) known = unknownKeys pointer fields known :=
  unknownKeys_push pointer fields known k (toJson v) h

@[simp]
theorem unknownKeys_pushOpt {α : Type u} [ToJson α] (pointer : List String)
    (fields : Array (String × Json)) (known : List String) (k : String) (o : Option α)
    (h : k ∈ known) :
    unknownKeys pointer (pushOpt fields k o) known = unknownKeys pointer fields known := by
  cases o <;> simp [pushOpt, h]

@[simp]
theorem finish_empty {α : Type u} (x : α) : finish #[] x = .ok x :=
  rfl

end Espal
