import Dbapi.Builder

/-!
# Query syntax in `do` notation

```
open Dbapi.Do in
def topScores (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 50)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
```

A query is a program in the `QM var` monad, for every choice of `var : Schema → Type`. The
interpreter picks `var`: rows for evaluation, alias numbers for SQL text. Because a query works
for every `var`, it can't hold on to another query's table variable, and ordinary Lean control
flow (`if`, `match`) can add clauses depending on runtime values.

This is a second tree beside `Dbapi.Expr`; proofs would have to cover it separately.
-/

namespace Dbapi.Do

inductive PExpr (var : Schema → Type) : SqlTy → Type where
  | col (v : var s) (j : Col s.cols t) : PExpr var t
  | param (v : t.denote) : PExpr var t
  | eq (a b : PExpr var t) : PExpr var .bool
  | lt (a b : PExpr var t) : PExpr var .bool
  | le (a b : PExpr var t) : PExpr var .bool
  | and (a b : PExpr var .bool) : PExpr var .bool
  | or (a b : PExpr var .bool) : PExpr var .bool
  | not (a : PExpr var .bool) : PExpr var .bool
  | inList (a : PExpr var t) (vs : List t.denote) : PExpr var .bool

/-- The selected columns and how to read a result row back. `R` doesn't mention `var`. -/
structure Proj (var : Schema → Type) (R : Type) where
  cols : List ((t : SqlTy) × PExpr var t)
  decode : List Value → Option R

inductive QM (var : Schema → Type) : Type → Type 1 where
  | pure (a : α) : QM var α
  | source (s : Schema) (k : var s → QM var α) : QM var α
  | filter (p : PExpr var .bool) (k : Unit → QM var α) : QM var α
  | order (t : SqlTy) (e : PExpr var t) (d : Dir) (k : Unit → QM var α) : QM var α
  | limit (n : Nat) (k : Unit → QM var α) : QM var α

def QM.bind : QM var α → (α → QM var β) → QM var β
  | .pure a, f => f a
  | .source s k, f => .source s fun v => (k v).bind f
  | .filter p k, f => .filter p fun u => (k u).bind f
  | .order t e d k, f => .order t e d fun u => (k u).bind f
  | .limit n k, f => .limit n fun u => (k u).bind f

instance : Monad (QM var) where
  pure := .pure
  bind := QM.bind

/-- A query: a program for every interpretation of table variables. -/
def Query (R : Type) : Type 1 := (var : Schema → Type) → QM var (Proj var R)

/-! ## Operations -/

def source (R : Type) {F : (SqlTy → Type) → Type} [RowOf R F] [Model F] :
    QM var (F (PExpr var)) :=
  .source (Model.schema F) fun v => .pure (Model.build fun j => .col v j)

def guardP (p : PExpr var .bool) : QM var Unit := .filter p .pure
def orderByP (e : PExpr var t) (d : Dir) : QM var Unit := .order t e d .pure
def limitP (n : Nat) : QM var Unit := .limit n .pure

class PSel (var : Schema → Type) (E : Type) (R : outParam Type) where
  cols : E → List ((t : SqlTy) × PExpr var t)
  decode : E → List Value → Option (R × List Value)

instance : PSel var (PExpr var t) t.denote where
  cols e := [⟨t, e⟩]
  decode _
    | v :: vs => (t.ofValue v).map (·, vs)
    | [] => none

instance [PSel var A RA] [PSel var B RB] : PSel var (A × B) (RA × RB) where
  cols p := PSel.cols p.1 ++ PSel.cols p.2
  decode p vs := do
    let (a, vs) ← PSel.decode (var := var) p.1 vs
    let (b, vs) ← PSel.decode (var := var) p.2 vs
    return ((a, b), vs)

instance [Model F] : PSel var (F (PExpr var)) (F SqlTy.denote) where
  cols x := (allCols (Model.schema F).cols).map fun ⟨t, j⟩ => ⟨t, Model.get x j⟩
  decode _ vs := (decodeRow (Model.schema F).cols vs).map fun (r, rest) => (Model.ofRow r, rest)

def selectP [PSel var E R] (e : E) : QM var (Proj var R) :=
  .pure { cols := PSel.cols e, decode := fun vs => (PSel.decode (var := var) e vs).map (·.1) }

