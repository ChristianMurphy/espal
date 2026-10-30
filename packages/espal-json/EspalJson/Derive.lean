/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalJson.Object
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
`NotNullJson`. The handler can't yet take a type with parameters or indices, or one that contains
itself.
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

/-- A structure's fields, data first and then proofs, each in declaration order. -/
meta def splitFields (declName : Name) : MetaM (Array Name × Array Name) := do
  let fields := getStructureFieldsFlattened (← getEnv) declName (includeSubobjectFields := false)
  withLocalDeclD `self (mkConst declName) fun self => do
      let mut data := #[]
      let mut proofs := #[]
      for f in fields do
        if ← isProp (← inferType (← mkProjection self f)) then
          proofs := proofs.push f
        else
          data := data.push f
      return (data, proofs)

/--
`espal_json_field_type% S f a₁ … aₙ` is the type of the field `f` of `S`, with the data fields of
`S` replaced by `a₁ … aₙ` in order. The derived decoder states each proof field's proposition
with it, in terms of the values it decoded.
-/
syntax (name := fieldTypeStx) "espal_json_field_type% " ident ident (ppSpace colGt term:max)* : term

/-- Turns `espal_json_field_type%` into the type it names. -/
@[term_elab fieldTypeStx]
meta def elabFieldType : TermElab := fun stx _ => do
  match stx with
  | `(espal_json_field_type% $struct:ident $field:ident $args*) =>
    let declName ← realizeGlobalConstNoOverloadWithInfo struct
    let (data, _) ← splitFields declName
    let args ← args.mapM (elabTerm · none)
    withLocalDeclD `self (mkConst declName) fun self => do
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
`espal_json_arg_type% C i a₁ … aₙ` is the type of argument `i` of the constructor `C`. Given
values for every data argument of `C`, in order, it puts them in place of those arguments.
-/
syntax (name := argTypeStx) "espal_json_arg_type% " ident num (ppSpace colGt term:max)* : term

/-- Turns `espal_json_arg_type%` into the type it names. -/
@[term_elab argTypeStx]
meta def elabArgType : TermElab := fun stx _ => do
  match stx with
  | `(espal_json_arg_type% $ctor:ident $i:num $args*) =>
    let ctorName ← realizeGlobalConstNoOverloadWithInfo ctor
    let info ← getConstInfoCtor ctorName
    let args ← args.mapM (elabTerm · none)
    forallTelescopeReducing info.type fun xs _ => do
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

/--
Refuses a data field the handler can't prove a round trip for. `reserved` holds the keys the
encoding itself uses.
-/
meta def checkData (declName : Name) (reserved : Array String) (data : Array (Name × Expr)) :
    MetaM Unit := do
  let mut keys := reserved
  for (f, type) in data do
    let (key, optional) ← fieldKey declName f
    if reserved.contains key then
      refuse declName m!"the field {f} uses the key {key}, which names the constructor"
    if keys.contains key then
      refuse declName m!"two fields use the key {key}"
    keys := keys.push key
    if (type.find? (·.isConstOf declName)).isSome then
      refuse declName "the handler can't yet take a type that contains itself"
    let inner ←
      if optional then
        match (← whnfR type).app1? ``Option with
        | some inner =>
          pure inner
        | none =>
          refuse declName m!"the optional field {f} needs an Option type, not {type}"
      else
        pure type
    for cls in (if optional then [``LawfulDecode, ``NotNullJson] else [``LawfulDecode]) do
      unless ← hasInstance cls inner do
        refuse declName m!"the field {f} has type {inner}, which has no {.ofConstName cls} instance"

