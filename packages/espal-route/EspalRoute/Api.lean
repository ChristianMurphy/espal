/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Access
public import EspalRoute.Table
public meta import EspalRoute.Table
public meta import Lean.Elab.Command
public import Routing.Trie

/-!
# The `api` command

```lean
api Bench where
  GET "/plaintext"  => plaintext
  GET "/users/:id"  => showUser
```

declares `Bench : Api α`, a lean-routing table whose links reach their routes. Each row gives a
method, a path and a handler. The handler's signature gives the rest. Its first argument is the
access value. The path capture with the same name fills each later argument, which must be a `Nat`
or a `String`. Every handler in a table returns the same type `α`.

For each handler `h`, the command also declares `pathTo h` and a theorem `Bench.pathTo_h`.
`pathTo h` builds the decoded path of a link to `h` from `h`'s arguments. The theorem shows that
`matchTable` sends that path to `h` with those arguments. The command fails to compile when a route would
catch a link built for a later route with the same method.
-/

@[expose] public section

namespace Espal

open Routing Espal.Route

/-- A route table whose links reach their routes. The `api` command builds one. -/
structure Api (α : Type) where
  /-- The routes, tried in order. -/
  routes : List (Route α)
  /-- No route accepts a link built for a later route with the same method. -/
  links_disjoint : linksDisjoint routes = true

/-- Every link to a route in `api` reaches that route, with the arguments it was built from. -/
theorem Api.matchTable_pathOf {α : Type} (t : Api α) (i : Fin t.routes.length)
    (args : Args t.routes[i].segs) (hl : Linkable t.routes[i].segs args) :
    matchTable t.routes t.routes[i].method (pathOf t.routes[i].segs args) =
      some
        (⟨t.routes[i].method, t.routes[i].segs⟩,
          applyHandler t.routes[i].segs t.routes[i].handler args) :=
  Espal.Route.matchTable_pathOf t.links_disjoint i args hl

/-- `t` with `f` applied to each handler's result. Mapping keeps each route's method and pattern, so
`t`'s proof carries over. -/
def Api.map {α β : Type} (f : α → β) (t : Api α) : Api β where
  routes := t.routes.map (mapRoute f)
  links_disjoint := (linksDisjoint_map f t.routes).trans t.links_disjoint

/-- lean-routing's route index over `t`'s routes. `t`'s own proof shows that no route is shadowed,
so building it checks nothing again. -/
def Api.index {α : Type} (t : Api α) : RouteIndex α :=
  RouteIndex.of t.routes (unshadowed_of_linksDisjoint t.links_disjoint)

/-- The decoded path of a link to `handler`, as a function of the handler's arguments after the
access value. The `api` command declares an instance for each handler in its table. -/
class PathTo {τ : Type} (handler : τ) (Path : outParam Type) where
  /-- The path, as a function of the handler's arguments. -/
  pathTo : Path

/-- The decoded path of a link to `handler`, as a function of the handler's arguments after the
access value. -/
def pathTo {τ : Type} (handler : τ) {Path : Type} [PathTo handler Path] : Path :=
  PathTo.pathTo handler

end Espal

namespace Espal.ApiCommand

open Lean Elab Command Meta Routing Espal.Route

/-- One row of an `api` table, with a method, a path and a handler. -/
syntax apiRoute := ident ppSpace str " => " ident

/-- Declares an `Espal.Api` from rows of `METHOD "/path/:capture" => handler`. See the module
docstring. -/
syntax (name := apiCmd) "api " ident " where" many1Indent(ppLine apiRoute) : command

/-- The methods a row can name, with their `Std.Http.Method` constructors. -/
private meta def methods : List (String × Name) :=
  [("GET", ``Std.Http.Method.get), ("HEAD", ``Std.Http.Method.head),
    ("POST", ``Std.Http.Method.post), ("PUT", ``Std.Http.Method.put),
    ("PATCH", ``Std.Http.Method.patch), ("DELETE", ``Std.Http.Method.delete),
    ("OPTIONS", ``Std.Http.Method.options)]

