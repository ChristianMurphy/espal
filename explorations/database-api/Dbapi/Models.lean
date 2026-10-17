import Dbapi.Builder
import Lean

/-!
# The `model` command

```
model Student "students" where
  id : Int
  schoolId : Int
  name : String
  belongsTo school : School via schoolId
  hasMany submissions : Submission via studentId
```

generates the structure `Student.Of`, the row type `Student`, its `Model` instance, `find`, `all`
and `insert`, and one function per relation. Relation targets must already exist; `relations`
adds relations after the fact, for cycles such as a school that has many students.
-/

namespace Dbapi
open Lean Elab Command

declare_syntax_cat modelItem
syntax ident " : " ident : modelItem
syntax "belongsTo " ident " : " ident " via " ident : modelItem
syntax "hasMany " ident " : " ident " via " ident : modelItem

syntax "model " ident str " where" (ppLine colGt modelItem)* : command
syntax "relations " ident " where" (ppLine colGt modelItem)* : command

private def snake (s : String) : String :=
  s.foldl (fun acc c => if c.isUpper then acc ++ "_" ++ (c.toLower.toString) else acc.push c) ""

private def capitalize (s : String) : String :=
  match s.toList with
  | [] => s
  | c :: cs => String.ofList (c.toUpper :: cs)

private def sqlTyOf (ty : Ident) : CommandElabM (TSyntax `term) :=
  match ty.getId with
  | `Int => `(Dbapi.SqlTy.int)
  | `String => `(Dbapi.SqlTy.text)
  | `Bool => `(Dbapi.SqlTy.bool)
  | _ => throwErrorAt ty "column type must be Int, String or Bool"

private def colIdx : Nat → CommandElabM (TSyntax `term)
  | 0 => `(Dbapi.Col.here)
  | n + 1 => do `(Dbapi.Col.there $(← colIdx n))

private def elabRelation (mdl : Ident) (item : TSyntax `modelItem) : CommandElabM Unit := do
  let ofId (n : Ident) := mkIdent (n.getId ++ `Of)
  let field (n f : Ident) := mkIdent (n.getId ++ `Of ++ f.getId)
  match item with
  | `(modelItem| belongsTo $rel : $target via $fk) =>
    elabCommand (← `(command|
      def $(mkIdent (mdl.getId ++ rel.getId)) (self : $mdl) : Dbapi.DbM 1 (Option $target) :=
        Dbapi.DbM.one (((Dbapi.selectFrom $target).filter fun x =>
          $(field target (mkIdent `id)) x ==. $(field mdl fk) self).limit 1 |>.select fun x => x)))
  | `(modelItem| hasMany $rel : $target via $fk) =>
    let preload := mkIdent (mdl.getId ++ Name.mkSimple ("with" ++ capitalize rel.getId.toString))
    elabCommand (← `(command|
      def $(mkIdent (mdl.getId ++ rel.getId)) (self : $mdl) : Dbapi.DbM 1 (List $target) :=
        Dbapi.DbM.all ((Dbapi.selectFrom $target).filter (fun x =>
          $(field target fk) x ==. $(field mdl (mkIdent `id)) self) |>.select fun x => x)))
    elabCommand (← `(command|
      /-- Loads the related rows for every element with one statement. -/
      def $preload (selves : List $mdl) : Dbapi.DbM 1 (List ($mdl × List $target)) :=
        (Dbapi.DbM.all ((Dbapi.selectFrom $target).filter (fun x =>
          Dbapi.Expr.inList ($(field target fk) x) (selves.map $(field mdl (mkIdent `id))))
          |>.select fun x => x)).map fun rows =>
            selves.map fun s => (s, rows.filter fun r =>
              $(field target fk) r == $(field mdl (mkIdent `id)) s)))
  | _ => pure ()
  let _ := ofId

elab_rules : command
  | `(model $name $table where $items*) => do
    let mut fields : Array Ident := #[]
    let mut tys : Array (TSyntax `term) := #[]
    let mut cols : Array (TSyntax `term) := #[]
    for item in items do
      if let `(modelItem| $f:ident : $ty:ident) := item then
        let sty ← sqlTyOf ty
        fields := fields.push f
        tys := tys.push sty
        cols := cols.push (← `(($(quote (snake f.getId.toString)), $sty)))
    let ofId := mkIdent (name.getId ++ `Of)
    let idxs ← (List.range fields.size).toArray.mapM colIdx
    let projs := fields.map fun f => mkIdent (name.getId ++ `Of ++ f.getId)
    let fBinder := mkIdent `f
    let ftys ← tys.mapM fun t => `($fBinder $t)
    elabCommand (← `(command|
      structure $ofId ($fBinder : Dbapi.SqlTy → Type) where
        $[$fields:ident : $ftys]*))
    elabCommand (← `(command| abbrev $name := $ofId Dbapi.SqlTy.denote))
    elabCommand (← `(command|
      instance : Dbapi.Model $ofId where
        schema := { table := $table, cols := [$[$cols],*] }
        build g := ⟨$[g $idxs],*⟩
        get x := fun j => match j with $[| $idxs => $projs x]*))
    elabCommand (← `(command| instance : Dbapi.RowOf $name $ofId := ⟨⟩))
    elabCommand (← `(command|
      def $(mkIdent (name.getId ++ `find)) (key : Int) : Dbapi.DbM 1 (Option $name) :=
        Dbapi.DbM.one (((Dbapi.selectFrom $name).filter fun x =>
          $(mkIdent (name.getId ++ `Of ++ `id)) x ==. key).limit 1 |>.select fun x => x)))
    elabCommand (← `(command|
      def $(mkIdent (name.getId ++ `insert)) (row : $name) : Dbapi.DbM 1 Unit :=
        Dbapi.DbM.run (.insert (Dbapi.Model.schema $ofId) (Dbapi.Model.toRow row))))
    for item in items do
      elabRelation name item
  | `(relations $name where $items*) => do
    for item in items do
      elabRelation name item

end Dbapi