/-- Refuses a structure field the handler can't prove a round trip for. -/
meta def checkStructure (declName : Name) (data : Array Name) : MetaM Unit := do
  withLocalDeclD `self (mkConst declName) fun self => do
      let typed ←
        data.mapM fun f => do
            let type ← inferType (← mkProjection self f)
            if mentions self type then
              refuse declName m!"the type of {f} depends on another field"
            return (f, type)
      checkData declName #[] typed

/--
A constructor's arguments, each with whether it is a proof. Refuses an argument the handler can't
name or prove a round trip for.
-/
meta def ctorArgs (declName : Name) (ctor : Name) : MetaM (Array (Name × Bool)) := do
  let info ← getConstInfoCtor ctor
  forallTelescopeReducing info.type fun xs _ => do
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
        else
          if xs.any (mentions · type) then
            refuse declName m!"the type of {name} depends on another argument"
          data := data.push (name, type)
        args := args.push (name, proof)
      checkData declName #["kind"] data
      return args

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

/-- The instances that every derived codec ends with. -/
meta def instanceCmds (T enc dec : Ident) (lawful notNull : Term) : TermElabM (Array Command) :=
  return #[
    ← `(instance : _root_.Json.ToJson $T := ⟨$enc⟩),
    ← `(instance : Espal.JsonDecode $T := ⟨$dec⟩),
    ← `(set_option linter.unusedSimpArgs false in
        instance : Espal.LawfulDecode $T := $lawful),
    ← `(instance : Espal.NotNullJson $T := $notNull),
    ← `(instance : _root_.Json.FromJson $T := Espal.JsonDecode.toFromJson $T),
    ← `(instance : Espal.LawfulJson $T := Espal.JsonDecode.lawfulJson $T)]

/-- The simp set of every derived round-trip proof, with the proofs to decide checks by. -/
meta def simpArgs (enc dec : Ident) (proofs : Array Term) :
    TermElabM (Array (TSyntax ``Parser.Tactic.simpLemma)) := do
  return #[← `(Parser.Tactic.simpLemma| $enc:ident), ← `(Parser.Tactic.simpLemma| $dec:ident),
        ← `(Parser.Tactic.simpLemma| Espal.field), ← `(Parser.Tactic.simpLemma| Espal.optField),
        ← `(Parser.Tactic.simpLemma| Espal.tagOf)] ++
      (← proofs.mapM fun p => `(Parser.Tactic.simpLemma| ↓ $p:term))

open TSyntax.Compat in
/-- The commands for a structure's codec, in the order they run. -/
meta def structureCommands (declName : Name) : TermElabM (Array Command) := do
  let (data, proofs) ← splitFields declName
  checkStructure declName data
  let T := mkCIdent declName
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
        readField pointer fields key optional (← `(espal_json_field_type% $T $(mkIdent f)))
  let props ← proofs.mapM fun f => `(espal_json_field_type% $T $(mkIdent f) $vars*)
  let names := (data ++ proofs).map mkIdent
  let values := vars ++ hyps
  let value ← `({ $[$names:ident := $values],* })
  let body ←
    decodeObject pointer fields (keyed.map (·.2.1)) reads vars (proofs.zip (hyps.zip props)).toList
      value
  let simpArgs ← simpArgs enc dec (← proofs.mapM fun f => `(($self).$(mkIdent f):ident))
  let missing := quote "expected an object"
  return #[
    ← `(def $enc ($self : $T) : _root_.Json := _root_.Json.obj $obj),
    ← `(def $dec ($pointer : List String) : _root_.Json → Except (Array Espal.DecodeError) $T
        | .obj $fields => $body
        | _ => .error #[⟨$pointer, $missing⟩])] ++
    (← instanceCmds T enc dec
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
  let T := mkCIdent declName
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
    ← `(def $enc : $T → _root_.Json
        $encAlts:matchAlt*),
    ← `(def $dec ($pointer : List String) : _root_.Json → Except (Array Espal.DecodeError) $T
        | .str $tag => $chain
        | _ => .error #[⟨$pointer, $wrongType⟩])] ++
    (← instanceCmds T enc dec
        (← `(⟨fun $pointer $x => by
              show $dec $pointer ($enc $x) = .ok $x
              cases $x:ident <;> simp [$enc:ident, $dec:ident]⟩))
        (← `(⟨fun $x => by cases $x:ident <;> nofun⟩)))

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
meta def taggedCtor (declName : Name) (enc dec pointer fields : Ident) (c : Name) :
    TermElabM TaggedCtor := do
  let args ← ctorArgs declName c
  let s ← ctorTag declName c
  let C := mkCIdent c
  let idents ← args.mapM fun (name, _) => return mkIdent (← mkFreshUserName name)
  let decoded ← args.mapM fun (name, _) => return mkIdent (← mkFreshUserName name)
  let mut encPats : Array Term := #[]
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
        (← `(espal_json_arg_type% $C $(quote i))))
      vars := vars.push v
  let checks ←
    proofs.mapM fun (name, v, i) => do
        return (name, v, ← `(espal_json_arg_type% $C $(quote i) $vars*))
  let pattern ← `(@$C:ident $idents*)
  let simpArgs ← simpArgs enc dec proofIdents
  return {
    encAlt := ← `(Lean.Parser.Term.matchAltExpr| | @$C:ident $encPats* => _root_.Json.obj $obj)
    proofAlt := ← `(Lean.Parser.Term.matchAltExpr|
      | @$C:ident $idents* => by
        show $dec $pointer ($enc $pattern) = .ok $pattern
        simp [$simpArgs,*])
    decode := (s, ← decodeObject pointer fields keys reads vars checks.toList
      (← `(@$C:ident $decoded*))) }

open TSyntax.Compat in
/-- The commands for the codec of an inductive type whose values become tagged objects. -/
meta def taggedCommands (declName : Name) (ctors : List Name) : TermElabM (Array Command) := do
  let T := mkCIdent declName
  let enc := mkIdent (← mkFreshUserName `encodeJson)
  let dec := mkIdent (← mkFreshUserName `decodeJson)
  let pointer := mkIdent (← mkFreshUserName `pointer)
  let fields := mkIdent (← mkFreshUserName `fields)
  let tag := mkIdent (← mkFreshUserName `tag)
  let failures := mkIdent (← mkFreshUserName `failures)
  let x := mkIdent (← mkFreshUserName `x)
  let pieces ← ctors.toArray.mapM (taggedCtor declName enc dec pointer fields)
  let expected := quote s!"expected one of {", ".intercalate (pieces.toList.map (·.decode.1))}"
  let unknown ← `(Except.error #[⟨$pointer ++ ["kind"], $expected⟩])
  let chain ←
    pieces.foldrM (init := unknown) fun p rest =>
        `(if $tag == $(quote p.decode.1) then $(p.decode.2) else $rest)
  let missing := quote "expected an object"
  return #[
    ← `(def $enc : $T → _root_.Json
        $(pieces.map (·.encAlt)):matchAlt*),
    ← `(def $dec ($pointer : List String) : _root_.Json → Except (Array Espal.DecodeError) $T
        | .obj $fields =>
          match Espal.tagOf $pointer $fields with
          | .ok $tag => $chain
          | .error $failures => .error $failures
        | _ => .error #[⟨$pointer, $missing⟩])] ++
    (← instanceCmds T enc dec
        (← `(⟨fun $pointer $x => match $x:ident with $(pieces.map (·.proofAlt)):matchAlt*⟩))
        (← `(⟨fun $x => by cases $x:ident <;> nofun⟩)))

/-- The commands for the derived codec, in the order they run. -/
meta def mkCommands (declName : Name) : TermElabM (Array Command) := do
  let info ← getConstInfoInduct declName
  unless info.numParams == 0 && info.levelParams.isEmpty do
    refuse declName "the handler can't yet take a type with parameters"
  unless info.numIndices == 0 do
    refuse declName "the handler can't yet take a type with indices"
  unless info.all.length == 1 do
    refuse declName "the handler can't yet take mutually inductive types"
  if isStructure (← getEnv) declName then
    structureCommands declName
  else if info.ctors.isEmpty then
    refuse declName "it has no constructors, so no value has an encoding"
  else if ← info.ctors.allM fun c => return (← getConstInfoCtor c).numFields == 0 then
    enumCommands declName info.ctors
  else
    taggedCommands declName info.ctors

/-- Handles `deriving Json` for one type. -/
meta def jsonHandler (declNames : Array Name) : CommandElabM Bool := do
  let #[declName] := declNames | return false
  (← liftTermElabM <| mkCommands declName).forM elabCommand
  return true

meta initialize
  registerDerivingHandler ``_root_.Json jsonHandler

end Espal.Deriving
