/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalJson.Recursive
public meta import Lean.Elab.Deriving.Basic

/-!
# `deriving Json`

`deriving Json` writes `ToJson`, `JsonDecode` and `FromJson` instances, and proves `LawfulDecode`,
`LawfulJson` and `NotNullJson`.

- A structure becomes an object with one key per data field, in declaration order. Optional
  fields follow the convention in `EspalJson.Object`.
- An inductive type whose constructors have no arguments becomes a string, the constructor's name.
- Any other inductive type becomes a tagged object. Its `kind` key names the constructor, and each
  data argument gets a key, as a structure field does.

The decoder reads every data field and reports each failure. Once they all decode, it decides
each proof field, such as `ok : lo ≤ hi`, and reports each one that fails by its name. It also
reports every key the type doesn't have.

Each data field's type needs a `LawfulDecode` instance, and an optional field's type also needs
`NotNullJson`. A parameter that a data field's type mentions, such as `α` in `items : Array α`,
gets the same instances as arguments of the derived instances. It gets `NotNullJson` only if a
field needs it.

A field whose type is the type being derived, or an `Array`, `List` or `Option` of it, makes the
codec recursive. Its decoder counts down from the depth of the input, as `EspalJson.Recursive`
describes. The handler can't yet take a type with indices.
-/

public section

namespace Espal.Deriving

open Lean Elab Command Term Meta

/-- Stops the derivation with a reason. -/
meta def refuse {α : Type} (declName : Name) (reason : MessageData) : MetaM α :=
  throwError m!"cannot derive Json for {.ofConstName declName}: {reason}"

/-- Whether `e` occurs in `type`. -/
meta def mentions (e type : Expr) : Bool :=
  (type.find? (· == e)).isSome

/-- Runs `k` with fresh variables for the parameters of `declName`, and the type they make. -/
meta def withParams {α : Type} (declName : Name) (k : Array Expr → Expr → MetaM α) : MetaM α := do
  let info ← getConstInfoInduct declName
  forallBoundedTelescope info.type info.numParams fun params _ =>
      k params (mkAppN (mkConst declName (info.levelParams.map mkLevelParam)) params)

/-- The fields of a structure type, data first and then proofs, each in declaration order. -/
meta def splitFieldsOf (declName : Name) (type : Expr) : MetaM (Array Name × Array Name) := do
  let fields := getStructureFieldsFlattened (← getEnv) declName (includeSubobjectFields := false)
  withLocalDeclD `self type fun self => do
      let mut data := #[]
      let mut proofs := #[]
      for f in fields do
        if ← isProp (← inferType (← mkProjection self f)) then
          proofs := proofs.push f
        else
          data := data.push f
      return (data, proofs)

/-- A structure's fields, data first and then proofs, each in declaration order. -/
meta def splitFields (declName : Name) : MetaM (Array Name × Array Name) :=
  withParams declName fun _ type => splitFieldsOf declName type

/--
`espal_json_field_type% S f a₁ … aₙ` is the type of the field `f` of the structure type `S`, with
the data fields of `S` replaced by `a₁ … aₙ` in order. The derived decoder states each proof
field's proposition with it, in terms of the values it decoded.
-/
syntax (name := fieldTypeStx) "espal_json_field_type% " term:max ident (ppSpace colGt term:max)* :
  term

/-- Turns `espal_json_field_type%` into the type it names. -/
@[term_elab fieldTypeStx]
meta def elabFieldType : TermElab := fun stx _ => do
  match stx with
  | `(espal_json_field_type% $struct $field:ident $args*) =>
    let structType ← instantiateMVars (← elabType struct)
    let some declName :=
      structType.getAppFn.constName? | throwError "espal_json_field_type% needs a structure type, not {structType}"
    let (data, _) ← splitFieldsOf declName structType
    let args ← args.mapM (elabTerm · none)
    withLocalDeclD `self structType fun self => do
        let mut type ← instantiateMVars (← inferType (← mkProjection self field.getId))
        for (g, v) in data.zip args do
          let e ← mkProjection self g
          type := type.replace fun t => if t == e then some v else none
        if mentions self type then
          refuse declName m!"the type of {field.getId} depends on a field that isn't data"
        return type
  | _ =>
    throwUnsupportedSyntax

/--
`espal_json_arg_type% C i a₁ … aₙ` is the type of argument `i` of `C`, a constructor applied to
its type's parameters. Given values for every data argument of `C`, in order, it puts them in
place of those arguments.
-/
syntax (name := argTypeStx) "espal_json_arg_type% " term:max num (ppSpace colGt term:max)* : term

/-- Turns `espal_json_arg_type%` into the type it names. -/
@[term_elab argTypeStx]
meta def elabArgType : TermElab := fun stx _ => do
  match stx with
  | `(espal_json_arg_type% $ctor $i:num $args*) =>
    let ctorTerm ← elabTerm ctor none
    let some ctorName := ctorTerm.getAppFn.constName? |
      throwError "espal_json_arg_type% needs a constructor, not {ctorTerm}"
    let info ← getConstInfoCtor ctorName
    let args ← args.mapM (elabTerm · none)
    forallTelescopeReducing (← inferType ctorTerm) fun xs _ => do
        let some x := xs[i.getNat]? | refuse info.induct m!"{ctorName} has no argument {i.getNat}"
        let data ← xs.filterM fun y => return !(← isProp (← inferType y))
        let mut type ← instantiateMVars (← inferType x)
        if args.size == data.size then
          type := type.replaceFVars data args
        if xs.any (mentions · type) then
          refuse info.induct
              m!"the type of an argument of {ctorName} depends on an argument that isn't data"
        return type
  | _ =>
    throwUnsupportedSyntax

