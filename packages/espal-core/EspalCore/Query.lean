/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

/-!
# Query parameters

A handler's argument whose type has a `FromQuery` instance reads the query parameter with the
argument's name. `Nat`, `Bool` and `String` are required, and `Option α` makes one optional. A
repeated key reads its first value.

`Clamp lo hi` is a natural number kept between two bounds. A missing or malformed value reads as
`lo`, and a value outside the bounds moves to the nearest one. So a clamped parameter never
refuses a request.
-/

@[expose] public section

namespace Espal

/-- A request's query string as decoded keys and values, in the order they arrived. -/
abbrev Query :=
  List (String × String)

/-- The first value of `key`, if the query has the key. -/
def Query.first? (query : Query) (key : String) : Option String :=
  (query.find? (·.1 == key)).map (·.2)

/-- How one query parameter becomes a handler's argument. -/
class FromQuery (α : Type) where
  /-- The value of a parameter, where `none` means its key is absent, or what is wrong with it. -/
  fromQuery : Option String → Except String α

export FromQuery (fromQuery)

/-- The natural number that `s` spells in decimal digits. -/
def natOfDigits? (s : String) : Option Nat :=
  if !s.isEmpty && s.all Char.isDigit then some (Nat.ofDigitChars 10 s.toList 0) else none

instance : FromQuery String where
  fromQuery
    | some s => .ok s
    | none => .error "missing"

instance : FromQuery Nat where
  fromQuery
    | some s =>
      match natOfDigits? s with
      | some n => .ok n
      | none => .error "expected a natural number"
    | none => .error "missing"

instance : FromQuery Bool where
  fromQuery
    | some "true" => .ok true
    | some "false" => .ok false
    | some _ => .error "expected true or false"
    | none => .error "missing"

/-- An optional parameter is `none` when its key is absent. -/
instance {α : Type} [FromQuery α] : FromQuery (Option α) where
  fromQuery
    | none => .ok none
    | some s => some <$> fromQuery (some s)

/-- A natural number kept between `lo` and `hi`. -/
structure Clamp (lo hi : Nat) where
  /-- The number. -/
  val : Nat
  /-- It is at least `lo`. -/
  ge : lo ≤ val
  /-- It is at most `hi`. -/
  le : val ≤ hi
  deriving Repr, DecidableEq

/-- `n` moved to the nearest bound, when it lies outside them. -/
def Clamp.ofNat {lo hi : Nat} (h : lo ≤ hi) (n : Nat) : Clamp lo hi :=
  ⟨min (max n lo) hi, by omega, by omega⟩

/-- A missing or malformed value reads as `lo`, and any other value is clamped. -/
instance {lo hi : Nat} : FromQuery (Clamp lo hi) where
  fromQuery s :=
    if h : lo ≤ hi then .ok (.ofNat h ((s.bind natOfDigits?).getD lo))
    else .error "no value lies between the bounds"

/-- A clamped parameter never refuses a request. -/
theorem Clamp.fromQuery_ok (lo hi : Nat) (h : lo ≤ hi) (s : Option String) :
    ∃ c : Clamp lo hi, fromQuery s = .ok c :=
  ⟨.ofNat h ((s.bind natOfDigits?).getD lo), dite_eq_left h⟩

/-! ## Writing a query -/

/-- How a handler's argument becomes a query parameter in a link. -/
class ToQuery (α : Type) where
  /-- The parameter's value, where `none` leaves its key out of the link. -/
  toQuery : α → Option String

export ToQuery (toQuery)

/-- `toQuery` always writes a value, so `Option α` can use a missing key for `none`. -/
class PresentQuery (α : Type) [ToQuery α] : Prop where
  /-- Every value writes a parameter. -/
  toQuery_isSome (x : α) : (toQuery x).isSome = true

/-- `fromQuery` reads back what `toQuery` writes. -/
class LawfulQuery (α : Type) [ToQuery α] [FromQuery α] : Prop where
  /-- Reading a written parameter gives the value back. -/
  fromQuery_toQuery (x : α) : fromQuery (toQuery x) = .ok x

export LawfulQuery (fromQuery_toQuery)

attribute [simp] fromQuery_toQuery

