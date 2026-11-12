/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Access
public import EspalCore.Handler
public import EspalCore.Reply
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

declares `Bench : Api Endpoint`, a lean-routing table whose links reach their routes. Each row
gives a method, a path and a handler. The handler's signature gives the rest. Its first argument is
the access value. The path capture with the same name fills a later argument, which must be a `Nat`
or a `String`. An argument with no capture of its name reads the query parameter of that name
when its type has a `FromQuery` instance. At most one other argument is left, and it is the request
body. Its type needs a `FromBody` instance, and only a POST, PUT or PATCH row takes one. The result type
needs a `ToAnswer` instance, and the command wraps each handler into an `Endpoint`. A plain value
has one through `ToReply`, and so do `Handler α` and `Fails ε α`, whose programs may read the clock,
draw random numbers and log.

For each handler `h`, the command also declares `pathTo h` and a theorem `Bench.pathTo_h`.
`pathTo h` builds the decoded path of a link to `h` from `h`'s arguments. The theorem shows that
`matchTable` sends that path to `h`'s endpoint with those arguments. The command fails to compile when a route would
catch a link built for a later route with the same method.

The command also declares `linkTo h` and a theorem `Bench.linkTo_h`. `linkTo h` takes `h`'s
captures and query arguments and builds a `Link`, which holds the path and the query parameters.
The theorem shows that following the link gives the reply of `h` for those arguments. A handler
gets no `linkTo` when one of its query arguments has no `LawfulQuery` instance.

A handler can link to another row of its own table. It takes that row's `LinkTo` or `PathTo`
instance as an instance argument, and the command fills it when it builds the table.
-/

@[expose] public section

namespace Espal

universe u v
open Routing Espal.Route

/-- A route table whose links reach their routes. The `api` command builds one. -/
structure Api (α : Type u) where
  /-- The routes, tried in order. -/
  routes : List (Route α)
  /-- No route accepts a link built for a later route with the same method. -/
  links_disjoint : linksDisjoint routes = true

/-- Every link to a route in `api` reaches that route, with the arguments it was built from. -/
theorem Api.matchTable_pathOf {α : Type u} (t : Api α) (i : Fin t.routes.length)
    (args : Args t.routes[i].segs) (hl : Linkable t.routes[i].segs args) :
    matchTable t.routes t.routes[i].method (pathOf t.routes[i].segs args) =
      some
        (⟨t.routes[i].method, t.routes[i].segs⟩,
          applyHandler t.routes[i].segs t.routes[i].handler args) :=
  Espal.Route.matchTable_pathOf t.links_disjoint i args hl

/-- `t` with `f` applied to each handler's result. Mapping keeps each route's method and pattern, so
`t`'s proof carries over. -/
def Api.map {α : Type u} {β : Type v} (f : α → β) (t : Api α) : Api β where
  routes := t.routes.map (mapRoute f)
  links_disjoint := (linksDisjoint_map f t.routes).trans t.links_disjoint

/-- lean-routing's route index over `t`'s routes. `t`'s own proof shows that no route is shadowed,
so building it checks nothing again. -/
def Api.index {α : Type u} (t : Api α) : RouteIndex α :=
  RouteIndex.of t.routes (unshadowed_of_linksDisjoint t.links_disjoint)

/-- The methods that `path` answers in `t`. A request for `path` with any other method gets `405`
when this list has a method, and `404` when it has none. -/
def Api.allowed {α : Type u} (t : Api α) (path : List String) : List Std.Http.Method :=
  (t.routes.map (·.method)).eraseDups.filter fun m => (matchTable t.routes m path).isSome

/-- `allowed` lists exactly the methods whose route matches the path. -/
theorem Api.mem_allowed_iff {α : Type u} (t : Api α) (path : List String) (m : Std.Http.Method) :
    m ∈ t.allowed path ↔ (matchTable t.routes m path).isSome := by
  simp only [Api.allowed, List.mem_filter, and_iff_right_iff_imp]
  intro h
  obtain ⟨x, hx⟩ := Option.isSome_iff_exists.1 h
  obtain ⟨r, hr, hm⟩ := List.exists_of_findSome?_eq_some hx
  have hbeq : (r.method == m) = true := by
    simp only [Route.tryMatch, Route.tryDispatch] at hm
    split at hm <;> simp_all
  have : ReflBEq Std.Http.Method := ⟨method_beq_self _⟩
  have : LawfulBEq Std.Http.Method := ⟨method_eq_of_beq⟩
  exact List.mem_eraseDups.2 (List.mem_map.2 ⟨r, hr, eq_of_beq hbeq⟩)

