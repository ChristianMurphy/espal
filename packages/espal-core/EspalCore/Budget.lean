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
# The `@[budget]` attribute

`@[budget]` on a handler proves, where the handler is defined, how many database statements it
can send. It walks the handler once and finds the worst case over every path. For a handler `h`
it declares the theorem `h.budget`, which says `Costs (h args…) n` for all arguments. A handler
that returns `Fails ε α` gets the theorem about the `Eff` program under it.

`@[budget n]` pins the number. The handler must fit it, and the theorem states `n`. An edit that
makes the handler send more then fails where the handler is defined.

The walk follows sequences, `if`, `match`, `throw` and effects. A call to a handler or helper
that has a `budget` theorem costs what that theorem states, and a call to any other definition is
unfolded. A loop over statements has no bound the walk can find.

The option `espal.statementLimit` is the limit an `api` table applies to a row that states none.
-/

public section

namespace Espal

/-- `@[budget]` proves how many database statements a handler can send, and declares the theorem
`h.budget` for the handler `h`. `@[budget n]` also requires that the handler fits `n`. -/
syntax (name := budgetAttr) &"budget" (ppSpace num)? : attr

/-- Proves a goal `Costs x n` by walking the program `x`, when `x` sends at most `n`. -/
syntax (name := budgetTactic) "budget" : tactic

namespace Budget

open Lean Elab Term Meta

/-- Whether a program's type is `Eff α`, an `ExceptT` over it, or neither. -/
meta inductive Layer where
  /-- An `Eff α`. -/
  | eff
  /-- An `ExceptT ε Eff α`. -/
  | failing
  deriving BEq

/-- The layer of a program of type `type`, if it is a program. -/
meta def layerOf? (type : Expr) : MetaM (Option Layer) := do
  let type ← whnfR type
  if type.isAppOf ``Espal.Eff then
    return some .eff
  if type.isAppOf ``ExceptT then
    return some .failing
  return none

/-- The `Eff` program whose statements `program` sends: itself, or what `ExceptT.run` gives. -/
meta def underlying (layer : Layer) (program : Expr) : MetaM Expr :=
  match layer with
  | .eff => pure program
  | .failing => mkAppM ``ExceptT.run #[program]

/-- The statement `Costs (underlying program) n`. -/
meta def costsType (layer : Layer) (program : Expr) (n : Expr) : MetaM Expr := do
  mkAppM ``Espal.Costs #[← underlying layer program, n]

