/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalJson.Object

/-!
# Codecs for recursive types

A recursive type has no `JsonDecode` instance while its decoder is being defined. So the derived
decoder reads a field such as `kids : Array Tree` with the functions here, which take the element
decoder as an argument.

The derived decoder takes a count, and every recursive call passes one less. The instance starts
it at the depth of the input plus one. Each level of a value adds a level of nesting, so the
count never runs out before the input does. The lemmas here bound the depth of a field by the
depth of the object that holds it. The round-trip proof needs that bound.
-/

@[expose] public section

universe u

namespace Espal

open Json

/-- Appends the field `(key, j)`. -/
def pushJson (fields : Array (String × Json)) (key : String) (j : Json) : Array (String × Json) :=
  fields.push (key, j)

/-- Appends the field `(key, j)` if there is a `j`. -/
def pushOptJson (fields : Array (String × Json)) (key : String) :
    Option Json → Array (String × Json)
  | none => fields
  | some j => fields.push (key, j)

/-- A required field's value from its lookup, through `d`. -/
def requiredWith {α : Type u} (d : List String → Json → Except (Array DecodeError) α)
    (pointer : List String) : Option Json → Except (Array DecodeError) α
  | some j => d pointer j
  | none => .error #[⟨pointer, "missing"⟩]

/-- An `Option` through `d`, with `null` for `none`. -/
def optionWith {α : Type u} (d : List String → Json → Except (Array DecodeError) α)
    (pointer : List String) (j : Json) : Except (Array DecodeError) (Option α) :=
  if j.isNull then .ok none else some <$> d pointer j

/-- An optional field's value from its lookup, through `d`. -/
def optionalWith {α : Type u} (d : List String → Json → Except (Array DecodeError) α)
    (pointer : List String) : Option Json → Except (Array DecodeError) (Option α)
  | some j => optionWith d pointer j
  | none => .ok none

/-- The elements of a JSON array from index `i` on, through `d`. -/
def elemsWith {α : Type u} (d : List String → Json → Except (Array DecodeError) α)
    (pointer : List String) : Nat → List Json → Except (Array DecodeError) (List α)
  | _, [] => .ok []
  | i, j :: js =>
    (both (d (pointer ++ [toString i]) j) (elemsWith d pointer (i + 1) js)).map fun (a, as) =>
      a :: as

/-- An array through `d`. -/
def arrayWith {α : Type u} (d : List String → Json → Except (Array DecodeError) α)
    (pointer : List String) : Json → Except (Array DecodeError) (Array α)
  | .arr elems => (elemsWith d pointer 0 elems.toList).map List.toArray
  | _ => .error #[⟨pointer, "expected an array"⟩]

/-- A list through `d`. -/
def listWith {α : Type u} (d : List String → Json → Except (Array DecodeError) α)
    (pointer : List String) : Json → Except (Array DecodeError) (List α)
  | .arr elems => elemsWith d pointer 0 elems.toList
  | _ => .error #[⟨pointer, "expected an array"⟩]

/-! ## Lemmas for the derived proofs -/

/-- An `Option`'s value is smaller than the `Option`, which the derived encoder's termination needs. -/
theorem sizeOf_lt_of_eq_some {α : Type u} [SizeOf α] {o : Option α} {x : α} (h : o = some x) :
    sizeOf x < sizeOf o := by
  subst h
  simp

@[simp]
theorem findLast?_pushJson (fields : Array (String × Json)) (key : String) (j : Json) (k : String) :
    findLast? (pushJson fields key j) k = if key == k then some j else findLast? fields k :=
  findLast?_push fields key j k

@[simp]
theorem findLast?_pushOptJson (fields : Array (String × Json)) (key : String) (o : Option Json)
    (k : String) :
    findLast? (pushOptJson fields key o) k =
      if key == k then o.or (findLast? fields k) else findLast? fields k := by
  cases o <;> split <;> simp_all [pushOptJson, findLast?_push]

@[simp]
theorem unknownKeys_pushJson (pointer : List String) (fields : Array (String × Json))
    (known : List String) (k : String) (j : Json) (h : k ∈ known) :
    unknownKeys pointer (pushJson fields k j) known = unknownKeys pointer fields known :=
  unknownKeys_push pointer fields known k j h

@[simp]
theorem unknownKeys_pushOptJson (pointer : List String) (fields : Array (String × Json))
    (known : List String) (k : String) (o : Option Json) (h : k ∈ known) :
    unknownKeys pointer (pushOptJson fields k o) known = unknownKeys pointer fields known := by
  cases o <;> simp [pushOptJson, h]

@[simp]
theorem requiredWith_some {α : Type u} (d : List String → Json → Except (Array DecodeError) α)
    (pointer : List String) (j : Json) : requiredWith d pointer (some j) = d pointer j :=
  rfl

theorem elemsWith_map {α : Type u} (d : List String → Json → Except (Array DecodeError) α)
    (f : α → Json) (pointer : List String) :
    ∀ (i : Nat) (xs : List α),
      (∀ x ∈ xs, ∀ p, d p (f x) = .ok x) → elemsWith d pointer i (xs.map f) = .ok xs
  | _, [], _ => rfl
  | i, x :: xs, h => by
    simp only [List.map_cons, elemsWith, h x List.mem_cons_self,
      elemsWith_map d f pointer (i + 1) xs fun y hy => h y (List.mem_cons_of_mem x hy), both_ok]
    rfl