/-- `natOfDigits?` reads back every natural number that `toString` prints. -/
theorem natOfDigits?_toString (n : Nat) : natOfDigits? (toString n) = some n := by
  have hne : (toString n).isEmpty = false := by
    rw [String.isEmpty_eq_false_iff]
    intro he
    have := Nat.length_repr_pos (n := n)
    rw [← Nat.toString_eq_repr, he] at this
    exact absurd this (by decide)
  have hall : (toString n).all Char.isDigit = true := by
    rw [String.all_bool_eq, Nat.toString_eq_repr, Nat.toList_repr, List.all_eq_true]
    exact fun c hc => Nat.isDigit_of_mem_toDigits (by decide) (by decide) hc
  simp only [natOfDigits?, hne, hall, Bool.not_false, Bool.and_self, ↓reduceIte, Option.some.injEq]
  rw [Nat.toString_eq_repr, Nat.toList_repr, Nat.ofDigitChars_ten_toDigits]

instance : ToQuery String :=
  ⟨some⟩

instance : PresentQuery String :=
  ⟨fun _ => rfl⟩

instance : LawfulQuery String :=
  ⟨fun _ => rfl⟩

instance : ToQuery Nat :=
  ⟨fun n => some (toString n)⟩

instance : PresentQuery Nat :=
  ⟨fun _ => rfl⟩

instance : LawfulQuery Nat :=
  ⟨fun n => by
    show
      (match natOfDigits? (toString n) with
        | some n => Except.ok n
        | none => .error "expected a natural number") =
        _
    rw [natOfDigits?_toString]⟩

instance : ToQuery Bool :=
  ⟨fun b => some (if b then "true" else "false")⟩

instance : PresentQuery Bool :=
  ⟨fun _ => rfl⟩

instance : LawfulQuery Bool :=
  ⟨fun b => by cases b <;> rfl⟩

/-- `none` leaves the key out. -/
instance {α : Type} [ToQuery α] : ToQuery (Option α) :=
  ⟨fun o => o.bind toQuery⟩

instance {α : Type} [ToQuery α] [FromQuery α] [PresentQuery α] [LawfulQuery α] :
    LawfulQuery (Option α) :=
  ⟨fun o => by
    cases o with
    | none => rfl
    | some x =>
      obtain ⟨s, hs⟩ := Option.isSome_iff_exists.1 (PresentQuery.toQuery_isSome x)
      show fromQuery (α := Option α) (toQuery x) = _
      rw [hs]
      show some <$> fromQuery (some s) = _
      rw [← hs, fromQuery_toQuery]
      rfl⟩

instance {lo hi : Nat} : ToQuery (Clamp lo hi) :=
  ⟨fun c => some (toString c.val)⟩

instance {lo hi : Nat} : PresentQuery (Clamp lo hi) :=
  ⟨fun _ => rfl⟩

instance {lo hi : Nat} : LawfulQuery (Clamp lo hi) :=
  ⟨fun c => by
    have h : lo ≤ hi := Nat.le_trans c.ge c.le
    show
      (if h : lo ≤ hi then
          Except.ok (Clamp.ofNat h (((some (toString c.val)).bind natOfDigits?).getD lo))
        else .error "no value lies between the bounds") =
        _
    rw [dite_eq_left h]
    simp only [Option.bind_some, natOfDigits?_toString, Option.getD_some, Clamp.ofNat]
    cases c with
    | mk val ge le =>
      congr 1
      simp only [Clamp.mk.injEq]
      omega⟩

/-! ## Links -/

/-- A link before it is written as a URL. It holds the decoded path segments and query parameters. -/
structure Link where
  /-- The decoded path segments. -/
  path : List String
  /-- The decoded query parameters, in order. -/
  query : Query
  deriving Repr, BEq, DecidableEq

/-- `rest` with the parameter `name` for `x` in front, if `x` writes one. -/
def Query.with {α : Type} [ToQuery α] (name : String) (x : α) (rest : Query) : Query :=
  match toQuery x with
  | some value => (name, value) :: rest
  | none => rest

@[simp]
theorem Query.first?_nil (key : String) : Query.first? [] key = none :=
  rfl

@[simp]
theorem Query.first?_with {α : Type} [ToQuery α] (name : String) (x : α) (rest : Query)
    (key : String) :
    (Query.with name x rest).first? key =
      if name == key then (toQuery x).or (rest.first? key) else rest.first? key := by
  unfold Query.with
  cases toQuery x <;> cases hk : name == key <;> simp_all [Query.first?]

end Espal