class IntoP (var : Schema → Type) (t : outParam SqlTy) (α : Type) where
  into : α → PExpr var t

instance : IntoP var t (PExpr var t) := ⟨id⟩
instance : IntoP var .int Int := ⟨fun v => .param (t := .int) v⟩
instance : IntoP var .int Nat := ⟨fun n => .param (t := .int) (Int.ofNat n)⟩
instance : IntoP var .text String := ⟨fun v => .param (t := .text) v⟩
instance : IntoP var .bool Bool := ⟨fun v => .param (t := .bool) v⟩

section
variable {var : Schema → Type} {t : SqlTy} {α β : Type} [IntoP var t α] [IntoP var t β]
open IntoP
def peq (a : α) (b : β) : PExpr var .bool := .eq (into a) (into b)
def pne (a : α) (b : β) : PExpr var .bool := .not (.eq (into a) (into b))
def plt (a : α) (b : β) : PExpr var .bool := .lt (into a) (into b)
def ple (a : α) (b : β) : PExpr var .bool := .le (into a) (into b)
def pgt (a : α) (b : β) : PExpr var .bool := .lt (into b) (into a)
def pge (a : α) (b : β) : PExpr var .bool := .le (into b) (into a)
end

/-! ## Evaluation: `var` is a row -/

def PExpr.eval : PExpr Row t → t.denote
  | .col r j => j.get r
  | .param v => v
  | .eq (t := t) a b => t.beq a.eval b.eval
  | .lt (t := t) a b => (t.toValue a.eval).lt (t.toValue b.eval)
  | .le (t := t) a b => (t.toValue a.eval).le (t.toValue b.eval)
  | .and a b => a.eval && b.eval
  | .or a b => a.eval || b.eval
  | .not a => !a.eval
  | .inList (t := t) a vs => vs.any (t.beq a.eval)

/-- Each surviving combination of rows, with its sort key, the limit seen, and the result. -/
def paths (db : MemDb) : QM Row α → List (List (Value × Dir) × Option Nat × α)
  | .pure a => [([], none, a)]
  | .source s k => (db.rows s).flatMap fun r => paths db (k r)
  | .filter p k => if p.eval then paths db (k ()) else []
  | .order t e d k => (paths db (k ())).map fun (ks, l, a) => ((t.toValue e.eval, d) :: ks, l, a)
  | .limit n k => (paths db (k ())).map fun (ks, _, a) => (ks, some n, a)

def evalOn (q : Query R) (db : MemDb) : List R :=
  let ps := paths db (q Row)
  let sorted := ps.mergeSort fun a b => keyLe a.1 b.1
  let lim := (ps.head?.bind (·.2.1))
  let taken := match lim with | some n => sorted.take n | none => sorted
  taken.filterMap fun (_, _, p) => p.decode (p.cols.map fun ⟨t, e⟩ => t.toValue e.eval)

/-! ## SQL: `var` is an alias number -/

abbrev Alias := fun (_ : Schema) => Nat

def PExpr.render (d : Dialect) : PExpr Alias t → RenderM String
  | .col a j => pure s!"t{a}.{j.name}"
  | .param (t := t) v => Dbapi.bind d (t.toValue v)
  | .eq a b => return s!"({← a.render d} = {← b.render d})"
  | .lt a b => return s!"({← a.render d} < {← b.render d})"
  | .le a b => return s!"({← a.render d} <= {← b.render d})"
  | .and a b => return s!"({← a.render d} AND {← b.render d})"
  | .or a b => return s!"({← a.render d} OR {← b.render d})"
  | .not a => return s!"(NOT {← a.render d})"
  | .inList (t := t) a vs => do
    let lhs ← a.render d
    let phs ← vs.mapM fun v => Dbapi.bind d (t.toValue v)
    return s!"({lhs} IN ({", ".intercalate phs}))"

structure Parts where
  froms : Array String := #[]
  wheres : Array String := #[]
  orders : Array String := #[]
  limit : Option Nat := none
  cols : List String := []

