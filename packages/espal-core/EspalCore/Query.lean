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

end Espal
