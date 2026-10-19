module

meta import Lean
meta import LintRules

/-! Tests for the checks in `scripts/LintRules.lean`, run on the fixtures below. -/

namespace EspalTests.LintFixture

/-- Two constructors, so Lean 4.36 gives `Choice.ctorIdx` an `unsafe` implementation. -/
public inductive Choice where
  | yes
  | no

/-- Has the name of a generated implementation without being one. -/
public def plain : Nat :=
  0

public unsafe def plain.ctorIdx._impl : Nat :=
  0

public unsafe def unsafeValue : Nat :=
  0

end EspalTests.LintFixture

open Lean

/-- The fixtures to check. `Choice.ctorIdx._impl` exists only from Lean 4.36 on. -/
meta def fixtures : List Name :=
  [`Choice, `Choice.ctorIdx, `Choice.ctorIdx._impl, `plain, `plain.ctorIdx._impl, `unsafeValue]

/-- Logs what the lint reports on each fixture that exists, one line per problem. -/
meta def report : MetaM Unit := do
  let env ← getEnv
  let mut found : Array String := #[]
  for n in fixtures.map (`EspalTests.LintFixture ++ ·) do
    if let some ci := env.find? n then
      for msg in EspalLint.check env n ci do
        found := found.push s!"{n} {msg}"
  logInfo (String.intercalate "\n" found.toList)

/--
info: EspalTests.LintFixture.plain.ctorIdx._impl is `unsafe`
EspalTests.LintFixture.unsafeValue is `unsafe`
-/
#guard_msgs in
#eval report