theorem arrayWith_map {α : Type u} (d : List String → Json → Except (Array DecodeError) α)
    (f : α → Json) (xs : Array α) (h : ∀ x ∈ xs, ∀ p, d p (f x) = .ok x) (pointer : List String) :
    arrayWith d pointer (.arr (xs.map f)) = .ok xs := by
  simp only [arrayWith, Array.toList_map]
  rw [elemsWith_map d f pointer 0 xs.toList fun x hx => h x (by simpa using hx)]
  rfl

theorem listWith_map {α : Type u} (d : List String → Json → Except (Array DecodeError) α)
    (f : α → Json) (xs : List α) (h : ∀ x ∈ xs, ∀ p, d p (f x) = .ok x) (pointer : List String) :
    listWith d pointer (.arr (xs.map f).toArray) = .ok xs := by
  simp only [listWith]
  exact elemsWith_map d f pointer 0 xs h

theorem optionWith_map {α : Type u} (d : List String → Json → Except (Array DecodeError) α)
    (f : α → Json) (o : Option α) (h : ∀ x, o = some x → ∀ p, d p (f x) = .ok x)
    (hnull : ∀ x, f x ≠ .null) (pointer : List String) :
    optionWith d pointer ((o.map f).getD .null) = .ok o := by
  cases o with
  | none => rfl
  | some x =>
    have : (f x).isNull = false := by cases hx : f x <;> simp_all [Json.isNull]
    simp [optionWith, this, h x rfl]
    rfl

theorem optionalWith_map {α : Type u} (d : List String → Json → Except (Array DecodeError) α)
    (f : α → Json) (o : Option α) (h : ∀ x, o = some x → ∀ p, d p (f x) = .ok x)
    (hnull : ∀ x, f x ≠ .null) (pointer : List String) :
    optionalWith d pointer (o.map f) = .ok o := by
  cases o with
  | none => rfl
  | some x => exact optionWith_map d f (some x) h hnull pointer

/-- A field's value is less deep than the object that holds it, by at least one level. -/
theorem depth_lt_of_field {fields : Array (String × Json)} {k : String} {v : Json} {n : Nat}
    (h : (Json.obj fields).depth < n + 1) (hm : (k, v) ∈ fields) : v.depth < n := by
  have := depth_obj_lt hm
  omega

theorem depth_lt_of_mem_array {α : Type u} {xs : Array α} {f : α → Json} {x : α} {n : Nat}
    (h : (Json.arr (xs.map f)).depth < n) (hx : x ∈ xs) : (f x).depth < n :=
  Nat.lt_trans (depth_arr_lt (Array.mem_map_of_mem hx)) h

theorem depth_lt_of_mem_list {α : Type u} {xs : List α} {f : α → Json} {x : α} {n : Nat}
    (h : (Json.arr (xs.map f).toArray).depth < n) (hx : x ∈ xs) : (f x).depth < n :=
  Nat.lt_trans (depth_arr_lt (by simpa using List.mem_map_of_mem hx)) h

theorem depth_lt_of_eq_some {α : Type u} {o : Option α} {f : α → Json} {x : α} {n : Nat}
    (h : ((o.map f).getD .null).depth < n) (hx : o = some x) : (f x).depth < n := by
  subst hx
  simpa using h

theorem depth_lt_of_map_eq_some {α : Type u} {o : Option α} {f : α → Json} {x : α} {n : Nat}
    (h : ∀ j, o.map f = some j → j.depth < n) (hx : o = some x) : (f x).depth < n :=
  h (f x) (by simp [hx])

@[simp]
theorem mem_pushField {α : Type u} [ToJson α] (fields : Array (String × Json)) (key : String)
    (v : α) (x : String × Json) :
    x ∈ pushField fields key v ↔ x ∈ fields ∨ x = (key, toJson v) := by simp [pushField]

@[simp]
theorem mem_pushOpt {α : Type u} [ToJson α] (fields : Array (String × Json)) (key : String)
    (o : Option α) (x : String × Json) :
    x ∈ pushOpt fields key o ↔ x ∈ fields ∨ ∃ v, o = some v ∧ x = (key, toJson v) := by
  cases o <;> simp [pushOpt]

@[simp]
theorem mem_pushTag (fields : Array (String × Json)) (tag : String) (x : String × Json) :
    x ∈ pushTag fields tag ↔ x ∈ fields ∨ x = ("kind", .str tag) := by simp [pushTag]

@[simp]
theorem mem_pushJson (fields : Array (String × Json)) (key : String) (j : Json)
    (x : String × Json) : x ∈ pushJson fields key j ↔ x ∈ fields ∨ x = (key, j) := by
  simp [pushJson]

@[simp]
theorem mem_pushOptJson (fields : Array (String × Json)) (key : String) (o : Option Json)
    (x : String × Json) :
    x ∈ pushOptJson fields key o ↔ x ∈ fields ∨ ∃ j, o = some j ∧ x = (key, j) := by
  cases o <;> simp [pushOptJson]

end Espal
