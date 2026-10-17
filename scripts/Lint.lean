/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
import Lean

/-!
# Espal lint

Checks the compiled declarations of every module under a root (default `Espal`) against the code
style rules in `CONTRIBUTING.md`:

* no `unsafe` or `partial` declarations;
* no calls to panicking functions: `panic!` and any constant whose name ends in `!`;
* no axioms beyond `propext`, `Classical.choice` and `Quot.sound`, which rules out `sorry`.

It reads Lean's environment after `lake build`, so it sees code exactly as the compiler does.
Run with `lake env lean --run scripts/Lint.lean [Root]`.
-/

open Lean

/-- Axioms the standard library relies on; anything else, including `sorryAx`, is rejected. -/
def allowedAxioms : NameSet :=
  .ofList [``propext, ``Classical.choice, ``Quot.sound]

/-- Functions that panic at run time. -/
def panicking : NameSet :=
  .ofList [``panic, ``panicCore, ``panicWithPos, ``panicWithPosWithDecl]

/-- Whether calling `n` can panic: a panic function, or a `!` variant such as `getElem!`. -/
def isPanicking (n : Name) : Bool :=
  panicking.contains n ||
    match n with
    | .str _ s => s.endsWith "!"
    | _ => false

/-- The axioms `n` depends on, found by walking the constants its type and value mention. -/
partial def axiomsOf (env : Environment) (n : Name) : StateM NameSet NameSet := do
  if (← get).contains n then
    return {}
  modify (·.insert n)
  let some ci := env.find? n | return {}
  if ci matches .axiomInfo _ then
    return NameSet.empty.insert n
  let mut out := {}
  for c in
    ci.type.getUsedConstants ++ (ci.value? (allowOpaque := true)).elim #[] (·.getUsedConstants) do
    for a in ← axiomsOf env c do
      out := out.insert a
  return out

/--
Whether `n` is the code of a `partial def`. Lean also compiles well-founded recursion through a
`_unsafe_rec` helper marked partial; only a `partial def` leaves the user-facing constant opaque.
-/
def isUserPartial (env : Environment) (n : Name) (ci : ConstantInfo) : Bool :=
  ci.isPartial &&
    match n with
    | .str base s =>
      if s == "_unsafe_rec" then
        match env.find? base with
        | some (.opaqueInfo _) => true
        | _ => false
      else true
    | _ => true

/-- Problems with one declaration, as human-readable messages. -/
def check (env : Environment) (n : Name) (ci : ConstantInfo) : Array String :=
  Id.run do
    let mut out := #[]
    if ci.isUnsafe then
      out := out.push "is `unsafe`"
    if isUserPartial env n ci then
      out := out.push "is `partial`"
    let used := (ci.value? (allowOpaque := true)).elim #[] (·.getUsedConstants)
    for c in used do
      if isPanicking c then
        out := out.push s!"calls `{c}`, which can panic"
    let (axs, _) := (axiomsOf env n).run {}
    for a in axs do
      unless allowedAxioms.contains a do
        out := out.push s!"depends on axiom `{a}`"
    return out

def main (args : List String) : IO UInt32 := do
  let root := (args.head?.map String.toName).getD `Espal
  initSearchPath (← findSysroot)
  let env ← importModules #[{ module := root }] {} 0
  let mut problems := 0
  for (n, ci) in env.constants.map₁.toList do
    let some idx := env.getModuleIdxFor? n | continue
    let some mod := env.header.moduleNames[idx.toNat]? | continue
    unless root.isPrefixOf mod do
      continue
    for msg in check env n ci do
      IO.eprintln s!"{mod}: `{n}` {msg}"
      problems := problems + 1
  if problems == 0 then
    IO.println s!"espal lint: no problems in {root}"
    return 0
  IO.eprintln s!"espal lint: {problems} problem(s)"
  return 1
