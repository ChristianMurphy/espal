module

import EspalRoute
meta import EspalRoute

/-!
Tests for the route-table check in `EspalRoute.Table`. They check which segment pairs `overlaps`
reports. They also check that `decide +kernel` evaluates `linksDisjoint` on a concrete table, and
that `matchTable_pathOf` applies to one.
-/

open Routing Espal.Route

/-! `natAccepts` takes the numerals `toString` writes, and the kernel evaluates it. -/

example : natAccepts "0" = true := by decide +kernel

example : natAccepts "42" = true := by decide +kernel

example : natAccepts "" = false := by decide +kernel

example : natAccepts "00" = false := by decide +kernel

example : natAccepts "042" = false := by decide +kernel

example : natAccepts "1_000" = false := by decide +kernel

example : natAccepts "+1" = false := by decide +kernel

example : natAccepts "١" = false := by decide +kernel

#guard
  ["0", "42", "", "00", "042", "1_000", "+1", "١", "new"].all fun s =>
    natAccepts s == (Internal.parseNat? s).isSome

/-! Segment pairs. A `Nat` capture's link never renders `new` or `042`, and a `Nat` capture rejects
both, so neither pair overlaps in either order. -/

example : overlaps [.lit "new" (by decide)] [.capture "id" .nat] = false := by decide +kernel

example : overlaps [.capture "id" .nat] [.lit "new" (by decide)] = false := by decide +kernel

example : overlaps [.lit "042" (by decide)] [.capture "id" .nat] = false := by decide +kernel

example : overlaps [.capture "id" .nat] [.lit "042" (by decide)] = false := by decide +kernel

example : overlaps [.lit "42" (by decide)] [.capture "id" .nat] = true := by decide +kernel

example : overlaps [.lit "new" (by decide)] [.capture "name" .string] = true := by decide +kernel

/-- A `String` capture's link can carry `new`, so a later literal `new` is caught by it. -/
example : overlaps [.capture "name" .string] [.lit "new" (by decide)] = true := by decide +kernel

/-- `dispatch` accepts one trailing empty segment, so the root route catches the link `[""]`. -/
example : overlaps [] [.lit "" (by decide)] = true := by decide +kernel

example : overlaps [.lit "" (by decide)] [] = false := by decide +kernel

/-- `strCode` tells apart literals whose bytes differ only past the first byte of a character. -/
example : keysOverlap [segKey (.lit "é" (by decide))] [segKey (.lit "è" (by decide))] = false := by
  decide +kernel

example : keysOverlap [] [segKey (.lit "" (by decide))] = true := by decide +kernel

def users : List (Route String) :=
  [{ method := .get, segs := [.lit "users" (by decide), .lit "new" (by decide)],
     handler := "form" },
    { method := .get, segs := [.lit "users" (by decide), .capture "id" .nat],
      handler := fun n => s!"user {n}" },
    { method := .post, segs := [.lit "users" (by decide), .capture "id" .nat],
      handler := fun n => s!"update {n}" }]

theorem users_disjoint : linksDisjoint users = true := by decide +kernel

/-! The kernel evaluates `keysDisjoint`, which the `api` command checks in place of
`linksDisjoint`. -/

example : keysDisjoint (users.map routeKey) = true := by decide +kernel

/-- The link for user `n` reaches the second route, with `n`. -/
example (n : Nat) :
    matchTable users .get ["users", toString n] = some (⟨.get, users[1].segs⟩, s!"user {n}") :=
  matchTable_pathOf users_disjoint ⟨1, by decide⟩ (n, ()) trivial

#guard (matchTable users .get ["users", "new"]).map (·.2) == some "form"

#guard (matchTable users .get ["users", "42"]).map (·.2) == some "user 42"

/-- `/users/new` catches the link for a user named `new`. -/
def byName : List (Route String) :=
  [{ method := .get, segs := [.lit "users" (by decide), .lit "new" (by decide)],
     handler := "form" },
    { method := .get, segs := [.lit "users" (by decide), .capture "name" .string],
      handler := fun s => s!"user {s}" }]

example : linksDisjoint byName = false := by decide +kernel

example : keysDisjoint (byName.map routeKey) = false := by decide +kernel

#guard (matchTable byName .get ["users", "new"]).map (·.2) == some "form"

/-- The same pattern under two methods is fine, and under one method it isn't. -/
example :
    linksDisjoint
        [({ method := .get, segs := [.lit "a" (by decide)], handler := "get" } : Route String),
          { method := .post, segs := [.lit "a" (by decide)], handler := "post" }] =
      true := by
  decide +kernel

example :
    linksDisjoint
        [({ method := .get, segs := [.lit "a" (by decide)], handler := "one" } : Route String),
          { method := .get, segs := [.lit "a" (by decide)], handler := "two" }] =
      false := by
  decide +kernel

/-- The root route catches the link for `[.lit ""]`. -/
example :
    linksDisjoint
        [({ method := .get, segs := [], handler := "root" } : Route String),
          { method := .get, segs := [.lit "" (by decide)], handler := "empty" }] =
      false := by
  decide +kernel