def collect (d : Dialect) : QM Alias (Proj Alias R) → Parts → RenderM Parts
  | .pure p, acc => do return { acc with cols := ← p.cols.mapM fun ⟨_, e⟩ => e.render d }
  | .source s k, acc =>
    collect d (k acc.froms.size) { acc with froms := acc.froms.push s!"{s.table} t{acc.froms.size}" }
  | .filter p k, acc => do collect d (k ()) { acc with wheres := acc.wheres.push (← p.render d) }
  | .order _ e dir k, acc => do
    let key ← e.render d
    let key := match dir with | .asc => key | .desc => key ++ " DESC"
    collect d (k ()) { acc with orders := acc.orders.push key }
  | .limit n k, acc => collect d (k ()) { acc with limit := some n }

def render (q : Query R) (d : Dialect) : String × Array Value :=
  let m : RenderM String := do
    let p ← collect d (q Alias) {}
    let top := match d, p.limit with | .mssql, some n => s!"TOP ({n}) " | _, _ => ""
    let src := "FROM " ++ " CROSS JOIN ".intercalate p.froms.toList
    let whr := if p.wheres.isEmpty then "" else " WHERE " ++ " AND ".intercalate p.wheres.toList
    let ord := if p.orders.isEmpty then "" else " ORDER BY " ++ ", ".intercalate p.orders.toList
    let lim := match d, p.limit with | .mssql, _ => "" | _, some n => s!" LIMIT {n}" | _, none => ""
    return s!"SELECT {top}{", ".intercalate p.cols} {src}{whr}{ord}{lim}"
  m.run #[]

/-- The reference result as untyped values, for the differential test. -/
def evalValues (q : Query R) (db : MemDb) : List (List Value) :=
  let ps := paths db (q Row)
  let sorted := ps.mergeSort fun a b => keyLe a.1 b.1
  let lim := (ps.head?.bind (·.2.1))
  let taken := match lim with | some n => sorted.take n | none => sorted
  taken.map fun (_, _, p) => p.cols.map fun ⟨t, e⟩ => t.toValue e.eval

/-! ## Surface syntax -/

open Lean in
/-- Rewrites comparison and boolean syntax inside `guard` and `orderBy` into SQL builders. -/
partial def sqlTermP (t : Term) : MacroM Term := do
  match t with
  | `(($a)) => sqlTermP a
  | `($a == $b) => `(Dbapi.Do.peq $(← sqlTermP a) $(← sqlTermP b))
  | `($a != $b) => `(Dbapi.Do.pne $(← sqlTermP a) $(← sqlTermP b))
  | `($a < $b) => `(Dbapi.Do.plt $(← sqlTermP a) $(← sqlTermP b))
  | `($a <= $b) => `(Dbapi.Do.ple $(← sqlTermP a) $(← sqlTermP b))
  | `($a > $b) => `(Dbapi.Do.pgt $(← sqlTermP a) $(← sqlTermP b))
  | `($a >= $b) => `(Dbapi.Do.pge $(← sqlTermP a) $(← sqlTermP b))
  | `($a && $b) => `(Dbapi.Do.PExpr.and $(← sqlTermP a) $(← sqlTermP b))
  | `($a || $b) => `(Dbapi.Do.PExpr.or $(← sqlTermP a) $(← sqlTermP b))
  | `(!$a) => `(Dbapi.Do.PExpr.not $(← sqlTermP a))
  | `($a ∈ $xs) => `(Dbapi.Do.PExpr.inList (Dbapi.Do.IntoP.into $(← sqlTermP a)) $xs)
  | _ => pure t

scoped syntax "from " ident : term
scoped syntax "guard " term:max : term
scoped syntax "orderBy " term:max (" desc")? : term
scoped syntax "limit " term:max : term
scoped syntax "select " term:max : term
scoped syntax "query% " term : term

macro_rules
  | `(from $t) => `(Dbapi.Do.source $t)
  | `(guard $p) => do `(Dbapi.Do.guardP $(← sqlTermP p))
  | `(orderBy $e $[desc%$dsc]?) => do
    let dir ← if dsc.isSome then `(Dbapi.Dir.desc) else `(Dbapi.Dir.asc)
    `(Dbapi.Do.orderByP $(← sqlTermP e) $dir)
  | `(limit $n) => `(Dbapi.Do.limitP $n)
  | `(select $e) => `(Dbapi.Do.selectP $e)
  | `(query% $body) => `((fun var => ($body : Dbapi.Do.QM var _) : Dbapi.Do.Query _))

end Dbapi.Do
