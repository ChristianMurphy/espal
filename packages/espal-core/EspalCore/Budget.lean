/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Costs
public import EspalCore.Handler
public import EspalCore.ReadOnly
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
unfolded.

A loop over a list, written as `mapM` or as `for`, costs the bound on the list's length times the
most one pass can send. The walk finds that bound in three places: a `.take n`, a `List.range` over
a `Clamp` value, and a proof such as `small : items.length ≤ n`, in scope or as a field of the
structure that holds the list. A loop over any other list is an error.

The option `espal.statementLimit` is the limit an `api` table applies to a row that states none.

The same walk proves `ReadOnly` for a handler behind a `GET` row, as the theorem `h.readOnly`. It
fails at a `statement`, and a loop needs no bound for it.
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

/-- What the walk proves about a program. -/
meta inductive Claim where
  /-- `Costs`, with the most statements the program can send. -/
  | costs
  /-- `ReadOnly`, that the program never asks for `statement`. -/
  | reads
  deriving BEq

/-- The statement the walk proves about `program`. The bound matters only for `Claim.costs`. -/
meta def Claim.type (claim : Claim) (layer : Layer) (program : Expr) (bound : Nat) : MetaM Expr :=
  match claim with
  | .costs => costsType layer program (mkNatLit bound)
  | .reads => do
    mkAppM ``Espal.ReadOnly #[← underlying layer program]

/-- The name of the theorem that states a claim about a whole handler. -/
meta def Claim.suffix : Claim → Name
  | .costs => `budget
  | .reads => `readOnly