/-- The JSON key of a field, and whether a trailing `?` makes it optional. -/
meta def fieldKey (declName : Name) (field : Name) : MetaM (String × Bool) := do
  let .str .anonymous s := field | refuse declName m!"can't name a key after the field {field}"
  let key := (s.dropEndWhile (· == '?')).copy
  return (key, key != s)

/-- Whether `cls type` has an instance, counting a missing instance argument as none. -/
meta def hasInstance (cls : Name) (type : Expr) : MetaM Bool := do
  try
    let arity := (← getConstInfo cls).type.getForallBinderNames.length
    let goal ← mkAppOptM cls (#[some type] ++ Array.replicate (arity - 1) none)
    return (← trySynthInstance goal) matches .some _
  catch _ =>
    return false

/-- Refuses a check that the decoder can't decide. -/
meta def checkDecidable (declName : Name) (name : Name) (prop : Expr) : MetaM Unit := do
  if (← trySynthInstance (mkApp (mkConst ``Decidable) prop)) matches .none then
    refuse declName m!"the check {name} has no Decidable instance, so the decoder can't decide it"

/--
Refuses a data field whose key the encoding can't use. `reserved` holds the keys the encoding
itself uses.
-/
meta def checkKeys (declName : Name) (reserved : Array String) (data : Array (Name × Expr)) :
    MetaM Unit := do
  let mut keys := reserved
  for (f, type) in data do
    let (key, optional) ← fieldKey declName f
    if reserved.contains key then
      refuse declName m!"the field {f} uses the key {key}, which names the constructor"
    if keys.contains key then
      refuse declName m!"two fields use the key {key}"
    keys := keys.push key
    if optional && ((← whnfR type).app1? ``Option).isNone then
      refuse declName m!"the optional field {f} needs an Option type, not {type}"

/-- How a data field's type contains the type being derived, if it does. -/
inductive FieldKind where
  /-- It doesn't, so the field's own codec reads and writes it. -/
  | plain
  /-- The field is a value of the type itself. -/
  | direct
  /-- An `Array` of the type. -/
  | array
  /-- A `List` of the type. -/
  | list
  /-- A required `Option` of the type, with `null` for `none`. -/
  | option
  /-- An optional field, named with a trailing `?`, of an `Option` of the type. -/
  | optional

/-- Whether `kind` reads and writes through the field's own codec. -/
meta def FieldKind.isPlain : FieldKind → Bool
  | .plain => true
  | _ => false

/--
How the type of the data field `f` contains the type being derived. Refuses a field that
contains it in any other shape.
-/
meta def fieldKind (declName : Name) (params : Array Expr) (f : Name) (type : Expr) :
    MetaM FieldKind := do
  if (type.find? (·.isConstOf declName)).isNone then
    return .plain
  let info ← getConstInfoInduct declName
  let self := mkAppN (mkConst declName (info.levelParams.map mkLevelParam)) params
  let type ← instantiateMVars type
  if (← fieldKey declName f).2 then
    if (type.app1? ``Option).any (· == self) then
      return .optional
  else
    if type == self then
      return .direct
    if (type.app1? ``Array).any (· == self) then
      return .array
    if (type.app1? ``List).any (· == self) then
      return .list
    if (type.app1? ``Option).any (· == self) then
      return .option
  refuse declName
      m!"the field {f} has type {type}, which contains {self} in a shape the handler \
    doesn't cover. It covers {self} itself, and an Array, List or Option of it"

/-- The type a field's value must have a codec for: the `α` of an optional field's `Option α`. -/
meta def codecType (declName : Name) (field : Name) (type : Expr) : MetaM Expr := do
  if (← fieldKey declName field).2 then
    return ((← whnfR type).app1? ``Option).getD type
  else
    return type

/-- Runs `k` with codec instances for each parameter, and `NotNullJson` where marked. -/
meta def withCodecInstances {α : Type} (params : List (Expr × Bool)) (k : MetaM α) : MetaM α :=
  match params with
  | [] => k
  | (p, notNull) :: rest => do
    withLocalDecl `inst .instImplicit (← mkAppM ``Json.ToJson #[p]) fun _ => do
        withLocalDecl `inst .instImplicit (← mkAppM ``JsonDecode #[p]) fun _ => do
            withLocalDecl `inst .instImplicit (← mkAppOptM ``LawfulDecode #[p, none, none]) fun _ =>
                do
                if notNull then
                  withLocalDecl `inst .instImplicit (← mkAppOptM ``NotNullJson #[p, none]) fun _ =>
                      withCodecInstances rest k
                else
                  withCodecInstances rest k

/-- The first data field without the instances its round trip needs, as a reason to refuse. -/
meta def missingInstance (declName : Name) (data : Array (Name × Expr)) :
    MetaM (Option MessageData) := do
  for (f, type) in data do
    let inner ← codecType declName f type
    let optional := (← fieldKey declName f).2
    for cls in (if optional then [``LawfulDecode, ``NotNullJson] else [``LawfulDecode]) do
      unless ← hasInstance cls inner do
        return some m!"the field {f} has type {inner}, which has no {.ofConstName cls} instance"
  return none

/--
The parameters that take codecs, by position, with whether each needs `NotNullJson`. A parameter
takes codecs when a data field's type mentions it. Refuses a field whose round trip has no proof
even with those instances.
-/
meta def planParams (declName : Name) (params : Array Expr) (data : Array (Name × Expr)) :
    MetaM (Array (Nat × Bool)) := do
  let used :=
    (params.zip (Array.range params.size)).filter fun (p, _) =>
      data.any fun (_, type) => mentions p type
  for (p, _) in used do
    let .sort (.succ _) ←
      whnf
          (←
            inferType
                p) | refuse declName m!"a field's type mentions the parameter {p}, which isn't a type"
  let attempt (notNull : Array Bool) : MetaM (Option MessageData) :=
    withCodecInstances ((used.zip notNull).toList.map fun ((p, _), n) => (p, n))
      (missingInstance declName data)
  let mut notNull := used.map fun _ => true
  if let some reason := (← attempt notNull) then
    refuse declName reason
  for j in [0:notNull.size] do
    let trial := notNull.modify j fun _ => false
    if (← attempt trial).isNone then
      notNull := trial
  return (used.zip notNull).map fun ((_, i), n) => (i, n)

/-- The parameters of a derived codec, as its commands bind them. -/
structure Params where
  /-- The names that stand for the type's parameters. -/
  idents : Array Ident
  /-- The parameters that take codecs, with whether each needs `NotNullJson`. -/
  codecs : Array (Ident × Bool)

/-- Fresh names for the parameters of `declName`, and which of them take codecs. -/
meta def Params.make (declName : Name) (plan : Array (Nat × Bool)) : TermElabM Params := do
  let names ←
    withParams declName fun params _ =>
        params.mapM fun p => return (← getFVarLocalDecl p).userName.eraseMacroScopes
  let idents ← names.mapM fun n => return mkIdent (← mkFreshUserName n)
  let codecs := plan.filterMap fun (i, n) => idents[i]?.map (·, n)
  return { idents, codecs }

/--
The binders that a derived declaration takes. Each parameter comes first, and then the given
classes for each parameter that takes codecs.
-/
meta def Params.binders (ps : Params) (classes : Array Name) (withNotNull : Bool) :
    TermElabM (Array (TSyntax ``Parser.Term.bracketedBinder)) := do
  let mut binders ← ps.idents.mapM fun p => `(Lean.Parser.Term.bracketedBinderF| {$p})
  for (p, notNull) in ps.codecs do
    for cls in classes do
      binders := binders.push (← `(Lean.Parser.Term.bracketedBinderF| [$(mkCIdent cls) $p]))
    if withNotNull && notNull then
      binders := binders.push (← `(Lean.Parser.Term.bracketedBinderF| [Espal.NotNullJson $p]))
  return binders

/-- The derived type, applied to its parameters. -/
meta def Params.applied (ps : Params) (T : Ident) : TermElabM Term := do
  let idents := ps.idents
  `(@$T $idents*)

/-- Appends one field's value to the object the encoder builds. -/
meta def encodeStep (acc : Term) (key : String) (optional : Bool) (value : Term) : TermElabM Term :=
  if optional then `(Espal.pushOpt $acc $(quote key) $value)
  else `(Espal.pushField $acc $(quote key) $value)

/-- How the decoder reads one data field, with the type it reads at. -/
meta def readField (pointer fields : Ident) (key : String) (optional : Bool) (type : Term) :
    TermElabM Term :=
  if optional then
    `((Espal.optField $pointer $fields $(quote key) : Except (Array Espal.DecodeError) $type))
  else `((Espal.field $pointer $fields $(quote key) : Except (Array Espal.DecodeError) $type))

/-- Reads every data field, as nested pairs so that one failure doesn't hide another. -/
meta def readAll (reads : Array Term) (vars : Array Ident) : TermElabM (Term × Term) := do
  match (reads.zip vars).toList.reverse with
  | (lastRead, lastVar) :: earlier =>
    earlier.foldlM (init := ((lastRead : Term), (lastVar : Term))) fun (read, pat) (r, v) =>
        return (← `(Espal.both $r $read), ← `(($v, $pat)))
  | [] =>
    return (← `((Except.ok () : Except (Array Espal.DecodeError) Unit)), ← `(()))

/--
Decides each proof field in turn, and then builds the value. When one fails, the decoder reports
it with every later check that fails too.
-/
meta def decideChecks (pointer extra : Ident) (done : Term) :
    List (Name × Ident × Term) → TermElabM Term
  | [] => pure done
  | (f, h, p) :: rest => do
    let inner ← decideChecks pointer extra done rest
    let failed ←
      ((f, h, p) :: rest).foldrM (init := (extra : Term)) fun (g, _, q) acc =>
          `(Espal.check $pointer $(quote s!"fails the check {g}") $q ++ $acc)
    `(if $h:ident : $p then $inner else Except.error $failed)

/--
Decodes the fields of one object and builds `value` from them. It reports the keys outside
`keys` beside every other failure.
-/
meta def decodeObject (pointer fields : Ident) (keys : Array String) (reads : Array Term)
    (vars : Array Ident) (checks : List (Name × Ident × Term)) (value : Term) : TermElabM Term := do
  let extra := mkIdent (← mkFreshUserName `extra)
  let failures := mkIdent (← mkFreshUserName `failures)
  let (read, pat) ← readAll reads vars
  let body ← decideChecks pointer extra (← `(Espal.finish $extra $value)) checks
  let keys : Array Term := keys.map quote
  `(let $extra :=Espal.unknownKeys $pointer $fields [$keys,*]
      match $read:term with
      | .ok $pat => $body
      | .error $failures => .error ($failures ++ $extra))

/-- The encoder's and the decoder's headers, which bind the parameters and their codecs. -/
meta def defHeaders (ps : Params) :
    TermElabM
      (Array (TSyntax ``Parser.Term.bracketedBinder) ×
        Array (TSyntax ``Parser.Term.bracketedBinder)) :=
  return (← ps.binders #[``Json.ToJson] false, ← ps.binders #[``JsonDecode] false)

/--
The instances at the end of every derived codec. The term `decode` gives the `JsonDecode`
instance.
-/
meta def instanceCmds (ps : Params) (T enc : Ident) (decode lawful notNull : Term) :
    TermElabM (Array Command) := do
  let ty ← ps.applied T
  let (encB, decB) ← defHeaders ps
  let lawB ← ps.binders #[``Json.ToJson, ``JsonDecode, ``LawfulDecode] true
  return #[←
        `(
instance $encB:bracketedBinder* : _root_.Json.ToJson $ty :=
⟨$enc⟩),
      ←
        `(
instance $decB:bracketedBinder* : Espal.JsonDecode $ty :=
$decode),
      ←
        `(
set_option linter.unusedSimpArgs false in
instance $lawB:bracketedBinder* : Espal.LawfulDecode $ty :=
  $lawful),
      ←
        `(
instance $encB:bracketedBinder* : Espal.NotNullJson $ty :=
$notNull),
      ←
        `(
instance $decB:bracketedBinder* : _root_.Json.FromJson $ty :=
Espal.JsonDecode.toFromJson $ty),
      ←
        `(
instance $lawB:bracketedBinder* : Espal.LawfulJson $ty :=
Espal.JsonDecode.lawfulJson $ty)]

/-- The simp set of every derived round-trip proof, with the proofs to decide checks by. -/
meta def simpArgs (enc dec : Ident) (proofs : Array Term) :
    TermElabM (Array (TSyntax ``Parser.Tactic.simpLemma)) := do
  return #[← `(Parser.Tactic.simpLemma| $enc:ident), ← `(Parser.Tactic.simpLemma| $dec:ident),
        ← `(Parser.Tactic.simpLemma| Espal.field), ← `(Parser.Tactic.simpLemma| Espal.optField),
        ← `(Parser.Tactic.simpLemma| Espal.tagOf)] ++
      (← proofs.mapM fun p => `(Parser.Tactic.simpLemma| ↓ $p:term))

/--
Checks a structure's data fields, plans which parameters take codecs, and says how each data
field contains the structure, if it does.
-/
meta def planStructure (declName : Name) (data proofs : Array Name) :
    MetaM (Array (Nat × Bool) × Array FieldKind) :=
  withParams declName fun params type =>
    withLocalDeclD `self type fun self => do
      for f in proofs do
        checkDecidable declName f (← inferType (← mkProjection self f))
      let typed ←
        data.mapM fun f => do
            let type ← inferType (← mkProjection self f)
            if mentions self type then
              refuse declName m!"the type of {f} depends on another field"
            return (f, type)
      checkKeys declName #[] typed
      let kinds ← typed.mapM fun (f, type) => fieldKind declName params f type
      let plain := (typed.zip kinds).filterMap fun (t, k) => if k.isPlain then some t else none
      return (← planParams declName params plain, kinds)

open TSyntax.Compat in
/-- The commands for a structure's codec, in the order they run. -/
meta def structureCommands (declName : Name) (data proofs : Array Name) (ps : Params) :
    TermElabM (Array Command) := do
  let T := mkCIdent declName
  let ty ← ps.applied T
  let (encB, decB) ← defHeaders ps
  let enc := mkIdent (← mkFreshUserName `encodeJson)
  let dec := mkIdent (← mkFreshUserName `decodeJson)
  let self := mkIdent (← mkFreshUserName `self)
  let pointer := mkIdent (← mkFreshUserName `pointer)
  let fields := mkIdent (← mkFreshUserName `fields)
  let keyed ← data.mapM fun f => return (f, ← fieldKey declName f)
  let mut obj ← `((#[] : Array (String × _root_.Json)))
  for (f, key, optional) in keyed do
    obj ← encodeStep obj key optional (← `(($self).$(mkIdent f):ident))
  let vars ← data.mapM fun f => return mkIdent (← mkFreshUserName f)
  let hyps ← proofs.mapM fun f => return mkIdent (← mkFreshUserName f)
  let reads ←
    keyed.mapM fun (f, key, optional) => do
        readField pointer fields key optional (← `(espal_json_field_type% $ty $(mkIdent f)))
  let props ← proofs.mapM fun f => `(espal_json_field_type% $ty $(mkIdent f) $vars*)
  let names := (data ++ proofs).map mkIdent
  let values := vars ++ hyps
  let value ← `({ $[$names:ident := $values],* })
  let body ←
    decodeObject pointer fields (keyed.map (·.2.1)) reads vars (proofs.zip (hyps.zip props)).toList
      value
  let simpArgs ← simpArgs enc dec (← proofs.mapM fun f => `(($self).$(mkIdent f):ident))
  let missing := quote "expected an object"
  return #[
    ← `(def $enc $encB:bracketedBinder* ($self : $ty) : _root_.Json := _root_.Json.obj $obj),
    ← `(def $dec $decB:bracketedBinder* ($pointer : List String) :
          _root_.Json → Except (Array Espal.DecodeError) $ty
        | .obj $fields => $body
        | _ => .error #[⟨$pointer, $missing⟩])] ++
    (← instanceCmds ps T enc (← `(⟨$dec⟩))
        (← `(⟨fun $pointer $self => by
              show $dec $pointer ($enc $self) = .ok $self
              simp [$simpArgs,*]⟩))
        (← `(⟨fun _ => nofun⟩)))

/-- The JSON name of a constructor. -/
meta def ctorTag (declName : Name) (ctor : Name) : MetaM String := do
  let .str _ s := ctor | refuse declName m!"can't name a tag after the constructor {ctor}"
  return s

open TSyntax.Compat in
/-- The commands for the codec of an inductive type whose constructors take no arguments. -/
meta def enumCommands (declName : Name) (ctors : List Name) : TermElabM (Array Command) := do
  let ps ← Params.make declName #[]
  let T := mkCIdent declName
  let ty ← ps.applied T
  let (encB, decB) ← defHeaders ps
  let enc := mkIdent (← mkFreshUserName `encodeJson)
  let dec := mkIdent (← mkFreshUserName `decodeJson)
  let pointer := mkIdent (← mkFreshUserName `pointer)
  let tag := mkIdent (← mkFreshUserName `tag)
  let x := mkIdent (← mkFreshUserName `x)
  let tags ← ctors.mapM fun c => return (c, ← ctorTag declName c)
  let encAlts ←
    tags.toArray.mapM fun (c, s) =>
        `(Lean.Parser.Term.matchAltExpr| | $(mkCIdent c):ident => _root_.Json.str $(quote s))
  let expected := quote s!"expected one of {", ".intercalate (tags.map (·.2))}"
  let unknown ← `(Except.error #[⟨$pointer, $expected⟩])
  let chain ←
    tags.foldrM (init := unknown) fun (c, s) rest =>
        `(if $tag == $(quote s) then Except.ok $(mkCIdent c) else $rest)
  let wrongType := quote "expected a string"
  return #[
    ← `(def $enc $encB:bracketedBinder* : $ty → _root_.Json
        $encAlts:matchAlt*),
    ← `(def $dec $decB:bracketedBinder* ($pointer : List String) :
          _root_.Json → Except (Array Espal.DecodeError) $ty
        | .str $tag => $chain
        | _ => .error #[⟨$pointer, $wrongType⟩])] ++
    (← instanceCmds ps T enc (← `(⟨$dec⟩))
        (← `(⟨fun $pointer $x => by
              show $dec $pointer ($enc $x) = .ok $x
              cases $x:ident <;> simp [$enc:ident, $dec:ident]⟩))
        (← `(⟨fun $x => by cases $x:ident <;> nofun⟩)))

/--
A constructor's arguments, each with whether it is a proof, and the name and type of each data
argument. Refuses an argument the handler can't name.
-/
meta def ctorArgs (declName : Name) (params : Array Expr) (ctor : Name) :
    MetaM (Array (Name × Bool) × Array (Name × Expr)) := do
  let info ← getConstInfoCtor ctor
  forallTelescopeReducing (← instantiateForall info.type params) fun xs _ => do
      let mut args := #[]
      let mut data := #[]
      let proofs ← xs.filterM fun x => return ← isProp (← inferType x)
      for x in xs do
        let name := (← getFVarLocalDecl x).userName
        if name.hasMacroScopes then
          refuse declName
              m!"an argument of {.ofConstName ctor} has no name to use as its key. Name it, as in `circle (radius : Small)`"
        let type ← inferType x
        let proof ← isProp type
        if proof then
          if proofs.any (mentions · type) then
            refuse declName m!"the check {name} depends on another check"
          checkDecidable declName name type
        else
          if xs.any (mentions · type) then
            refuse declName m!"the type of {name} depends on another argument"
          data := data.push (name, type)
        args := args.push (name, proof)
      checkKeys declName #["kind"] data
      return (args, data)

/-- One constructor's piece of a tagged codec. -/
structure TaggedCtor where
  /-- How the encoder writes this constructor. -/
  encAlt : TSyntax ``Lean.Parser.Term.matchAlt
  /-- How the round-trip proof handles this constructor. -/
  proofAlt : TSyntax ``Lean.Parser.Term.matchAlt
  /-- The tag, and the decoder for an object with that tag. -/
  decode : String × Term

open TSyntax.Compat in
/-- What one constructor adds to the encoder, the decoder and the proof. -/
meta def taggedCtor (declName : Name) (ps : Params) (enc dec pointer fields : Ident)
    (c : Name) (args : Array (Name × Bool)) : TermElabM TaggedCtor := do
  let s ← ctorTag declName c
  let C := mkCIdent c
  let paramIdents := ps.idents
  let ctorApp ← `(@$C:ident $paramIdents*)
  let holes ← ps.idents.mapM fun _ => `(_)
  let idents ← args.mapM fun (name, _) => return mkIdent (← mkFreshUserName name)
  let decoded ← args.mapM fun (name, _) => return mkIdent (← mkFreshUserName name)
  let mut encPats : Array Term := holes
  let mut obj ← `(Espal.pushTag (#[] : Array (String × _root_.Json)) $(quote s))
  let mut keys := #["kind"]
  let mut reads := #[]
  let mut vars := #[]
  let mut proofs : Array (Name × Ident × Nat) := #[]
  let mut proofIdents : Array Term := #[]
  for ((name, proof), a, v, i) in args.zip (idents.zip (decoded.zip (Array.range args.size))) do
    if proof then
      -- The encoder ignores proofs, so its pattern names only the data.
      encPats := encPats.push (← `(_))
      proofIdents := proofIdents.push a
      proofs := proofs.push (name, v, i)
    else
      let (key, optional) ← fieldKey declName name
      encPats := encPats.push a
      obj ← encodeStep obj key optional a
      keys := keys.push key
      reads := reads.push (← readField pointer fields key optional
        (← `(espal_json_arg_type% $ctorApp $(quote i))))
      vars := vars.push v
  let checks ←
    proofs.mapM fun (name, v, i) => do
        return (name, v, ← `(espal_json_arg_type% $ctorApp $(quote i) $vars*))
  let proofPats : Array Term := holes ++ idents.map (·)
  let pattern ← `(@$C:ident $proofPats*)
  let simpArgs ← simpArgs enc dec proofIdents
  return {
    encAlt := ← `(Lean.Parser.Term.matchAltExpr| | @$C:ident $encPats* => _root_.Json.obj $obj)
    proofAlt := ← `(Lean.Parser.Term.matchAltExpr|
      | @$C:ident $proofPats* => by
        show $dec $pointer ($enc $pattern) = .ok $pattern
        simp [$simpArgs,*])
    decode := (s, ← decodeObject pointer fields keys reads vars checks.toList
      (← `($ctorApp $decoded*))) }