/-- The reply of `t` to a request, run against `world` with no server. `none` means no route
matches the method and path. -/
def Api.reply? (t : Api Endpoint) (method : Std.Http.Method) (path : List String)
    (query : Query := []) (contentType : Option String := none)
    (body : ByteArray := ByteArray.empty) (world : World := { clock := 0 }) : Option Reply :=
  match matchTable t.routes method path with
  | some (_, endpoint) => some ((endpoint.reply query contentType body).value world)
  | none => none

/-- The decoded path of a link to `handler`, as a function of the handler's arguments after the
access value. The `api` command declares an instance for each handler in its table. -/
class PathTo {τ : Type u} (handler : τ) (Path : outParam Type) where
  /-- The path, as a function of the handler's arguments. -/
  pathTo : Path

/-- The decoded path of a link to `handler`, as a function of the handler's arguments after the
access value. -/
def pathTo {τ : Type u} (handler : τ) {Path : Type} [PathTo handler Path] : Path :=
  PathTo.pathTo handler

/-- A link to `handler`, as a function of the handler's arguments after the access value, without
its body. The `api` command declares an instance for each handler whose query arguments have
`LawfulQuery` instances. -/
class LinkTo {τ : Type u} (handler : τ) (Fn : outParam Type) where
  /-- The link, as a function of the handler's arguments. -/
  linkTo : Fn

/-- A link to `handler`, as a function of the handler's arguments after the access value, without
its body. Captures fill the path, and query arguments fill the query. -/
def linkTo {τ : Type u} (handler : τ) {Fn : Type} [LinkTo handler Fn] : Fn :=
  LinkTo.linkTo handler

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
  /-- The handler's arguments that captures fill, in the handler's order, with their kinds. -/
  args : List (Name × CaptureKind)
  /-- All the handler's arguments after the access value, in order. -/
  callArgs : List Name
  /-- The arguments that query parameters fill, in order. -/
  queries : List Name
  /-- The types of the query arguments, in order, if each has a `LawfulQuery` instance. -/
  queryTypes? : Option (List Term)
  /-- The argument that the request body fills, if the handler has one. -/
  body? : Option Name

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

/-- What `readHandler` finds in a handler's signature. -/
private meta structure Signature where
  /-- The arguments that captures fill, in order, with their kinds. -/
  args : List (Name × CaptureKind)
  /-- All the handler's arguments after the access value, in order. -/
  callArgs : List Name
  /-- The arguments that query parameters fill, in order. -/
  queries : List Name
  /-- The types of the query arguments, in order, if each has a `LawfulQuery` instance. -/
  queryTypes? : Option (List Term)
  /-- The argument that the request body fills, if there is one. -/
  body? : Option Name

