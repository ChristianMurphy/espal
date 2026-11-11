/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalJson.Reply
public meta import Lean.Elab.Deriving.Basic

/-!
# `deriving Problem`

`deriving instance Problem for E` writes the `ToReply` instance of an inductive type of errors.
Each constructor answers as an RFC 9457 problem. Its status comes from its name when the name is
one of a few well-known ones, such as `notFound`. Any other constructor needs
`attribute [status 409] E.closed` before the `deriving instance` line, since Lean takes no
attribute on a constructor where the type is declared. Its type and title come from its name,
so `tooLate` has the type `/problems/too-late` and the title "Too late". Each argument becomes a
member of the problem under the argument's name, so it needs a name and a JSON encoder.
-/

public section

namespace Espal

open Json

/-- The reply for a problem with the given status, type, title and extra members. -/
@[expose]
def problemReply (status : UInt16) (type title : String) (members : Array (String × Json)) :
    Reply :=
  ⟨status, "application/problem+json",
    (compress
        (.obj
          (#[("type", .str type), ("title", .str title),
              ("status", .num (Number.ofNat status.toNat))] ++
            members))).toUTF8,
    []⟩

/-- `attribute [status n] E.c` sets the HTTP status that `deriving instance Problem for E` answers
the constructor `E.c` with. -/
syntax (name := statusAttr) &"status " num : attr

namespace Deriving

open Lean Elab Command Term Meta

/-- The status each constructor was given with `@[status n]`. -/
meta initialize statusExt : ParametricAttribute Nat ←
  registerParametricAttribute
      { name := `statusAttr
        descr := "the HTTP status of an error constructor, for `deriving Problem`"
        getParam := fun _ stx =>
          match stx with
          | `(attr| status $n:num) => pure n.getNat
          | _ => throwError "expected `status n`, with `n` a status code" }

/-- Stops the derivation with a reason. -/
meta def refuseProblem {α : Type} (declName : Name) (reason : MessageData) : MetaM α :=
  throwError m!"cannot derive Problem for {.ofConstName declName}: {reason}"

/-- The status of a constructor that needs no `@[status n]`, by its name. -/
meta def knownStatus : String → Option Nat
  | "badRequest" => some 400
  | "unauthorized" => some 401
  | "forbidden" => some 403
  | "notFound" => some 404
  | "conflict" => some 409
  | "gone" => some 410
  | "tooManyRequests" => some 429
  | _ => none

/-- The words of a camel-case name, in lower case. -/
meta def nameWords (s : String) : List String :=
  let step (acc : List String × String) (c : Char) : List String × String :=
    if c.isUpper && !acc.2.isEmpty then (acc.2 :: acc.1, (String.singleton c).toLower)
    else (acc.1, acc.2.push c.toLower)
  let (done, last) := s.foldl step ([], "")
  (last :: done).reverse.filter (!·.isEmpty)

/-- One constructor's arm of the derived `toReply`. -/
meta def problemAlt (declName : Name) (ctor : Name) : TermElabM (TSyntax ``Parser.Term.matchAlt) :=
  do
  let .str _ short := ctor | refuseProblem declName m!"can't name a problem after {ctor}"
  let status ←
    match statusExt.getParam? (← getEnv) ctor, knownStatus short with
    | some n, _ =>
      pure n
    | none, some n =>
      pure n
    | none, none =>
      refuseProblem declName
          m!"the constructor {short} has no status. Add `attribute [status 409] {privateToUserName ctor}` before deriving"
  unless 400 ≤ status && status ≤ 599 do
    refuseProblem declName m!"the constructor {short} has status {status}, which is no error status"
  let words := nameWords short
  let type := "/problems/" ++ "-".intercalate words
  let title := (" ".intercalate words).capitalize
  let info ← getConstInfoCtor ctor
  let args ←
    forallTelescopeReducing info.type fun xs _ =>
        xs.mapM fun x => do
          let decl ← getFVarLocalDecl x
          let name := decl.userName
          if name.hasMacroScopes then
            refuseProblem declName
                m!"an argument of {short} has no name to use as its key. Name it, as in `{short} (reason : String)`"
          let key := name.toString
          if ["type", "title", "status"].contains key then
            refuseProblem declName m!"the argument {key} of {short} uses a key every problem has"
          let goal ← mkAppM ``Json.ToJson #[decl.type]
          if (← trySynthInstance goal) matches .none then
            refuseProblem declName
                m!"the argument {key} of {short} has type {decl.type}, which has no ToJson instance"
          return key
  let idents ← args.mapM fun key => return mkIdent (← mkFreshUserName (Name.mkSimple key))
  let members ←
    (args.zip idents).mapM fun (key, a) => `(($(quote key), _root_.Json.ToJson.toJson $a))
  `(Parser.Term.matchAltExpr|
    | @$(mkCIdent ctor):ident $idents* =>
      Espal.problemReply $(quote status) $(quote type) $(quote title) #[$members,*])

/-- Handles `deriving Problem` for one inductive type of errors. -/
meta def problemHandler (declNames : Array Name) : CommandElabM Bool := do
  let #[declName] := declNames | return false
  let cmd ←
    liftTermElabM do
        let info ← getConstInfoInduct declName
        unless info.numParams == 0 && info.numIndices == 0 do
          refuseProblem declName "the handler can't yet take a type with parameters or indices"
        if info.ctors.isEmpty then
          refuseProblem declName "it has no constructors, so no error has a reply"
        let alts ← info.ctors.toArray.mapM (problemAlt declName)
        `(
instance : Espal.ToReply $(mkCIdent declName) :=
⟨fun
  $alts:matchAlt*⟩)
  elabCommand cmd
  return true

meta initialize
  registerDerivingHandler ``Espal.Problem problemHandler

end Deriving

end Espal