open TSyntax.Compat in
/-- The commands for the codec of an inductive type whose values become tagged objects. -/
meta def taggedCommands (declName : Name) (shapes : Array (Name × Array (Name × Bool)))
    (ps : Params) : TermElabM (Array Command) := do
  let T := mkCIdent declName
  let ty ← ps.applied T
  let (encB, decB) ← defHeaders ps
  let enc := mkIdent (← mkFreshUserName `encodeJson)
  let dec := mkIdent (← mkFreshUserName `decodeJson)
  let pointer := mkIdent (← mkFreshUserName `pointer)
  let fields := mkIdent (← mkFreshUserName `fields)
  let tag := mkIdent (← mkFreshUserName `tag)
  let failures := mkIdent (← mkFreshUserName `failures)
  let x := mkIdent (← mkFreshUserName `x)
  let pieces ← shapes.mapM fun (c, args) => taggedCtor declName ps enc dec pointer fields c args
  let expected := quote s!"expected one of {", ".intercalate (pieces.toList.map (·.decode.1))}"
  let unknown ← `(Except.error #[⟨$pointer ++ ["kind"], $expected⟩])
  let chain ←
    pieces.foldrM (init := unknown) fun p rest =>
        `(if $tag == $(quote p.decode.1) then $(p.decode.2) else $rest)
  let missing := quote "expected an object"
  return #[
    ← `(def $enc $encB:bracketedBinder* : $ty → _root_.Json
        $(pieces.map (·.encAlt)):matchAlt*),
    ← `(def $dec $decB:bracketedBinder* ($pointer : List String) :
          _root_.Json → Except (Array Espal.DecodeError) $ty
        | .obj $fields =>
          match Espal.tagOf $pointer $fields with
          | .ok $tag => $chain
          | .error $failures => .error $failures
        | _ => .error #[⟨$pointer, $missing⟩])] ++
    (← instanceCmds ps T enc (← `(⟨$dec⟩))
        (← `(⟨fun $pointer $x => match $x:ident with $(pieces.map (·.proofAlt)):matchAlt*⟩))
        (← `(⟨fun $x => by cases $x:ident <;> nofun⟩)))