/-- The budget that `declName.budget` states, if the theorem exists. -/
meta def stated? (declName : Name) : MetaM (Option Nat) := do
  let some proved := (← getEnv).find? (declName ++ `budget)
    | return none
  forallTelescope proved.type fun _ body => do
      let body ← instantiateMVars body
      return body.getAppArgs.back?.bind fun n => n.rawNatLit?.orElse fun _ => n.nat?

/-- The names under which `do` notation lifts an `Eff` program into `ExceptT`. -/
meta def liftNames : List Name :=
  [``liftM, ``monadLift, ``MonadLiftT.monadLift, ``MonadLift.monadLift, ``ExceptT.lift]

/-- The names under which `throw` appears. -/
meta def throwNames : List Name :=
  [``MonadExcept.throw, ``MonadExceptOf.throw, ``throwThe, ``throw]

/-- Stops the walk at a program it can't follow. -/
meta def lost {α : Type} (program : Expr) : MetaM α :=
  throwError m!"it can't follow{indentExpr program}\nA loop over statements needs a bound that \
    is proved by hand."

/-- The most statements `program` can send, with a proof of `Costs (underlying program) bound`.
`self?` is the handler being walked, whose own `budget` theorem must not be used. `fuel` bounds
how many definitions the walk unfolds in a row. -/
meta def walk (self? : Option Name) (program : Expr) : (fuel : Nat) → MetaM (Nat × Expr)
  | 0 => lost program
  | fuel + 1 => do
    let program := (← instantiateMVars program).headBeta.consumeMData
    if let .letE _ _ value body _ := program then
      return ← walk self? (body.instantiate1 value) fuel
    let programType ← whnfR (← inferType program)
    let some layer ← layerOf? programType | lost program
    -- The error type of a failing program, which the lemmas about one can't infer.
    let errorType := programType.getAppArgs[0]?
    let known (proof : Expr) (bound : Nat) : MetaM (Nat × Expr) := do
      return (bound, ← mkExpectedTypeHint proof (← costsType layer program (mkNatLit bound)))
    let fn := program.getAppFn
    let args := program.getAppArgs
    let under (k : Expr) (next : Expr → MetaM (Nat × Expr)) : MetaM (Nat × Expr) := do
      let some (.forallE name domain _ _) := some (← whnf (← inferType k))
        | lost program
      withLocalDeclD name domain fun a => do
          let (bound, proof) ← next (mkApp k a).headBeta
          return (bound, ← mkLambdaFVars #[a] proof)
    match fn.constName?, args with
    | some ``Pure.pure, #[_, _, _, a] =>
      match layer with
      | .eff =>
        known (← mkAppM ``Espal.costs_pure #[a, mkNatLit 0]) 0
      | .failing =>
        known (← mkAppOptM ``Espal.costsT_pure #[errorType, none, a]) 0
    | some ``Bind.bind, #[_, _, _, _, x, k] =>
      let (m, hx) ← walk self? x fuel
      let (j, hk) ← under k fun body => walk self? body fuel
      let lemma := if layer == .eff then ``Espal.costs_bind else ``Espal.costsT_bind
      return (m + j, ← mkAppM lemma #[x, k, hx, hk])
    | some ``Functor.map, #[_, _, _, _, f, x] =>
      let (m, hx) ← walk self? x fuel
      let lemma := if layer == .eff then ``Espal.costs_map else ``Espal.costsT_map
      return (m, ← mkAppM lemma #[f, x, hx])
    | some ``ite, #[_, c, inst, t, e] =>
      let (a, ht) ← walk self? t fuel
      let (b, he) ← walk self? e fuel
      let lemma := if layer == .eff then ``Espal.costs_ite else ``Espal.costsT_ite
      let implicit : Array (Option Expr) := if layer == .eff then #[none] else #[none, none]
      return (max a b,
          ←
            mkAppOptM lemma
                (implicit ++ #[some c, some inst, some t, some e, none, none, some ht, some he]))
    | some ``dite, #[_, c, inst, t, e] =>
      let (a, ht) ← under t fun body => walk self? body fuel
      let (b, he) ← under e fun body => walk self? body fuel
      let lemma := if layer == .eff then ``Espal.costs_dite else ``Espal.costsT_dite
      let implicit : Array (Option Expr) := if layer == .eff then #[none] else #[none, none]
      return (max a b,
          ←
            mkAppOptM lemma
                (implicit ++ #[some c, some inst, some t, some e, none, none, some ht, some he]))
    | some name, _ =>
      if name == ``Espal.now && args.isEmpty then
        return ← known (mkConst ``Espal.costs_now) 0
      if name == ``Espal.random && args.size == 2 then
        return ← known (← mkAppM ``Espal.costs_random args) 0
      if name == ``Espal.log && args.size == 1 then
        return ← known (← mkAppM ``Espal.costs_log args) 0
      if name == ``Espal.statement && args.size == 1 then
        return ← known (← mkAppM ``Espal.costs_statement args) 1
      if layer == .failing && throwNames.contains name then
        let some e := args.back?
          | lost program
        return ←
            known (← mkAppOptM ``Espal.costsT_throw #[errorType, programType.getAppArgs[2]?, e]) 0
      if layer == .failing && liftNames.contains name then
        let some y := args.back?
          | lost program
        let (m, hy) ← walk self? y fuel
        let proof ← mkAppOptM ``Espal.costsT_lift #[errorType, none, y, none, hy]
        return ← known proof m
      if some name != self? then
        if let some bound← stated? name then
          let levels :=
            match fn with
            | .const _ levels => levels
            | _ => []
          let proof := mkAppN (mkConst (name ++ `budget) levels) args
          return ← known proof bound
      if let some matcher← matchMatcherApp? program then
        -- A `match` costs the dearest of its alternatives. The proof splits the match and closes
        -- each case with the walk of that alternative.
        let mut bound := 0
        for alt in matcher.alts do
          let (cost, _) ← lambdaTelescope alt fun _ body => walk self? body fuel
          bound := max bound cost
        let goal ← mkFreshExprSyntheticOpaqueMVar (← costsType layer program (mkNatLit bound))
        let .mvar goalId := goal
          | lost program
        let cases ← (Tactic.run goalId (Tactic.evalTactic (← `(tactic| split)))).run'
        for case in cases do
          case.withContext do
              let caseType ← instantiateMVars (← case.getType)
              let some caseProgram := caseType.getAppArgs[2]?
                | lost program
              let inner :=
                if caseProgram.isAppOf ``ExceptT.run then
                  caseProgram.getAppArgs.back?.getD caseProgram
                else caseProgram
              let (cost, proof) ← walk self? inner fuel
              let fits ← mkDecideProof (← mkAppM ``LE.le #[mkNatLit cost, mkNatLit bound])
              case.assign
                  (← mkAppOptM ``Espal.Costs.mono #[none, none, none, none, none, proof, fits])
        return (bound, ← instantiateMVars goal)
      let some unfolded ← unfoldDefinition? program | lost program
      -- A failure inside another definition is reported at the call, as the handler wrote it.
      let (bound, proof) ←
        if some name == self? then
          walk self? unfolded fuel
        else
          try
            walk self? unfolded fuel
          catch _ =>
            lost program
      known proof bound
    | none, _ =>
      lost program

/-- How deep the walk goes into a handler before it gives up. -/
meta def walkFuel : Nat :=
  512

/-- A count of statements with its noun, such as `2 database statements`. -/
meta def statements (n : Nat) : String :=
  s!"{n} database {if n == 1 then "statement" else "statements"}"

/-- The most statements the handler `declName` can send, with the type and proof of its `budget`
theorem at `pinned?`, or at that number when nothing is pinned. `none` if the handler's result
isn't a program. -/
meta def measure (declName : Name) (pinned? : Option Nat) : MetaM (Option (Nat × Expr × Expr)) := do
  let info ← getConstInfo declName
  forallTelescope info.type fun xs result => do
      let some layer ← layerOf? result | return none
      let call := mkAppN (mkConst declName (info.levelParams.map mkLevelParam)) xs
      let (bound, proof) ←
        try
          walk (some declName) call walkFuel
        catch error =>
          throwError m!"`@[budget]` found no bound for `{privateToUserName declName}`, because \
          {error.toMessageData}"
      let stated := pinned?.getD bound
      if bound > stated then
        throwError m!"`{privateToUserName declName}` may send {statements bound}, and its budget \
        is {stated}."
      let fits ← mkDecideProof (← mkAppM ``LE.le #[mkNatLit bound, mkNatLit stated])
      let widened ← mkAppOptM ``Espal.Costs.mono #[none, none, none, none, none, proof, fits]
      let type ← mkForallFVars xs (← costsType layer call (mkNatLit stated))
      let value ← mkLambdaFVars xs widened
      return some (bound, ← instantiateMVars type, ← instantiateMVars value)

/-- Declares `declName.budget` and returns the budget it states. -/
meta def prove (declName : Name) (pinned? : Option Nat) : MetaM Nat := do
  let info ← getConstInfo declName
  let some (bound, type, value) ← measure declName pinned? |
    throwError m!"`@[budget]` is for a handler that returns `Handler α` or `Fails ε α`, and \
        `{privateToUserName declName}` returns `{← forallTelescope info.type fun _ r => pure r}`."
  addDecl (.thmDecl { name := declName ++ `budget, levelParams := info.levelParams, type, value })
  return pinned?.getD bound

/-- The limit on the database statements one request sends, for a table or row that states
none. Set it for an app in the lakefile's `leanOptions`, or for a file with `set_option`. -/
meta initialize statementLimit : Lean.Option Nat ←
  Option.register `espal.statementLimit
      { defValue := 10
        descr :=
          "the most database statements a request may send, unless its table or row says otherwise" }

/-- Makes sure the handler `declName` has a proved budget within `limit`, when its result is a
program. It uses the handler's `budget` theorem if there is one, and proves one otherwise. A
handler with a plain result sends nothing and needs no proof. -/
meta def ensure (declName : Name) (limit : Nat) : MetaM Unit := do
  let info ← getConstInfo declName
  let isProgram ← forallTelescope info.type fun _ result => return (← layerOf? result).isSome
  unless isProgram do
    return
  let budget ←
    match ← stated? declName with
    | some n =>
      pure n
    | none =>
      prove declName none
  unless budget ≤ limit do
    throwError m!"`{privateToUserName declName}` may send {statements budget}, and this route's \
      limit is {limit}.\nRaise the limit on the row with `limit {budget}`, or send fewer."

/-- The `budget` tactic. -/
@[tactic budgetTactic]
public meta def evalBudget : Tactic.Tactic := fun _ => do
  let goal ← Tactic.getMainGoal
  goal.withContext do
      let goalType ← instantiateMVars (← goal.getType)
      let args := goalType.getAppArgs
      let (some program, some wanted) := (args[2]?, args[3]?)
        | throwError "`budget` proves a goal of the form `Costs x n`."
      let inner :=
        if program.isAppOf ``ExceptT.run then program.getAppArgs.back?.getD program else program
      let (bound, proof) ← walk none inner walkFuel
      let some n := (← instantiateMVars wanted).nat?.orElse fun _ => wanted.rawNatLit?
        | throwError "`budget` needs the bound in the goal to be a number."
      if bound > n then
        throwError m!"the program may send {statements bound}, and the goal allows {n}."
      let fits ← mkDecideProof (← mkAppM ``LE.le #[mkNatLit bound, mkNatLit n])
      goal.assign (← mkAppOptM ``Espal.Costs.mono #[none, none, none, none, none, proof, fits])
      Tactic.replaceMainGoal []

-- A parametric attribute would swallow an error from its hook, so this one is registered directly.
meta initialize
  registerBuiltinAttribute
      { name := `budgetAttr
        descr := "the most database statements a handler sends, proved where it is defined"
        applicationTime := .afterTypeChecking
        add := fun declName stx _ => do
          let pinned? ←
            match stx with
            | `(attr| budget $n:num) =>
              pure (some n.getNat)
            | `(attr| budget) =>
              pure none
            | _ =>
              throwError "expected `budget` or `budget n`, with `n` a number of statements"
          discard <| (prove declName pinned?).run'
          -- Hovering the attribute shows the theorem it declared, with the proved bound.
          Elab.addConstInfo stx (declName ++ `budget) }

end Budget

end Espal