/-- A path segment before the handler's signature gives each capture its kind. -/
private meta inductive RawSeg where
  | lit (seg : PathSeg)
  | capture (name : String)

/-- The segments of `path`, or the reason it isn't a path an `api` row accepts. -/
private meta def parsePath (path : String) : Except String (List RawSeg) := do
  unless path.startsWith "/" do
    throw s!"path `{path}` must start with `/`."
  if path == "/" then
    return []
  let mut segs : Array RawSeg := #[]
  let mut names : Array String := #[]
  for part in (path.drop 1).toString.splitOn "/" do
    if part.isEmpty then
      throw s!"path `{path}` has an empty segment."
    if part.startsWith ":" then
      let name := (part.drop 1).toString
      if name.isEmpty then
        throw s!"path `{path}` has a capture with no name."
      if names.contains name then
        throw s!"path `{path}` captures `{name}` twice."
      names := names.push name
      segs := segs.push (.capture name)
    else if h : dotSegment part = false then
      segs := segs.push (.lit (.lit part h))
    else
      throw s!"path `{path}` has the segment `{part}`, which a client removes before sending."
  return segs.toList

/-- What the `api` command needs from one row, once its handler's signature is read. -/
private meta structure Row where
  ref : Syntax
  methodText : String
  method : Name
  path : String
  handler : Name
  /-- The segments, with each capture's kind taken from the handler. -/
  segs : List PathSeg
  /-- The handler's arguments after the access value, in order, with their kinds. -/
  args : List (Name × CaptureKind)

/-- The last component of `n`, which names the declarations generated for it. -/
private meta def lastComponent (n : Name) : String :=
  match n.eraseMacroScopes with
  | .str _ s => s
  | other => other.toString

/-- How a row appears in an error message. -/
private meta def Row.display (r : Row) : String :=
  s!"`{r.methodText} {r.path}` (handler `{privateToUserName r.handler}`)"

/-- `seg` with its kind, once the handler's arguments are known. -/
private meta def resolveSeg (handler : Name) (path : String) (args : List (Name × CaptureKind)) :
    RawSeg → Except String PathSeg
  | .lit seg => .ok seg
  | .capture name =>
    match args.find? (·.1 == Name.mkSimple name) with
    | some (_, kind) => .ok (.capture name kind)
    | none =>
      .error
        s!"path `{path}` captures `{name}`, but handler \
      `{privateToUserName handler}` has no argument named `{name}`."

/-- Reads the handler's signature: checks the access value and returns each later argument's
name and kind, and the result type. -/
private meta def readHandler (handler : Name) (captures : List String) (path : String) :
    TermElabM (List (Name × CaptureKind) × Expr) := do
  let shown := privateToUserName handler
  let noAccess := m!"handler `{shown}` takes no access value, so nothing says who may call \
    it.\nAdd `(_ : Public)` as its first argument for a public endpoint."
  let info ← getConstInfo handler
  forallTelescope info.type fun xs result => do
    let some access := xs[0]?
      | throwError noAccess
    unless ← withReducible (isDefEq (← inferType access) (mkConst ``Espal.Public)) do
      throwError noAccess
    let decls ← xs.mapM fun x => getFVarLocalDecl x
    for decl in decls do
      unless decl.binderInfo.isExplicit do
        throwError m!"handler `{shown}` takes `{decl.userName}` as an implicit argument, which \
          an `api` row has no way to fill."
    let mut args := #[]
    for decl in decls[1:] do
      let name := decl.userName.eraseMacroScopes
      let kind ←
        if ← withReducible (isDefEq decl.type (mkConst ``Nat)) then pure CaptureKind.nat
        else if ← withReducible (isDefEq decl.type (mkConst ``String)) then
          pure CaptureKind.string
        else
          throwError m!"handler `{shown}` takes `{name} : {decl.type}`, but a path capture \
            fills only a `Nat` or `String` argument."
      unless captures.contains name.toString do
        throwError m!"handler `{shown}` takes `{name}`, but path `{path}` has no capture \
          `:{name}`."
      args := args.push (name, kind)
    if result.hasAnyFVar fun f => xs.contains (.fvar f) then
      throwError m!"handler `{shown}` has a result type that depends on its arguments, so its \
        table has no single result type."
    return (args.toList, result)

