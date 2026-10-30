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

`deriving Json` on a structure writes `ToJson`, `JsonDecode` and `FromJson` instances, and proves
`LawfulDecode`, `LawfulJson` and `NotNullJson`. The structure becomes an object with one key per
data field, in declaration order. Optional fields follow the convention in `EspalJson.Object`.

The decoder reads every data field and reports each failure. Once they all decode, it decides
each proof field, such as `ok : lo ≤ hi`, and reports each one that fails by its name. It also
reports every key the structure doesn't have.

Each data field's type needs a `LawfulDecode` instance, and an optional field's type also needs
`NotNullJson`. The handler can't yet take a structure with type parameters, or one that contains
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

/-- Refuses a field the handler can't prove a round trip for. -/
meta def checkStructure (declName : Name) (data : Array Name) : MetaM Unit := do
  withLocalDeclD `self (mkConst declName) fun self => do
      let mut keys : Array String := #[]
      for f in data do
        let (key, optional) ← fieldKey declName f
        if keys.contains key then
          refuse declName m!"two fields use the key {key}"
        keys := keys.push key
        let type ← inferType (← mkProjection self f)
        if mentions self type then
          refuse declName m!"the type of {f} depends on another field"
        if (type.find? (·.isConstOf declName)).isSome then
          refuse declName "the handler can't yet take a structure that contains itself"
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
            refuse declName
                m!"the field {f} has type {inner}, which has no {.ofConstName cls} instance"

/-- Appends one field's value to the object the encoder builds. -/
meta def encodeStep (declName : Name) (self : Ident) (acc : Term) (field : Name) : TermElabM Term :=
  do
  let (key, optional) ← fieldKey declName field
  let access ← `(($self).$(mkIdent field):ident)
  if optional then
    `(Espal.pushOpt $acc $(quote key) $access)
  else
    `(Espal.pushField $acc $(quote key) $access)

/-- Reads every data field, as nested pairs so that one failure doesn't hide another. -/
meta def readAll (declName : Name) (pointer fields : Ident) (data : Array Name)
    (vars : Array Ident) : TermElabM (Term × Term) := do
  let reads ←
    data.mapM fun f => do
        let (key, optional) ← fieldKey declName f
        let type ← `(espal_json_field_type% $(mkCIdent declName) $(mkIdent f))
        if optional then
          `((Espal.optField $pointer $fields $(quote key) : Except (Array Espal.DecodeError) $type))
        else
          `((Espal.field $pointer $fields $(quote key) : Except (Array Espal.DecodeError) $type))
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

open TSyntax.Compat in
/-- The commands for the derived codec, in the order they run. -/
meta def mkCommands (declName : Name) : TermElabM (Array Command) := do
  let info ← getConstInfoInduct declName
  unless info.numParams == 0 && info.levelParams.isEmpty do
    refuse declName "the handler can't yet take a structure with type parameters"
  let (data, proofs) ← splitFields declName
  checkStructure declName data
  let T := mkCIdent declName
  let enc := mkIdent (← mkFreshUserName `encodeJson)
  let dec := mkIdent (← mkFreshUserName `decodeJson)
  let self := mkIdent (← mkFreshUserName `self)
  let pointer := mkIdent (← mkFreshUserName `pointer)
  let fields := mkIdent (← mkFreshUserName `fields)
  let extra := mkIdent (← mkFreshUserName `extra)
  let failures := mkIdent (← mkFreshUserName `failures)
  let mut obj ← `((#[] : Array (String × _root_.Json)))
  for f in data do
    obj ← encodeStep declName self obj f
  let vars ← data.mapM fun f => return mkIdent (← mkFreshUserName f)
  let hyps ← proofs.mapM fun f => return mkIdent (← mkFreshUserName f)
  let keys : Array Term ← data.mapM fun f => return quote (← fieldKey declName f).1
  let (read, pat) ← readAll declName pointer fields data vars
  let props ← proofs.mapM fun f =>
    `(espal_json_field_type% $T $(mkIdent f) $vars*)
  let names := data ++ proofs
  let values := vars ++ hyps
  let done ← `(Espal.finish $extra { $[$(names.map mkIdent):ident := $values],* })
  let body ← decideChecks pointer extra done (proofs.zip (hyps.zip props)).toList
  let simpArgs : Array (TSyntax ``Parser.Tactic.simpLemma) :=
    #[← `(Parser.Tactic.simpLemma| $enc:ident), ← `(Parser.Tactic.simpLemma| $dec:ident),
      ← `(Parser.Tactic.simpLemma| Espal.field), ← `(Parser.Tactic.simpLemma| Espal.optField)] ++
    (← proofs.mapM fun f => `(Parser.Tactic.simpLemma| ↓ ($self).$(mkIdent f):ident))
  let missing := quote "expected an object"
  return #[
    ← `(def $enc ($self : $T) : _root_.Json := _root_.Json.obj $obj),
    ← `(def $dec ($pointer : List String) : _root_.Json → Except (Array Espal.DecodeError) $T
        | .obj $fields =>
          let $extra := Espal.unknownKeys $pointer $fields [$keys,*]
          match $read:term with
          | .ok $pat => $body
          | .error $failures => .error ($failures ++ $extra)
        | _ => .error #[⟨$pointer, $missing⟩]),
    ← `(instance : _root_.Json.ToJson $T := ⟨$enc⟩),
    ← `(instance : Espal.JsonDecode $T := ⟨$dec⟩),
    ← `(set_option linter.unusedSimpArgs false in
        instance : Espal.LawfulDecode $T := ⟨fun $pointer $self => by
          show $dec $pointer ($enc $self) = .ok $self
          simp [$simpArgs,*]⟩),
    ← `(instance : Espal.NotNullJson $T := ⟨fun _ => nofun⟩),
    ← `(instance : _root_.Json.FromJson $T := Espal.JsonDecode.toFromJson $T),
    ← `(instance : Espal.LawfulJson $T := Espal.JsonDecode.lawfulJson $T)]

/-- Handles `deriving Json` for one structure. -/
meta def jsonHandler (declNames : Array Name) : CommandElabM Bool := do
  let #[declName] := declNames | return false
  unless isStructure (← getEnv) declName do
    liftTermElabM <| refuse declName "the handler takes only structures for now"
  (← liftTermElabM <| mkCommands declName).forM elabCommand
  return true

meta initialize
  registerDerivingHandler ``_root_.Json jsonHandler

end Espal.Deriving