/-- Whether `cls type` has an instance. -/
private meta def hasInstance (cls : Name) (type : Expr) : MetaM Bool := do
  try
    return (← trySynthInstance (← mkAppM cls #[type])) matches .some _
  catch _ =>
    return false

/-- Whether `type` has a `LawfulQuery` instance, with the `ToQuery` instance it needs. -/
private meta def hasLawfulQuery (type : Expr) : MetaM Bool := do
  try
    let cls ← mkAppOptM ``Espal.LawfulQuery #[type, none, none]
    return (← trySynthInstance cls) matches .some _
  catch _ =>
    return false

/-- Reads the handler's signature. It checks the access value and sorts each later argument into a
capture or the body. It also checks that the body and the result have the instances they need. -/
private meta def readHandler (handler : Name) (captures : List String) (path methodText : String) :
    TermElabM Signature := do
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
    let isLink (decl : LocalDecl) : Bool :=
      decl.binderInfo.isInstImplicit &&
        (decl.type.isAppOf ``Espal.LinkTo || decl.type.isAppOf ``Espal.PathTo)
    for decl in decls do
      unless decl.binderInfo.isExplicit || isLink decl do
        throwError m!"handler `{shown}` takes `{decl.userName}` as an implicit argument, which \
          an `api` row has no way to fill."
    let mut args := #[]
    let mut callArgs := #[]
    let mut queries := #[]
    let mut queryTypes? : Option (Array Term) := some #[]
    let mut body? : Option (Name × Expr) := none
    for decl in decls[1:] do
      if isLink decl then
        continue
      let name := decl.userName.eraseMacroScopes
      callArgs := callArgs.push name
      if captures.contains name.toString then
        let kind ←
          if ← withReducible (isDefEq decl.type (mkConst ``Nat)) then pure CaptureKind.nat
          else if ← withReducible (isDefEq decl.type (mkConst ``String)) then
            pure CaptureKind.string
          else
            throwError m!"handler `{shown}` takes `{name} : {decl.type}`, but a path capture \
              fills only a `Nat` or `String` argument."
        args := args.push (name, kind)
      else if ← hasInstance ``Espal.FromQuery decl.type then
        queries := queries.push name
        if ← hasLawfulQuery decl.type then
          let type ← withOptions (pp.fullNames.set · true) (PrettyPrinter.delab decl.type)
          queryTypes? := queryTypes?.map (·.push type)
        else
          queryTypes? := none
      else if let some (first, _) := body? then
        throwError m!"handler `{shown}` takes `{first}` and `{name}`, and path `{path}` has no \
          capture for either. A handler reads at most one argument from the request body."
      else
        body? := some (name, decl.type)
    if let some (name, type) := body? then
      unless ["POST", "PUT", "PATCH"].contains methodText do
        throwError m!"handler `{shown}` takes `{name}`, but path `{path}` has no capture \
          `:{name}`, so `{name}` would be the request body.\nOnly a POST, PUT or PATCH row takes \
          a body, and this row is {methodText}."
      unless ← hasInstance ``Espal.FromBody type do
        throwError m!"handler `{shown}` takes the request body as `{name} : {type}`, which has \
          no `FromBody` instance.\nDerive one with `deriving Json`."
    if result.hasAnyFVar fun f => xs.contains (.fvar f) then
      throwError m!"handler `{shown}` has a result type that depends on its arguments, so it \
        has no single reply type."
    unless ← hasInstance ``Espal.ToAnswer result do
      throwError m!"handler `{shown}` returns `{result}`, which has no `ToReply` instance.\n\
        Return `Text` for plain text, or a type that derives `Json`."
    let sig : Signature :=
      { args := args.toList, callArgs := callArgs.toList, queries := queries.toList
        queryTypes? := queryTypes?.map (·.toList), body? := body?.map (·.1) }
    return sig

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

/-- The endpoint for the handler of `r`. Its variables take the names of the handler's arguments,
and a body argument is bound by the function that `Endpoint.ofBody` takes. -/
private meta def endpointSyntax {m : Type → Type} [Monad m] [MonadQuotation m] (r : Row) : m Term :=
  do
  let callArgs : Array Term := r.callArgs.toArray.map fun n => mkIdent n
  let call ← `($(mkCIdent r.handler) {} $callArgs*)
  if r.queries.isEmpty then
    match r.body? with
    | none =>
      `(Espal.Endpoint.ofValue $call)
    | some body =>
      `(Espal.Endpoint.ofBody fun $(funBinder (mkIdent body)) => $call)
  else
    let query ← `(query)
    let decode ← `(decode)
    let mut reply ← `(Espal.ToAnswer.answer $call)
    if let some body := r.body? then
      reply ← `($decode fun $(funBinder (mkIdent body)) => $reply)
    for q in r.queries.reverse do
      reply ← `(Espal.withQuery $query $(quote q.toString) fun $(funBinder (mkIdent q)) => $reply)
    match r.body? with
    | none =>
      `(Espal.Endpoint.noBody fun $query => $reply)
    | some _ =>
      `(Espal.Endpoint.ofQueryBody fun $query $decode => $reply)

elab_rules : command
  | `(command| api $apiId:ident where $rows*) => do
    let apiName := apiId.getId
    let mut parsed : Array Row := #[]
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
      if parsed.any (·.handler == handler) then
        throwErrorAt handlerId m!"handler `{privateToUserName handler}` appears twice in \
          `api {apiName}`, so a link to it would be ambiguous."
      let captureNames := raw.filterMap fun | .capture n => some n | .lit _ => none
      let sig ← withRef handlerId <| liftTermElabM <|
        readHandler handler captureNames path methodText
      let segs ← match raw.mapM (resolveSeg handler path sig.args) with
        | .ok segs => pure segs
        | .error msg => throwErrorAt pathLit msg
      parsed := parsed.push
        { ref := row, methodText, method, path, handler, segs, args := sig.args
          callArgs := sig.callArgs, queries := sig.queries, queryTypes? := sig.queryTypes?
          body? := sig.body? }
    -- The check `linksDisjoint` makes, run here so the error names both routes.
    let rowsArr := parsed
    for hj : j in [0:rowsArr.size] do
      for hi : i in [j+1:rowsArr.size] do
        let earlier := rowsArr[j]
        let later := rowsArr[i]
        if earlier.method == later.method && overlaps earlier.segs later.segs then
          throwErrorAt later.ref m!"{earlier.display} accepts links built for the later \
            route {later.display}.\nThose links would reach the wrong handler. Change one of \
            the two paths."
    -- The `PathTo` and `LinkTo` instances come before the table, so a handler in it can take one
    -- as an instance argument and link to another row.
    for r in rowsArr do
      let segs : Array Term ← r.segs.toArray.mapM segSyntax
      let segsTerm ← `([$segs,*])
      let argsTerm ← argsSyntax r.segs
      let binders : Array Ident := r.args.toArray.map fun (n, _) => mkIdent n
      let pathType ← r.args.foldrM (init := ← `(List String)) fun (_, kind) acc =>
        `($(kindType kind) → $acc)
      let pathFn ← if binders.isEmpty then `(Espal.Route.pathOf $segsTerm $argsTerm)
        else `(fun $(binders.map funBinder)* => Espal.Route.pathOf $segsTerm $argsTerm)
      let handlerIdent := mkCIdent r.handler
      let instName := mkIdentFrom apiId (apiName ++ (`instPathTo).appendAfter
        (lastComponent r.handler).capitalize)
      elabCommand <| ← `(command|
        instance $instName:ident : Espal.PathTo $handlerIdent $pathType := ⟨$pathFn⟩)
      let some queryTypes := r.queryTypes?
        | continue
      let linkArgs := r.callArgs.filter fun n => some n != r.body?
      let linkTypes : List Term := linkArgs.map fun n =>
        match r.args.find? (·.1 == n), (r.queries.zip queryTypes).find? (·.1 == n) with
        | some (_, kind), _ => kindType kind
        | none, some (_, type) => type
        | none, none => mkCIdent ``Unit
      let linkIdents : Array Ident := linkArgs.toArray.map fun n => mkIdent n
      let linkType ← linkTypes.foldrM (init := ← `(Espal.Link)) fun type acc => `($type → $acc)
      let noQuery ← `(([] : Espal.Query))
      let queryTerm ← r.queries.foldrM (init := noQuery) fun q acc =>
        `(Espal.Query.with $(quote q.toString) $(mkIdent q) $acc)
      let link ← `((⟨Espal.Route.pathOf $segsTerm $argsTerm, $queryTerm⟩ : Espal.Link))
      let linkFn ← if linkIdents.isEmpty then pure link
        else `(fun $(linkIdents.map funBinder)* => $link)
      let linkInst := mkIdentFrom apiId (apiName ++ (`instLinkTo).appendAfter
        (lastComponent r.handler).capitalize)
      elabCommand <| ← `(command|
        instance $linkInst:ident : Espal.LinkTo $handlerIdent $linkType := ⟨$linkFn⟩)
    -- `def Name`, an `Api` with the routes. The kernel checks `keysDisjoint`, which
    -- `keysDisjoint_map_routeKey` turns into `linksDisjoint`.
    let routeTerms ← rowsArr.mapM fun r => liftTermElabM do
      let segs : Array Term ← r.segs.toArray.mapM segSyntax
      let caps : Array Ident :=
        (captures r.segs).toArray.map fun (n, _) => mkIdent (Name.mkSimple n)
      let body ← endpointSyntax r
      let handlerTerm ← if caps.isEmpty then pure body
        else `(fun $(caps.map funBinder)* => $body)
      `({ method := $(mkCIdent r.method), segs := [$segs,*], handler := $handlerTerm :
          Routing.Route Espal.Endpoint })
    elabCommand <| ← `(command|
      def $apiId :=
        ({ routes := [$routeTerms,*]
           links_disjoint := by
            rw [← Espal.Route.keysDisjoint_map_routeKey]
            decide +kernel } : Espal.Api Espal.Endpoint))
    -- The theorems for `pathTo` and `linkTo`, for each handler.
    for hidx : idx in [0:rowsArr.size] do
      let r := rowsArr[idx]
      let segs : Array Term ← r.segs.toArray.mapM segSyntax
      let segsTerm ← `([$segs,*])
      let argsTerm ← argsSyntax r.segs
      let binders : Array Ident := r.args.toArray.map fun (n, _) => mkIdent n
      let binderTerms : Array Term := binders.map (·)
      let handlerIdent := mkCIdent r.handler
      let explicitBinders ← r.args.toArray.mapM fun (n, kind) =>
        `(Lean.Parser.Term.bracketedBinderF| ($(mkIdent n) : $(kindType kind)))
      let linkableBinders ← (captures r.segs).toArray.filterMapM fun (n, kind) =>
        match kind with
        | .string => some <$>
            `(Lean.Parser.Term.bracketedBinderF|
              ($(mkIdent (Name.mkSimple s!"h_{n}")) :
                Routing.unlinkable $(mkIdent (Name.mkSimple n)) = false))
        | .nat => pure none
      let idxLit := Syntax.mkNumLit (toString idx)
      let stmt ← `(Routing.matchTable (Espal.Api.routes $apiId) $(mkCIdent r.method)
            (Espal.pathTo $handlerIdent $binderTerms*) =
          some (⟨$(mkCIdent r.method), $segsTerm⟩, $(← endpointSyntax r)))
      -- The proof applies `Api.matchTable_pathOf` at index `idx`, and its type matches `stmt`
      -- only once `routes[idx]` unfolds. The elaborator unfolds it a step at a time, which took
      -- most of a second at index 199, so the kernel checks the proof instead.
      let isPublic := (← getScope).isPublic
      liftTermElabM do
        let table ← Term.elabTerm apiId none
        let some α := (← inferType table).app1? ``Espal.Api
          | throwError "`{apiName}` is not an `Espal.Api`."
        let some tableName := table.constName?
          | throwError "`{apiName}` is not a constant."
        let declName := tableName ++ Name.mkSimple s!"pathTo_{lastComponent r.handler}"
        Term.elabBinders (explicitBinders ++ linkableBinders) fun xs => do
          let type ← Term.elabType stmt
          let segs ← Term.elabTerm segsTerm (← mkAppM ``List #[mkConst ``PathSeg])
          let args ← Term.elabTermEnsuringType argsTerm (← mkAppM ``Espal.Route.Args #[segs])
          let hl ← Term.elabTermEnsuringType (← `(by simp [Espal.Route.Linkable, *]))
            (← mkAppM ``Espal.Route.Linkable #[segs, args])
          let len ← mkAppM ``List.length #[← mkAppM ``Espal.Api.routes #[table]]
          let i ← Term.elabTermEnsuringType (← `(⟨$idxLit, by decide +kernel⟩))
            (← mkAppM ``Fin #[len])
          Term.synthesizeSyntheticMVarsNoPostponing
          let level ← getDecLevel α
          let proof :=
            mkAppN (mkConst ``Espal.Api.matchTable_pathOf [level]) #[α, table, i, args, hl]
          let type ← instantiateMVars (← mkForallFVars xs type)
          let value ← instantiateMVars (← mkLambdaFVars xs proof)
          withExporting (isExporting := isPublic) <|
            addDecl (.thmDecl { name := declName, levelParams := [], type, value })
          addDeclarationRangesFromSyntax declName r.ref
      -- The `linkTo` theorem, when every query argument can be written back.
      let some queryTypes := r.queryTypes?
        | continue
      let linkArgs := r.callArgs.filter fun n => some n != r.body?
      let linkTypes : List Term := linkArgs.map fun n =>
        match r.args.find? (·.1 == n), (r.queries.zip queryTypes).find? (·.1 == n) with
        | some (_, kind), _ => kindType kind
        | none, some (_, type) => type
        | none, none => mkCIdent ``Unit
      let linkIdents : Array Ident := linkArgs.toArray.map fun n => mkIdent n
      let linkTerms : Array Term := linkIdents.map (·)
      let noQuery ← `(([] : Espal.Query))
      let queryTerm ← r.queries.foldrM (init := noQuery) fun q acc =>
        `(Espal.Query.with $(quote q.toString) $(mkIdent q) $acc)
      let linkBinders ← (linkArgs.zip linkTypes).toArray.mapM fun (n, type) =>
        `(Lean.Parser.Term.bracketedBinderF| ($(mkIdent n) : $type))
      let fresh (base : String) : Ident :=
        mkIdent (Name.mkSimple (if r.callArgs.contains (Name.mkSimple base) then base ++ "'" else base))
      let contentType := fresh "contentType"
      let bytes := fresh "bytes"
      let hypTerms : Array Term := (captures r.segs).toArray.filterMap fun (n, kind) =>
        match kind with
        | .string => some (mkIdent (Name.mkSimple s!"h_{n}"))
        | .nat => none
      let callArgs : Array Term := r.callArgs.toArray.map fun n => mkIdent n
      let call ← `($handlerIdent {} $callArgs*)
      let supplied ← match r.body? with
        | none => `(Espal.Endpoint.ofValue $call)
        | some body => `(Espal.Endpoint.ofBody fun $(funBinder (mkIdent body)) => $call)
      let pathThm := mkIdentFrom apiId
        (apiName ++ Name.mkSimple s!"pathTo_{lastComponent r.handler}")
      let linkThm := mkIdentFrom r.ref
        (apiName ++ Name.mkSimple s!"linkTo_{lastComponent r.handler}")
      let linkProof ←
        if r.queries.isEmpty then
          `(Lean.Parser.Tactic.tacticSeq|
            rw [show (Espal.linkTo $handlerIdent $linkTerms*).path =
                Espal.pathTo $handlerIdent $binderTerms* from rfl,
              $pathThm:ident $binderTerms* $hypTerms*]
            rfl)
        else
          `(Lean.Parser.Tactic.tacticSeq|
            have hp : (Espal.linkTo $handlerIdent $linkTerms*).path =
                Espal.pathTo $handlerIdent $binderTerms* := rfl
            have hq : (Espal.linkTo $handlerIdent $linkTerms*).query = $queryTerm := rfl
            rw [hp, hq, $pathThm:ident $binderTerms* $hypTerms*]
            simp [Espal.Endpoint.ofValue, Espal.Endpoint.ofBody, Espal.Endpoint.ofQueryBody,
              Espal.withQuery])
      elabCommand <| ← `(command|
        theorem $linkThm:ident $linkBinders:bracketedBinder* $linkableBinders:bracketedBinder*
            ($contentType : Option String) ($bytes : ByteArray) :
            (Routing.matchTable (Espal.Api.routes $apiId) $(mkCIdent r.method)
                (Espal.linkTo $handlerIdent $linkTerms*).path).map
              (fun m =>
                Espal.Endpoint.reply m.2 (Espal.linkTo $handlerIdent $linkTerms*).query
                  $contentType $bytes) =
              some (Espal.Endpoint.reply $supplied [] $contentType $bytes) := by $linkProof)

end Espal.ApiCommand
