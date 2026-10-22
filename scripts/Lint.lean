/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
import Lean
import LintRules

/-!
# Espal lint

Checks the compiled declarations of every module that a root imports from Espal's packages against
the code style rules in `CONTRIBUTING.md`, with the checks in `scripts/LintRules.lean`. The default
root, `Espal`, imports every package, and each package's modules start with `Espal`, such as
`EspalRoute`. The rules are these:

* no `unsafe` or `partial` declarations;
* no calls to panicking functions: `panic!` and any constant whose name ends in `!`;
* no `@[implemented_by]` or `@[extern]`, whose code Lean never checks, unless
  `uncheckedAllowed` lists the declaration;
* no axioms beyond `propext`, `Classical.choice` and `Quot.sound`, which rules out `sorry`.

It reads Lean's environment after `lake build`, so it sees code exactly as the compiler does.
Run with `lake lint`, or `lake exe lint [Root]` for another root.
-/

open Lean EspalLint

def main (args : List String) : IO UInt32 := do
  let root := (args.head?.map String.toName).getD `Espal
  initSearchPath (← findSysroot)
  let env ← importModules #[{ module := root }] {} 0
  let mut problems := 0
  for (n, ci) in env.constants.map₁.toList do
    let some idx := env.getModuleIdxFor? n | continue
    let some mod := env.header.moduleNames[idx.toNat]? | continue
    unless mod.getRoot.toString.startsWith root.getRoot.toString do
      continue
    for msg in check env n ci do
      IO.eprintln s!"{mod}: `{n}` {msg}"
      problems := problems + 1
  if problems == 0 then
    IO.println s!"espal lint: no problems in {root}"
    return 0
  IO.eprintln s!"espal lint: {problems} problem(s)"
  return 1
