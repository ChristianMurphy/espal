/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Costs
public import EspalCore.Handler
public meta import Lean.Elab.Command
public meta import Lean.Elab.Tactic

/-!
# The `@[budget n]` attribute

`@[budget n]` on a handler states that it sends at most `n` database statements, and proves it
where the handler is defined. For a handler `h` it declares the theorem `h.budget`, which says
`Costs (h args…) n` for all arguments. A handler that returns `Fails ε α` gets the theorem about
the `Eff` program under it.

The proof is the `budget` tactic. When the handler can send more than `n` statements, the error
shows the statement that the budget couldn't pay for.
-/

public section

namespace Espal

/-- `@[budget n]` proves that a handler sends at most `n` database statements, and declares the
theorem `h.budget` for the handler `h`. -/
syntax (name := budgetAttr) &"budget " num : attr

namespace Budget

open Lean Elab Term Meta

/-- The program whose statements a handler's result sends: the result itself for an `Eff`, and
the program under it for an `ExceptT` over `Eff`. `none` for any other result type. -/
meta def programOf (value type : Expr) : MetaM (Option Expr) := do
  let type ← whnfR type
  if type.isAppOf ``Espal.Eff then
    return some value
  if type.isAppOf ``ExceptT then
    return some (← mkAppM ``ExceptT.run #[value])
  return none

/-- Declares `declName.budget`, the proof that `declName` sends at most `n` statements. -/
meta def prove (declName : Name) (n : Nat) : TermElabM Unit := do
  let info ← getConstInfo declName
  let shown := privateToUserName declName
  let thmName := declName ++ `budget
  let (type, value) ←
    forallTelescope info.type fun xs result => do
        let call := mkAppN (mkConst declName (info.levelParams.map mkLevelParam)) xs
        let some program ← programOf call result |
          throwError m!"`@[budget {n}]` is for a handler that returns `Handler α` or \
            `Fails ε α`, and `{shown}` returns `{result}`."
        let goalType ← mkAppM ``Espal.Costs #[program, mkNatLit n]
        let goal ← mkFreshExprSyntheticOpaqueMVar goalType
        let .mvar goalId := goal
          | throwError m!"`{shown}`: the budget goal isn't a metavariable."
        let remaining ←
          Tactic.run goalId do
              Tactic.evalTactic (← `(tactic| unfold $(mkCIdent declName):ident))
              Tactic.evalTactic (← `(tactic| budget))
        if let some left := remaining.head? then
          let stuck ←
            left.withContext do
                let leftType ← instantiateMVars (← left.getType)
                pure (indentExpr (leftType.getAppArgs.getD 2 leftType))
          throwError m!"`{shown}` may send more than {n} database \
          {if n == 1 then "statement" else "statements"}. The budget ran out at:{stuck}"
        let proof ← instantiateMVars goal
        return (← mkForallFVars xs goalType, ← mkLambdaFVars xs proof)
  addDecl
      (.thmDecl
        { name := thmName, levelParams := info.levelParams, type := ← instantiateMVars type
          value := ← instantiateMVars value })

/-- The default limit on the database statements one request sends. -/
def defaultLimit : Nat :=
  10

/-- Makes sure the handler `declName` has a proved budget within `limit`, when its result is a
program. It uses the handler's `@[budget n]` theorem if there is one, and proves the budget at
`limit` otherwise. A handler with a plain result sends nothing and needs no proof. -/
meta def ensure (declName : Name) (limit : Nat) : TermElabM Unit := do
  let info ← getConstInfo declName
  let isProgram ←
    forallTelescope info.type fun xs result => do
        let call := mkAppN (mkConst declName (info.levelParams.map mkLevelParam)) xs
        return (← programOf call result).isSome
  unless isProgram do
    return
  let shown := privateToUserName declName
  match (← getEnv).find? (declName ++ `budget) with
  | some proved =>
    let stated ←
      forallTelescope proved.type fun _ body => do
          return (← instantiateMVars body).getAppArgs.back?.bind (·.rawNatLit?) |>.orElse fun _ =>
              body.getAppArgs.back?.bind (·.nat?)
    match stated with
    | some n =>
      unless n ≤ limit do
        throwError m!"`{shown}` has `@[budget {n}]`, and a route may send at most {limit} \
          database statements."
    | none =>
      throwError m!"`{shown}.budget` doesn't state a budget."
  | none =>
    prove declName limit

-- A parametric attribute would swallow an error from its hook, so this one is registered directly.
meta initialize
  registerBuiltinAttribute
      { name := `budgetAttr
        descr := "the most database statements a handler sends, proved where it is defined"
        applicationTime := .afterTypeChecking
        add := fun declName stx _ => do
          let n ←
            match stx with
            | `(attr| budget $n:num) =>
              pure n.getNat
            | _ =>
              throwError "expected `budget n`, with `n` a number of statements"
          (prove declName n).run' {} |>.run' {} }

end Budget

end Espal