/-- The lemma for one way to build a program, such as `bind`, at this claim and layer. -/
meta def Claim.lemma (claim : Claim) (layer : Layer) (step : String) : Name :=
  let stem :=
    match claim, layer with
    | .costs, .eff => "costs_"
    | .costs, .failing => "costsT_"
    | .reads, .eff => "readOnly_"
    | .reads, .failing => "readOnlyT_"
  `Espal ++ Name.mkSimple (stem ++ step)

/-- The implicit numbers a `Costs` lemma takes before its proofs, which a `ReadOnly` lemma lacks. -/
meta def Claim.numbers (claim : Claim) (count : Nat) : Array (Option Expr) :=
  match claim with
  | .costs => Array.replicate count none
  | .reads => #[]

/-- Raises a proved bound to `bound`, which a `ReadOnly` proof doesn't need. -/
meta def Claim.raise (claim : Claim) (proof : Expr) (fits : Expr) : MetaM Expr :=
  match claim with
  | .costs => mkAppOptM ``Espal.Costs.mono #[none, none, none, none, none, proof, fits]
  | .reads => pure proof

/-- The budget that `declName.budget` states, if the theorem exists. -/
meta def stated? (declName : Name) (claim : Claim := .costs) : MetaM (Option Nat) := do
  let some proved := (← getEnv).find? (declName ++ claim.suffix)
    | return none
  if claim == .reads then
    return some 0
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
  throwError m!"it can't follow{indentExpr program}"

/-- The number that `n` is, if it is a numeral. -/
meta def numeral? (n : Expr) : MetaM (Option Nat) := do
  let n ← instantiateMVars n
  return n.nat?.orElse fun _ => n.rawNatLit?

/-- A number that `n` can't exceed, with a proof of `n ≤ bound`. A numeral bounds itself, and the
value of a `Clamp lo hi` is bounded by `hi`. -/
meta def natBound? (n : Expr) : MetaM (Option (Nat × Expr)) := do
  let n := (← instantiateMVars n).consumeMData
  if let some value← numeral? n then
    return some (value, ← mkAppM ``Nat.le_refl #[n])
  if n.isAppOf ``Espal.Clamp.val then
    let some clamp := n.getAppArgs.back?
      | return none
    let clampType ← whnfR (← inferType clamp)
    let some high := clampType.getAppArgs[1]?
      | return none
    let some limit ← numeral? high | return none
    return some (limit, ← mkAppM ``Espal.Clamp.le #[clamp])
  return none

/-- A proof that the list `xs` is no longer than some number. It comes from a hypothesis in scope,
or from a proof field of the structure that holds `xs`. -/
meta def statedLength? (xs : Expr) : MetaM (Option (Nat × Expr)) := do
  let fits (proof : Expr) : MetaM (Option (Nat × Expr)) := do
    let type ← instantiateMVars (← inferType proof)
    let_expr LE.le _ _ left right := type
      | return none
    let_expr List.length _ list := left
      | return none
    let some limit ← numeral? right | return none
    if ← isDefEq list xs then
      return some (limit, proof)
    return none
  for decl in ← getLCtx do
    if decl.isImplementationDetail then
      continue
    if let some found← fits decl.toExpr then
      return some found
  -- `xs` as a field `s.items` of a structure value `s`, whose other fields may bound it.
  let fn := xs.getAppFn
  let some fieldFn := fn.constName?
    | return none
  let some info := (← getEnv).getProjectionFnInfo? fieldFn
    | return none
  let some owner := xs.getAppArgs[info.numParams]?
    | return none
  let .ctorInfo ctor := (← getEnv).find? info.ctorName |>.getD default
    | return none
  for field in getStructureFields (← getEnv) ctor.induct do
    let proof ←
      try
        mkProjection owner field
      catch _ =>
        continue
    if let some found← fits proof then
      return some found
  return none

/-- A number that the length of the list `xs` can't exceed, with a proof of
`xs.length ≤ bound`. `none` when nothing bounds it. -/
meta def lengthBound? (xs : Expr) : (fuel : Nat) → MetaM (Option (Nat × Expr))
  | 0 => return none
  | fuel + 1 => do
    let xs := (← instantiateMVars xs).consumeMData
    if let some found← statedLength? xs then
      return some found
    match_expr xs with
    | List.take _ count list =>
      let some limit ← numeral? count | return none
      return some (limit, ← mkAppM ``List.length_take_le #[count, list])
    | List.range count =>
      let some (limit, fits) ← natBound? count | return none
      return some (limit, ← mkAppM ``Espal.length_range_le #[fits])
    | List.map _ _ f list =>
      let some (limit, fits) ← lengthBound? list fuel | return none
      return some (limit, ← mkAppM ``Espal.length_map_le #[f, fits])
    | _ =>
      return none

/-- Stops the walk at a loop whose list has no bound. -/
meta def unbounded {α : Type} (xs : Expr) : MetaM α :=
  throwError m!"the loop over{indentExpr xs}\nhas no bound on its length. Take at most `n` \
    items with `.take n`, count with a `Clamp`, or give the input a proof field such as \
    `small : items.length ≤ n`."

/-- The most statements `program` can send, with a proof of `Costs (underlying program) bound`.
With `Claim.reads` the proof is of `ReadOnly (underlying program)`, and the number is zero.
`self?` is the handler being walked, whose own theorem must not be used. `fuel` bounds how many
definitions the walk unfolds in a row. -/
meta def walk (claim : Claim) (self? : Option Name) (program : Expr) :
    (fuel : Nat) → MetaM (Nat × Expr)
  | 0 => lost program
  | fuel + 1 => do
    let program := (← instantiateMVars program).headBeta.consumeMData
    if let .letE _ _ value body _ := program then
      return ← walk claim self? (body.instantiate1 value) fuel
    let programType ← whnfR (← inferType program)
    let some layer ← layerOf? programType | lost program
    -- The error type of a failing program, which the lemmas about one can't infer.
    let errorType := programType.getAppArgs[0]?
    let known (proof : Expr) (bound : Nat) : MetaM (Nat × Expr) := do
      return (bound, ← mkExpectedTypeHint proof (← claim.type layer program bound))
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
      match claim, layer with
      | .costs, .eff =>
        known (← mkAppM ``Espal.costs_pure #[a, mkNatLit 0]) 0
      | .reads, .eff =>
        known (← mkAppM ``Espal.readOnly_pure #[a]) 0
      | _, .failing =>
        known (← mkAppOptM (claim.lemma layer "pure") #[errorType, none, a]) 0
    | some ``Bind.bind, #[_, _, _, _, x, k] =>
      let (m, hx) ← walk claim self? x fuel
      let (j, hk) ← under k fun body => walk claim self? body fuel
      return (m + j, ← mkAppM (claim.lemma layer "bind") #[x, k, hx, hk])
    | some ``List.mapM, #[_, _, _, _, f, xs] =>
      -- A loop costs the bound on its list's length times the most one pass can send.
      let (j, hf) ← under f fun body => walk claim self? body fuel
      let looped ← mkAppM (claim.lemma layer "mapM") #[f, xs, hf]
      if claim == .reads then
        return ← known looped 0
      let some (limit, fits) ← lengthBound? xs 16 | unbounded xs
      let widened ← mkAppM ``Nat.mul_le_mul_right #[mkNatLit j, fits]
      known (← mkAppOptM ``Espal.Costs.mono #[none, none, none, none, none, looped, widened])
          (limit * j)
    | some ``ForIn.forIn, #[_, _, _, _, _, xs, init, f] =>
      unless (← whnfR (← inferType xs)).isAppOf ``List do
        lost program
      let (j, hf) ←
        under f fun partial_ => do
            let some (.forallE name domain _ _) := some (← whnf (← inferType partial_))
              | lost program
            withLocalDeclD name domain fun state => do
                let (bound, proof) ← walk claim self? (mkApp partial_ state).headBeta fuel
                return (bound, ← mkLambdaFVars #[state] proof)
      let looped ← mkAppM (claim.lemma layer "forIn") #[xs, init, f, hf]
      if claim == .reads then
        return ← known looped 0
      let some (limit, fits) ← lengthBound? xs 16 | unbounded xs
      let widened ← mkAppM ``Nat.mul_le_mul_right #[mkNatLit j, fits]
      known (← mkAppOptM ``Espal.Costs.mono #[none, none, none, none, none, looped, widened])
          (limit * j)
    | some ``Functor.map, #[_, _, _, _, f, x] =>
      let (m, hx) ← walk claim self? x fuel
      return (m, ← mkAppM (claim.lemma layer "map") #[f, x, hx])
    | some ``ite, #[_, c, inst, t, e] =>
      let (a, ht) ← walk claim self? t fuel
      let (b, he) ← walk claim self? e fuel
      let implicit : Array (Option Expr) := if layer == .eff then #[none] else #[none, none]
      return (max a b,
          ←
            mkAppOptM (claim.lemma layer "ite")
                (implicit ++ #[some c, some inst, some t, some e] ++ claim.numbers 2 ++
                  #[some ht, some he]))
    | some ``dite, #[_, c, inst, t, e] =>
      let (a, ht) ← under t fun body => walk claim self? body fuel
      let (b, he) ← under e fun body => walk claim self? body fuel
      let implicit : Array (Option Expr) := if layer == .eff then #[none] else #[none, none]
      return (max a b,
          ←
            mkAppOptM (claim.lemma layer "dite")
                (implicit ++ #[some c, some inst, some t, some e] ++ claim.numbers 2 ++
                  #[some ht, some he]))
    | some name, _ =>
      if name == ``Espal.now && args.isEmpty then
        return ← known (mkConst (claim.lemma .eff "now")) 0
      if name == ``Espal.random && args.size == 2 then
        return ← known (← mkAppM (claim.lemma .eff "random") args) 0
      if name == ``Espal.log && args.size == 1 then
        return ← known (← mkAppM (claim.lemma .eff "log") args) 0
      if name == ``Espal.query && args.size == 1 then
        return ← known (← mkAppM (claim.lemma .eff "query") args) (if claim == .costs then 1 else 0)
      if name == ``Espal.statement && args.size == 1 then
        if claim == .reads then
          throwError m!"it sends{indentExpr program}\nwhich may write"
        return ← known (← mkAppM ``Espal.costs_statement args) 1
      if layer == .failing && throwNames.contains name then
        let some e := args.back?
          | lost program
        return ←
            known
                (←
                  mkAppOptM (claim.lemma .failing "throw")
                      #[errorType, programType.getAppArgs[2]?, e])
                0
      if layer == .failing && liftNames.contains name then
        let some y := args.back?
          | lost program
        let (m, hy) ← walk claim self? y fuel
        let proof ←
          mkAppOptM (claim.lemma .failing "lift")
              (#[errorType, none, some y] ++ claim.numbers 1 ++ #[some hy])
        return ← known proof m
      if some name != self? then
        if let some bound← stated? name claim then
          let levels :=
            match fn with
            | .const _ levels => levels
            | _ => []
          let proof := mkAppN (mkConst (name ++ claim.suffix) levels) args
          return ← known proof bound
      if let some matcher← matchMatcherApp? program then
        -- A `match` costs the dearest of its alternatives. The proof splits the match and closes
        -- each case with the walk of that alternative.
        let mut bound := 0
        for alt in matcher.alts do
          let (cost, _) ← lambdaTelescope alt fun _ body => walk claim self? body fuel
          bound := max bound cost
        let goal ← mkFreshExprSyntheticOpaqueMVar (← claim.type layer program bound)
        let .mvar goalId := goal
          | lost program
        let cases ←
          try
            (Tactic.run goalId (Tactic.evalTactic (← `(tactic| split)))).run'
          catch _ =>
            throwError m!"Lean can't split{indentExpr program}\nThat happens for an array pattern \
              such as `#[a]`. Read the cell with `row[0]?` and match on what it gives."
        for case in cases do
          case.withContext do
              let caseType ← instantiateMVars (← case.getType)
              let some caseProgram := caseType.getAppArgs[2]?
                | lost program
              let inner :=
                if caseProgram.isAppOf ``ExceptT.run then
                  caseProgram.getAppArgs.back?.getD caseProgram
                else caseProgram
              let (cost, proof) ← walk claim self? inner fuel
              let fits ← mkDecideProof (← mkAppM ``LE.le #[mkNatLit cost, mkNatLit bound])
              case.assign (← claim.raise proof fits)
        return (bound, ← instantiateMVars goal)
      let some unfolded ← unfoldDefinition? program | lost program
      -- A failure inside another definition is reported at the call, as the handler wrote it.
      let (bound, proof) ←
        if some name == self? then
          walk claim self? unfolded fuel
        else
          try
            walk claim self? unfolded fuel
          catch error =>
            if claim == .reads then
              throw error
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
          walk .costs (some declName) call walkFuel
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

/-- Makes sure the handler `declName` only reads, when its result is a program. It uses the
handler's `readOnly` theorem if there is one, and proves one otherwise. A `GET` row calls this. -/
meta def ensureReads (declName : Name) : MetaM Unit := do
  let info ← getConstInfo declName
  if ((← getEnv).find? (declName ++ `readOnly)).isSome then
    return
  let proved ←
    forallTelescope info.type fun xs result => do
        let some layer ← layerOf? result | return none
        let call := mkAppN (mkConst declName (info.levelParams.map mkLevelParam)) xs
        let (_, proof) ←
          try
            walk .reads (some declName) call walkFuel
          catch error =>
            throwError m!"`{privateToUserName declName}` answers a `GET` request, which must leave \
            the database as it was, and {error.toMessageData}.\nRead with `query`, or give the \
            route another method."
        let type ← mkForallFVars xs (← Claim.reads.type layer call 0)
        let value ← mkLambdaFVars xs proof
        return some (← instantiateMVars type, ← instantiateMVars value)
  let some (type, value) := proved
    | return
  addDecl (.thmDecl { name := declName ++ `readOnly, levelParams := info.levelParams, type, value })

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
      let (bound, proof) ← walk .costs none inner walkFuel
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
