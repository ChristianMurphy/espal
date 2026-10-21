/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import Lean

/-!
# Espal lint rules

The checks behind `scripts/Lint.lean`, kept in a library so that tests can run them on fixtures.
-/

open Lean

namespace EspalLint

/-- Axioms the standard library relies on; anything else, including `sorryAx`, is rejected. -/
public def allowedAxioms : NameSet :=
  .ofList [``propext, ``Classical.choice, ``Quot.sound]

/-- Functions that panic at run time. -/
public def panicking : NameSet :=
  .ofList [``panic, ``panicCore, ``panicWithPos, ``panicWithPosWithDecl]

/-- Whether calling `n` can panic: a panic function, or a `!` variant such as `getElem!`. -/
public def isPanicking (n : Name) : Bool :=
  panicking.contains n ||
    match n with
    | .str _ s => s.endsWith "!"
    | _ => false

/-- The axioms `n` depends on, found by walking the constants its type and value mention. -/
public partial def axiomsOf (env : Environment) (n : Name) : StateM NameSet NameSet := do
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
public def isUserPartial (env : Environment) (n : Name) (ci : ConstantInfo) : Bool :=
  ci.isPartial &&
    match n with
    | .str base s =>
      if s == "_unsafe_rec" then
        match env.find? base with
        | some (.opaqueInfo _) => true
        | _ => false
      else true
    | _ => true

/--
Whether `n` is the `unsafe` code that Lean 4.36 attaches to `I.ctorIdx` with `@[implemented_by]`,
for an inductive type `I` with more than one constructor. It reads the tag with the runtime's
`getObjTagNat`. The lint skips it and checks `I.ctorIdx`, which defines the same function.
-/
public def isGeneratedCtorIdx (env : Environment) (n : Name) : Bool :=
  match n with
  | .str base@(.str ind "ctorIdx") "_impl" =>
    (env.find? ind matches some (.inductInfo _)) &&
      Compiler.implementedByAttr.getParam? env base == some n
  | _ => false

/--
Declarations allowed to run code that Lean never checks, through `@[implemented_by]` or
`@[extern]`. Add one only with a test that compares its code with the definition it replaces.
-/
public def uncheckedAllowed : NameSet :=
  {}

/-- Problems with one declaration, as human-readable messages. -/
public def check (env : Environment) (n : Name) (ci : ConstantInfo) : Array String :=
  Id.run do
    if isGeneratedCtorIdx env n then
      return #[]
    let mut out := #[]
    if ci.isUnsafe then
      out := out.push "is `unsafe`"
    if isUserPartial env n ci then
      out := out.push "is `partial`"
    unless uncheckedAllowed.contains n do
      if let some impl := Compiler.implementedByAttr.getParam? env n then
        unless isGeneratedCtorIdx env impl do
          out := out.push s!"runs `{impl}` through `@[implemented_by]`, which Lean never checks"
      if isExtern env n then
        out := out.push "runs native code through `@[extern]`, which Lean never checks"
    let used := (ci.value? (allowOpaque := true)).elim #[] (·.getUsedConstants)
    for c in used do
      if isPanicking c then
        out := out.push s!"calls `{c}`, which can panic"
    let (axs, _) := (axiomsOf env n).run {}
    for a in axs do
      unless allowedAxioms.contains a do
        out := out.push s!"depends on axiom `{a}`"
    return out

end EspalLint