/-- A structure, or one constructor, as a recursive codec sees it. -/
structure RecShape where
  /-- The constructor, or `none` for a structure. -/
  ctor? : Option Name
  /-- Each field or argument in the order a pattern lists it, with whether it is a proof. -/
  args : Array (Name × Bool × FieldKind)

/-- Appends one field's value to the object a recursive encoder builds. -/
meta def recEncodeStep (enc : Ident) (acc : Term) (key : String) (optional : Bool)
    (kind : FieldKind) (value : Term) : TermElabM Term :=
  match kind with
  | .plain => encodeStep acc key optional value
  | .direct => `(Espal.pushJson $acc $(quote key) ($enc $value))
  | .array => `(Espal.pushJson $acc $(quote key) (_root_.Json.arr (($value).map $enc)))
  | .list => `(Espal.pushJson $acc $(quote key) (_root_.Json.arr (($value).map $enc).toArray))
  | .option =>
    `(Espal.pushJson $acc $(quote key)
        ((($value).attach.map fun i =>
              have := Espal.sizeOf_lt_of_eq_some i.2;
              $enc i.1).getD
          _root_.Json.null))
  | .optional =>
    `(Espal.pushOptJson $acc $(quote key)
        (($value).attach.map fun i =>
          have := Espal.sizeOf_lt_of_eq_some i.2;
          $enc i.1))

/-- How a recursive decoder reads one data field, with one less count for the type itself. -/
meta def recReadField (dec n pointer fields : Ident) (key : String) (optional : Bool)
    (kind : FieldKind) (type : Term) : TermElabM Term := do
  let lookup ← `(_root_.Json.findLast? $fields $(quote key))
  let here ← `($pointer ++ [$(quote key)])
  let read ←
    match kind with
    | .plain =>
      return ← readField pointer fields key optional type
    | .direct =>
      `(Espal.requiredWith ($dec $n) $here $lookup)
    | .array =>
      `(Espal.requiredWith (Espal.arrayWith ($dec $n)) $here $lookup)
    | .list =>
      `(Espal.requiredWith (Espal.listWith ($dec $n)) $here $lookup)
    | .option =>
      `(Espal.requiredWith (Espal.optionWith ($dec $n)) $here $lookup)
    | .optional =>
      `(Espal.optionalWith ($dec $n) $here $lookup)
  `(($read : Except (Array Espal.DecodeError) $type))

/--
The round-trip fact for one recursive field, from the count one level down, and the simp lemma
that uses it. `h` bounds the depth of the encoded value that holds the field.
-/
meta def recFact (decEnc dec enc encNN n h : Ident) (key : String) (kind : FieldKind) (a : Ident) :
    TermElabM (Option (TSyntax `tactic × Term)) := do
  let hv := mkIdent (← mkFreshUserName `hv)
  let k := quote key
  match kind with
  | .plain =>
    return none
  | .direct =>
    return some
        (←
            `(tactic|
                have $hv:ident := fun q =>
                  $decEnc $n $a q (Espal.depth_lt_of_field (k := $k) $h (by simp))),
          ← `($hv))
  | .array =>
    return some
        (←
            `(tactic|
                have $hv:ident : ∀ x ∈ $a, ∀ q, $dec $n q ($enc x) = .ok x := fun x hx q =>
                  $decEnc $n x q
                    (Espal.depth_lt_of_mem_array (Espal.depth_lt_of_field (k := $k) $h (by simp))
                      hx)),
          ← `(Espal.arrayWith_map _ _ _ $hv))
  | .list =>
    return some
        (←
            `(tactic|
                have $hv:ident : ∀ x ∈ $a, ∀ q, $dec $n q ($enc x) = .ok x := fun x hx q =>
                  $decEnc $n x q
                    (Espal.depth_lt_of_mem_list (Espal.depth_lt_of_field (k := $k) $h (by simp))
                      hx)),
          ← `(Espal.listWith_map _ _ _ $hv))
  | .option =>
    return some
        (←
            `(tactic|
                have $hv:ident : ∀ x, $a = some x → ∀ q, $dec $n q ($enc x) = .ok x := fun x hx q =>
                  $decEnc $n x q
                    (Espal.depth_lt_of_eq_some (Espal.depth_lt_of_field (k := $k) $h (by simp))
                      hx)),
          ← `(Espal.optionWith_map _ _ _ $hv $encNN))
  | .optional =>
    return some
        (←
            `(tactic|
                have $hv:ident : ∀ x, $a = some x → ∀ q, $dec $n q ($enc x) = .ok x := fun x hx q =>
                  $decEnc $n x q (Espal.depth_lt_of_field (k := $k) $h (by simp [hx]))),
          ← `(Espal.optionalWith_map _ _ _ $hv $encNN))

/--
What one shape adds to a recursive codec, as alternatives of the encoder, the decoder and the
proof.
-/
structure RecPieces where
  /-- How the encoder writes this shape. -/
  encAlt : TSyntax ``Lean.Parser.Term.matchAlt
  /-- How the round-trip proof handles this shape. -/
  proofAlt : TSyntax ``Lean.Parser.Term.matchAlt
  /-- The tag, if the codec is tagged, and the decoder for an object of this shape. -/
  decode : String × Term

open TSyntax.Compat in
/-- What one shape adds to a recursive codec. -/
meta def recPieces (declName : Name) (ps : Params) (ty : Term)
    (enc dec decEnc encNN pointer fields n p h : Ident) (tagged : Bool) (shape : RecShape) :
    TermElabM RecPieces := do
  let holes ← ps.idents.mapM fun _ => `(_)
  let paramIdents := ps.idents
  let build (terms : Array Term) (asPattern : Bool) : TermElabM Term := do
    match shape.ctor? with
    | some c =>
      let C := mkCIdent c
      if asPattern then `(@$C:ident $holes* $terms*) else `(@$C:ident $paramIdents* $terms*)
    | none =>
      let names := shape.args.map fun (name, _) => mkIdent name
      `({ $[$names:ident := $terms],* })
  let argType (name : Name) (i : Nat) (vars : Array Ident) : TermElabM Term :=
    match shape.ctor? with
    | some c => `(espal_json_arg_type% (@$(mkCIdent c):ident $paramIdents*) $(quote i) $vars*)
    | none => `(espal_json_field_type% $ty $(mkIdent name) $vars*)
  let s ← match shape.ctor? with
    | some c => ctorTag declName c
    | none => pure ""
  let idents ← shape.args.mapM fun (name, _) => return mkIdent (← mkFreshUserName name)
  let decoded ← shape.args.mapM fun (name, _) => return mkIdent (← mkFreshUserName name)
  let mut encPats : Array Term := #[]
  let mut obj ←
    if tagged then `(Espal.pushTag (#[] : Array (String × _root_.Json)) $(quote s))
    else `((#[] : Array (String × _root_.Json)))
  let mut keys := if tagged then #["kind"] else #[]
  let mut reads := #[]
  let mut vars := #[]
  let mut proofs : Array (Name × Ident × Nat) := #[]
  let mut proofIdents : Array Term := #[]
  let mut facts : Array (TSyntax `tactic) := #[]
  let mut lemmas : Array Term := #[]
  for ((name, proof, kind), a, v, i) in
      shape.args.zip (idents.zip (decoded.zip (Array.range shape.args.size))) do
    if proof then
      encPats := encPats.push (← `(_))
      proofIdents := proofIdents.push a
      proofs := proofs.push (name, v, i)
    else
      let (key, optional) ← fieldKey declName name
      encPats := encPats.push a
      obj ← recEncodeStep enc obj key optional kind a
      keys := keys.push key
      reads := reads.push (← recReadField dec n pointer fields key optional kind
        (← argType name i #[]))
      vars := vars.push v
      if let some (fact, lemma) := (← recFact decEnc dec enc encNN n h key kind a) then
        facts := facts.push fact
        lemmas := lemmas.push lemma
  let checks ←
    proofs.mapM fun (name, v, i) => do
        return (name, v, ← argType name i vars)
  let pattern ← build (idents.map (·)) true
  let value ← build (decoded.map (·)) false
  let simpArgs := (← simpArgs enc dec proofIdents) ++
    (← lemmas.mapM fun l => `(Parser.Tactic.simpLemma| $l:term))
  let unfold ← `(tactic| simp only [$enc:ident, Option.attach_map_val] at $h:ident ⊢)
  let finish ← `(tactic| simp [$simpArgs,*])
  let tactics := #[unfold] ++ facts ++ #[finish]
  return {
    encAlt := ← `(Lean.Parser.Term.matchAltExpr| | $(← build encPats true) => _root_.Json.obj $obj)
    proofAlt := ← `(Lean.Parser.Term.matchAltExpr|
      | $n + 1, $pattern, $p, $h => by $[$tactics]*)
    decode := (s, ← decodeObject pointer fields keys reads vars checks.toList value) }

open TSyntax.Compat in
/--
The commands for a recursive codec. The decoder counts down from the depth of its input, and the
proof is by induction on that count.
-/
meta def recursiveCommands (declName : Name) (ps : Params) (tagged : Bool)
    (shapes : Array RecShape) : TermElabM (Array Command) := do
  let T := mkCIdent declName
  let ty ← ps.applied T
  let (encB, decB) ← defHeaders ps
  let lawB ← ps.binders #[``Json.ToJson, ``JsonDecode, ``LawfulDecode] true
  let enc := mkIdent (← mkFreshUserName `encodeJson)
  let dec := mkIdent (← mkFreshUserName `decodeJson)
  let decEnc := mkIdent (← mkFreshUserName `decodeJson_encodeJson)
  let encNN := mkIdent (← mkFreshUserName `encodeJson_ne_null)
  let pointer := mkIdent (← mkFreshUserName `pointer)
  let fields := mkIdent (← mkFreshUserName `fields)
  let tag := mkIdent (← mkFreshUserName `tag)
  let failures := mkIdent (← mkFreshUserName `failures)
  let n := mkIdent (← mkFreshUserName `n)
  let p := mkIdent (← mkFreshUserName `p)
  let h := mkIdent (← mkFreshUserName `h)
  let j := mkIdent (← mkFreshUserName `j)
  let x := mkIdent (← mkFreshUserName `x)
  let pieces ← shapes.mapM (recPieces declName ps ty enc dec decEnc encNN pointer fields n p h tagged)
  let body ←
    if tagged then do
      let expected := quote s!"expected one of {", ".intercalate (pieces.toList.map (·.decode.1))}"
      let unknown ← `(Except.error #[⟨$pointer ++ ["kind"], $expected⟩])
      let chain ←
        pieces.foldrM (init := unknown) fun piece rest =>
            `(if $tag == $(quote piece.decode.1) then $(piece.decode.2) else $rest)
      `(match Espal.tagOf $pointer $fields with
        | .ok $tag => $chain
        | .error $failures => .error $failures)
    else
      match pieces[0]? with
      | some piece => pure piece.decode.2
      | none => refuse declName "a structure has one shape"
  let missing := quote "expected an object"
  let deep := quote "nested too deeply"
  return #[
    ← `(def $enc $encB:bracketedBinder* : $ty → _root_.Json
        $(pieces.map (·.encAlt)):matchAlt*),
    ← `(def $dec $decB:bracketedBinder* :
          Nat → List String → _root_.Json → Except (Array Espal.DecodeError) $ty
        | 0, $pointer, _ => .error #[⟨$pointer, $deep⟩]
        | $n + 1, $pointer, .obj $fields => $body
        | _ + 1, $pointer, _ => .error #[⟨$pointer, $missing⟩]),
    ← `(theorem $encNN $encB:bracketedBinder* ($x : $ty) : $enc $x ≠ _root_.Json.null := by
        unfold $enc:ident
        split <;> simp),
    ← `(set_option linter.unusedSimpArgs false in
        theorem $decEnc $lawB:bracketedBinder* :
            ∀ (n : Nat) (x : $ty) (p : List String),
              (_root_.Json.depth ($enc x)) < n → $dec n p ($enc x) = .ok x
          | 0, _, _, $h => absurd $h (Nat.not_lt_zero _)
          $(pieces.map (·.proofAlt)):matchAlt*)] ++
    (← instanceCmds ps T enc
        (← `(⟨fun $pointer $j => $dec (_root_.Json.depth $j + 1) $pointer $j⟩))
        (← `(⟨fun $pointer $x => $decEnc _ $x $pointer (Nat.lt_succ_self _)⟩))
        (← `(⟨$encNN⟩)))

/-- The commands for the derived codec, in the order they run. -/
meta def mkCommands (declName : Name) : TermElabM (Array Command) := do
  let info ← getConstInfoInduct declName
  unless info.numIndices == 0 do
    refuse declName "the handler can't yet take a type with indices"
  unless info.all.length == 1 do
    refuse declName "the handler can't yet take mutually inductive types"
  if isStructure (← getEnv) declName then
    let (data, proofs) ← splitFields declName
    let (plan, kinds) ← planStructure declName data proofs
    let ps ← Params.make declName plan
    if kinds.all (·.isPlain) then
      structureCommands declName data proofs ps
    else
      let args :=
        (data.zip kinds).map (fun (f, k) => (f, false, k)) ++
          proofs.map fun f => (f, true, FieldKind.plain)
      recursiveCommands declName ps false #[{ ctor? := none, args }]
  else if info.ctors.isEmpty then
    refuse declName "it has no constructors, so no value has an encoding"
  else if ← info.ctors.allM fun c => return (← getConstInfoCtor c).numFields == 0 then
    enumCommands declName info.ctors
  else
    let (shapes, plan) ←
      withParams declName fun params _ => do
          let shapes ←
            info.ctors.toArray.mapM fun c => do
                let (args, data) ← ctorArgs declName params c
                let kinds ←
                  data.mapM fun (f, type) => return (f, ← fieldKind declName params f type)
                return (c, args, data, kinds)
          let plain :=
            shapes.flatMap fun (_, _, data, kinds) =>
              (data.zip kinds).filterMap fun (t, (_, k)) => if k.isPlain then some t else none
          return (shapes, ← planParams declName params plain)
    let ps ← Params.make declName plan
    if shapes.all fun (_, _, _, kinds) => kinds.all (·.2.isPlain) then
      taggedCommands declName (shapes.map fun (c, args, _, _) => (c, args)) ps
    else
      let recShapes :=
        shapes.map fun (c, args, _, kinds) =>
          { ctor? := some c
            args :=
              args.map fun (name, proof) =>
                (name, proof, ((kinds.find? (·.1 == name)).map (·.2)).getD .plain) :
            RecShape }
      recursiveCommands declName ps true recShapes

/-- Handles `deriving Json` for one type. -/
meta def jsonHandler (declNames : Array Name) : CommandElabM Bool := do
  let #[declName] := declNames | return false
  (← liftTermElabM <| mkCommands declName).forM elabCommand
  return true

meta initialize
  registerDerivingHandler ``_root_.Json jsonHandler

end Espal.Deriving
