module

import EspalJson
meta import EspalJson
import Json
meta import Json

/-!
Tests for `EspalJson`: the decoders for `Int32` and `Small` refuse values just past each bound,
text parsed by lean-json decodes to the values Espal wrote, and `LawfulJson` has no instance where
the round trip fails.
-/

open Json Espal

/-- Whether decoding `j` as `α` succeeds. -/
def decodes (α : Type) [FromJson α] (j : Json) : Bool :=
  (fromJson? j : Except String α).toOption.isSome

/-! `Int32` takes every integer in its range and refuses the next one out on each side. -/

#guard decodes Int32 (.num (Number.ofInt 2147483647))

#guard decodes Int32 (.num (Number.ofInt (-2147483648)))

#guard !decodes Int32 (.num (Number.ofInt 2147483648))

#guard !decodes Int32 (.num (Number.ofInt (-2147483649)))

#guard !decodes Int32 (.num ⟨15, -1⟩)

#guard !decodes Int32 (.str "5")

/-! `Small` takes `2^53 - 1` and refuses `2^53` and negative numbers. -/

#guard decodes Small (.num (Number.ofNat (2 ^ 53 - 1)))

#guard !decodes Small (.num (Number.ofNat (2 ^ 53)))

#guard !decodes Small (.num (Number.ofInt (-1)))

/-! Text that lean-json parses decodes to the value Espal wrote, and `compress` prints it back. -/

#guard
  (do
      let j ← (parse "[1,-7,2147483647]").toOption
      (fromJson? j : Except String (Array Int32)).toOption) ==
    some #[1, -7, 2147483647]

#guard
  (do
      let j ← (parse "[null,3]").toOption
      ((fromJson? j : Except String (List (Option Small))).toOption).map (·.map (·.map (·.val)))) ==
    some [none, some 3]

#guard compress (toJson (#[(⟨9, by decide⟩ : Small)], true)) == "[[9],true]"

/-! No `LawfulJson` instance where the round trip fails. `none` and `some none` share `null` in
`Option (Option α)`, and lean-json's `Nat` decoder refuses numbers with more than 1,000 trailing
zeros. -/

/--
error: failed to synthesize instance of type class
  LawfulJson (Option (Option Small))

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs in
example : LawfulJson (Option (Option Small)) :=
  inferInstance

/--
error: failed to synthesize instance of type class
  LawfulJson Nat

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs in
example : LawfulJson Nat :=
  inferInstance

/-- `none` and `some none` encode the same, which is why the instance above can't exist. -/
example : toJson (none : Option (Option Small)) = toJson (some (none : Option Small)) :=
  rfl