/-- The syntax of `seg` as a `Routing.PathSeg` literal. -/
private meta def segSyntax {m : Type → Type} [Monad m] [MonadQuotation m] : PathSeg → m Term
  | .lit s _ => `(Routing.PathSeg.lit $(quote s))
  | .capture name .nat => `(Routing.PathSeg.capture $(quote name) .nat)
  | .capture name .string => `(Routing.PathSeg.capture $(quote name) .string)

/-- The captures of `segs`, in path order, with their kinds. -/
private meta def captures (segs : List PathSeg) : List (String × CaptureKind) :=
  segs.filterMap fun
    | .capture name kind => some (name, kind)
    | .lit _ _ => none

/-- `x` as a `fun` binder. -/
private meta def funBinder (x : Ident) : TSyntax ``Lean.Parser.Term.funBinder :=
  ⟨x.raw⟩

/-- The syntax of a capture kind's type. -/
private meta def kindType : CaptureKind → Term
  | .nat => mkCIdent ``Nat
  | .string => mkCIdent ``String

/-- The `Args` value for `segs`, built from variables named after its captures. -/
private meta def argsSyntax {m : Type → Type} [Monad m] [MonadQuotation m] (segs : List PathSeg) :
    m Term := do
  (captures segs).foldrM (init := ← `(())) fun (name, _) acc =>
      `(($(mkIdent (Name.mkSimple name)), $acc))

elab_rules : command
  | `(command| api $apiId:ident where $rows*) => do
    let apiName := apiId.getId
    let mut parsed : Array (Row × Expr) := #[]
    for row in rows do
      let `(apiRoute| $methodId:ident $pathLit:str => $handlerId:ident) := row
        | throwUnsupportedSyntax
      let methodText := methodId.getId.toString
      let some (_, method) := methods.find? (·.1 == methodText)
        | throwErrorAt methodId m!"`{methodText}` is not a method an `api` row accepts. Use \
            GET, HEAD, POST, PUT, PATCH, DELETE or OPTIONS."
      let path := pathLit.getString
      let raw ← match parsePath path with
        | .ok raw => pure raw
        | .error msg => throwErrorAt pathLit msg
      let handler ← liftCoreM <| realizeGlobalConstNoOverloadWithInfo handlerId
      if parsed.any (·.1.handler == handler) then
        throwErrorAt handlerId m!"handler `{privateToUserName handler}` appears twice in \
          `api {apiName}`, so a link to it would be ambiguous."
      let captureNames := raw.filterMap fun | .capture n => some n | .lit _ => none
      let (args, result) ← withRef handlerId <| liftTermElabM <|
        readHandler handler captureNames path
      let segs ← match raw.mapM (resolveSeg handler path args) with
        | .ok segs => pure segs
        | .error msg => throwErrorAt pathLit msg
      parsed := parsed.push
        ({ ref := row, methodText, method, path, handler, segs, args }, result)
    -- One result type for the whole table.
    if let some (first, firstResult) := parsed[0]? then
      for (r, result) in parsed[1:] do
        unless ← liftTermElabM (isDefEq result firstResult) do
          throwErrorAt r.ref m!"handler `{privateToUserName r.handler}` returns `{result}`, but \
            handler `{privateToUserName first.handler}` returns `{firstResult}`. Every handler in \
            one `api` table returns the same type."
    -- The check `linksDisjoint` makes, run here so the error names both routes.
    let rowsArr := parsed.map (·.1)
    for hj : j in [0:rowsArr.size] do
      for hi : i in [j+1:rowsArr.size] do
        let earlier := rowsArr[j]
        let later := rowsArr[i]
        if earlier.method == later.method && overlaps earlier.segs later.segs then
          throwErrorAt later.ref m!"{earlier.display} accepts links built for the later \
            route {later.display}.\nThose links would reach the wrong handler. Change one of \
            the two paths."
    -- `def Name`, an `Api` with the routes and the `decide +kernel` proof.
    let routeTerms ← rowsArr.mapM fun r => liftTermElabM do
      let segs : Array Term ← r.segs.toArray.mapM segSyntax
      let caps : Array Ident :=
        (captures r.segs).toArray.map fun (n, _) => mkIdent (Name.mkSimple n)
      let callArgs : Array Term := r.args.toArray.map fun (n, _) => mkIdent n
      let body ← `($(mkCIdent r.handler) {} $callArgs*)
      let handlerTerm ← if caps.isEmpty then pure body
        else `(fun $(caps.map funBinder)* => $body)
      `({ method := $(mkCIdent r.method), segs := [$segs,*], handler := $handlerTerm :
          Routing.Route _ })
    elabCommand <| ← `(command|
      def $apiId :=
        ({ routes := [$routeTerms,*], links_disjoint := by decide +kernel } : Espal.Api _))
    -- `pathTo` and its theorem for each handler.
    for hidx : idx in [0:rowsArr.size] do
      let r := rowsArr[idx]
      let segs : Array Term ← r.segs.toArray.mapM segSyntax
      let segsTerm ← `([$segs,*])
      let argsTerm ← argsSyntax r.segs
      let binders : Array Ident := r.args.toArray.map fun (n, _) => mkIdent n
      let binderTerms : Array Term := binders.map (·)
      let pathType ← r.args.foldrM (init := ← `(List String)) fun (_, kind) acc =>
        `($(kindType kind) → $acc)
      let pathFn ← if binders.isEmpty then `(Espal.Route.pathOf $segsTerm $argsTerm)
        else `(fun $(binders.map funBinder)* => Espal.Route.pathOf $segsTerm $argsTerm)
      let handlerIdent := mkCIdent r.handler
      let instName := mkIdentFrom apiId (apiName ++ (`instPathTo).appendAfter
        (lastComponent r.handler).capitalize)
      elabCommand <| ← `(command|
        instance $instName:ident : Espal.PathTo $handlerIdent $pathType := ⟨$pathFn⟩)
      let explicitBinders ← r.args.toArray.mapM fun (n, kind) =>
        `(Lean.Parser.Term.bracketedBinderF| ($(mkIdent n) : $(kindType kind)))
      let linkableBinders ← (captures r.segs).toArray.filterMapM fun (n, kind) =>
        match kind with
        | .string => some <$>
            `(Lean.Parser.Term.bracketedBinderF|
              ($(mkIdent (Name.mkSimple s!"h_{n}")) :
                Routing.unlinkable $(mkIdent (Name.mkSimple n)) = false))
        | .nat => pure none
      let thmName := mkIdentFrom apiId
        (apiName ++ Name.mkSimple s!"pathTo_{lastComponent r.handler}")
      let idxLit := Syntax.mkNumLit (toString idx)
      elabCommand <| ← `(command|
        theorem $thmName:ident $explicitBinders* $linkableBinders* :
            Routing.matchTable (Espal.Api.routes $apiId) $(mkCIdent r.method)
                (Espal.pathTo $handlerIdent $binderTerms*) =
              some (⟨$(mkCIdent r.method), $segsTerm⟩, $handlerIdent {} $binderTerms*) :=
          Espal.Api.matchTable_pathOf $apiId ⟨$idxLit, by decide⟩ $argsTerm
            (show Espal.Route.Linkable $segsTerm $argsTerm by simp [Espal.Route.Linkable, *]))

end Espal.ApiCommand
