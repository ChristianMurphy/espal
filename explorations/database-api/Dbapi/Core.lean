/-!
# Shared core for the query API exploration

All three surface styles (builder, models, embedded syntax) produce values of the types in this
file. Proofs about injection, tenants and budgets would be stated once, over these types.

* `Expr Γ t`: a typed SQL expression over the tables in context `Γ`.
* `Select Γ R`: a select statement returning rows of type `R`.
* `Select.eval`: the reference semantics, run against `MemDb`, an in-memory database.
* `Select.render`: SQL text and bind parameters for one of four dialects.
-/

namespace Dbapi

inductive SqlTy where
  | int | text | bool
  deriving DecidableEq, Repr

abbrev SqlTy.denote : SqlTy → Type
  | .int => Int
  | .text => String
  | .bool => Bool

inductive Value where
  | int (i : Int) | text (s : String) | bool (b : Bool)
  deriving Repr, BEq, DecidableEq, Inhabited

def SqlTy.toValue : (t : SqlTy) → t.denote → Value
  | .int, v => .int v
  | .text, v => .text v
  | .bool, v => .bool v

def SqlTy.ofValue : (t : SqlTy) → Value → Option t.denote
  | .int, .int v => some v
  | .text, .text v => some v
  | .bool, .bool v => some v
  | _, _ => none

def SqlTy.beq : (t : SqlTy) → t.denote → t.denote → Bool
  | .int, a, b => a == b
  | .text, a, b => a == b
  | .bool, a, b => a == b

/-- Ordering used by the reference evaluator. Postgres orders text by collation instead. -/
def Value.le : Value → Value → Bool
  | .int a, .int b => decide (a ≤ b)
  | .text a, .text b => decide (a ≤ b)
  | .bool a, .bool b => !a || b
  | _, _ => true

def Value.lt (a b : Value) : Bool := a.le b && a != b

/-- Map a Lean type to the SQL type that stores it. -/
class SqlType (α : Type) where
  ty : SqlTy

instance : SqlType Int := ⟨.int⟩
instance : SqlType String := ⟨.text⟩
instance : SqlType Bool := ⟨.bool⟩

structure Schema where
  table : String
  cols : List (String × SqlTy)
  deriving DecidableEq, Repr

/-- A typed position in a column list. -/
inductive Col : List (String × SqlTy) → SqlTy → Type where
  | here : Col ((n, t) :: cs) t
  | there : Col cs t → Col (c :: cs) t

/-- A typed position in the list of tables a query reads. -/
inductive Tbl : List Schema → Schema → Type where
  | here : Tbl (s :: ss) s
  | there : Tbl ss s → Tbl (s' :: ss) s

def Col.name : Col cs t → String
  | @Col.here n _ _ => n
  | .there j => j.name

def Tbl.index : Tbl ss s → Nat
  | .here => 0
  | .there i => i.index + 1

inductive HList {α : Type} (β : α → Type) : List α → Type where
  | nil : HList β []
  | cons (x : β a) (xs : HList β as) : HList β (a :: as)

abbrev Row (s : Schema) := HList (fun c : String × SqlTy => c.2.denote) s.cols
abbrev Env (Γ : List Schema) := HList Row Γ

def Col.get : Col cs t → HList (fun c : String × SqlTy => c.2.denote) cs → t.denote
  | .here, .cons x _ => x
  | .there j, .cons _ xs => j.get xs

def Tbl.get : Tbl ss s → HList Row ss → Row s
  | .here, .cons r _ => r
  | .there i, .cons _ rs => i.get rs

inductive Expr (Γ : List Schema) : SqlTy → Type where
  | col (i : Tbl Γ s) (j : Col s.cols t) : Expr Γ t
  | param (v : t.denote) : Expr Γ t
  | eq (a b : Expr Γ t) : Expr Γ .bool
  | lt (a b : Expr Γ t) : Expr Γ .bool
  | le (a b : Expr Γ t) : Expr Γ .bool
  | and (a b : Expr Γ .bool) : Expr Γ .bool
  | or (a b : Expr Γ .bool) : Expr Γ .bool
  | not (a : Expr Γ .bool) : Expr Γ .bool
  | inList (a : Expr Γ t) (vs : List t.denote) : Expr Γ .bool
  | true : Expr Γ .bool

namespace Expr

def eval (env : Env Γ) : Expr Γ t → t.denote
  | .col i j => j.get (i.get env)
  | .param v => v
  | .eq (t := t) a b => t.beq (a.eval env) (b.eval env)
  | .lt (t := t) a b => (t.toValue (a.eval env)).lt (t.toValue (b.eval env))
  | .le (t := t) a b => (t.toValue (a.eval env)).le (t.toValue (b.eval env))
  | .and a b => a.eval env && b.eval env
  | .or a b => a.eval env || b.eval env
  | .not a => !a.eval env
  | .inList (t := t) a vs => vs.any (t.beq (a.eval env))
  | .true => Bool.true

/-- Conjunction that drops the `true` a query starts with. -/
def andAlso : Expr Γ .bool → Expr Γ .bool → Expr Γ .bool
  | .true, b => b
  | a, b => .and a b

end Expr

inductive Dialect where
  | postgres | sqlite | mysql | mssql
  deriving Repr, DecidableEq

def Dialect.placeholder : Dialect → Nat → String
  | .postgres, n => s!"${n}"
  | .sqlite, n => s!"?{n}"
  | .mysql, _ => "?"
  | .mssql, n => s!"@p{n}"

/-- Rendering state: the bind parameters collected so far. -/
abbrev RenderM := StateM (Array Value)

def bind (d : Dialect) (v : Value) : RenderM String := do
  modify (·.push v)
  return d.placeholder (← get).size

namespace Expr

def render (d : Dialect) : Expr Γ t → RenderM String
  | .col i j => pure s!"t{i.index}.{j.name}"
  | .param (t := t) v => bind d (t.toValue v)
  | .eq a b => return s!"({← a.render d} = {← b.render d})"
  | .lt a b => return s!"({← a.render d} < {← b.render d})"
  | .le a b => return s!"({← a.render d} <= {← b.render d})"
  | .and a b => return s!"({← a.render d} AND {← b.render d})"
  | .or a b => return s!"({← a.render d} OR {← b.render d})"
  | .not a => return s!"(NOT {← a.render d})"
  | .inList (t := t) a vs => do
    let lhs ← a.render d
    let phs ← vs.mapM fun v => bind d (t.toValue v)
    return s!"({lhs} IN ({", ".intercalate phs}))"
  | .true => pure "(1 = 1)"

end Expr

inductive Dir where
  | asc | desc

structure Order (Γ : List Schema) where
  ty : SqlTy
  key : Expr Γ ty
  dir : Dir

/-- The clauses of a select, before the result columns are chosen. -/
structure Query (Γ : List Schema) where
  ons : List (Expr Γ .bool) := []
  filter : Expr Γ .bool := .true
  order : List (Order Γ) := []
  limit : Option Nat := none

/-- A value that can be selected: a column, a tuple, or a whole model. -/
class Selectable (Γ : List Schema) (E : Type) (R : outParam Type) where
  cols : E → List ((t : SqlTy) × Expr Γ t)
  eval : E → Env Γ → R
  decode : E → List Value → Option (R × List Value)

instance : Selectable Γ (Expr Γ t) t.denote where
  cols e := [⟨t, e⟩]
  eval e env := e.eval env
  decode _
    | v :: vs => (t.ofValue v).map (·, vs)
    | [] => none

instance [Selectable Γ A RA] [Selectable Γ B RB] : Selectable Γ (A × B) (RA × RB) where
  cols p := Selectable.cols p.1 ++ Selectable.cols p.2
  eval p env := (Selectable.eval p.1 env, Selectable.eval p.2 env)
  decode p vs := do
    let (a, vs) ← Selectable.decode (Γ := Γ) p.1 vs
    let (b, vs) ← Selectable.decode (Γ := Γ) p.2 vs
    return ((a, b), vs)

structure Select (Γ : List Schema) (R : Type) where
  query : Query Γ
  cols : List ((t : SqlTy) × Expr Γ t)
  eval : Env Γ → R
  decode : List Value → Option R

/-! ## The in-memory database -/

/-- Rows per table. The reference evaluator runs queries against it. -/
abbrev MemDb := List ((s : Schema) × List (Row s))

def MemDb.rows (db : MemDb) (s : Schema) : List (Row s) :=
  match db.find? (·.1 == s) with
  | some ⟨s', rs⟩ => if h : s' = s then h ▸ rs else []
  | none => []

def MemDb.insert (db : MemDb) (s : Schema) (r : Row s) : MemDb :=
  if db.any (·.1 == s) then
    db.map fun ⟨s', rs⟩ => if h : s' = s then ⟨s', rs ++ [h ▸ r]⟩ else ⟨s', rs⟩
  else db ++ [⟨s, [r]⟩]

/-- Every combination of one row per table: the cross product a join filters. -/
def envs (db : MemDb) : (Γ : List Schema) → List (Env Γ)
  | [] => [.nil]
  | s :: ss => (db.rows s).flatMap fun r => (envs db ss).map (.cons r)

def orderKey (env : Env Γ) (os : List (Order Γ)) : List (Value × Dir) :=
  os.map fun o => (o.ty.toValue (o.key.eval env), o.dir)

def keyLe : List (Value × Dir) → List (Value × Dir) → Bool
  | (a, d) :: as, (b, _) :: bs =>
    if a == b then keyLe as bs
    else match d with
      | .asc => a.le b
      | .desc => b.le a
  | _, _ => true

def SqlTy.ddl : Dialect → SqlTy → String
  | .sqlite, .int => "INTEGER"
  | .mssql, .text => "NVARCHAR(400)"
  | .mysql, .text => "VARCHAR(400)"
  | _, .int => "BIGINT"
  | _, .text => "TEXT"
  | .mssql, .bool => "BIT"
  | _, .bool => "BOOLEAN"

def Schema.createTable (d : Dialect) (s : Schema) : String :=
  let cols := s.cols.map fun (n, t) => s!"{n} {t.ddl d} NOT NULL"
  s!"CREATE TABLE {s.table} ({", ".intercalate cols})"

namespace Select

/-- The reference result as untyped values, for comparison with a real database. -/
def evalValues (q : Select Γ R) (db : MemDb) : List (List Value) :=
  let keep := (envs db Γ).filter fun env =>
    q.query.ons.all (·.eval env) && q.query.filter.eval env
  let sorted := keep.mergeSort fun a b => keyLe (orderKey a q.query.order) (orderKey b q.query.order)
  let limited := match q.query.limit with
    | some n => sorted.take n
    | none => sorted
  limited.map fun env => q.cols.map fun ⟨t, e⟩ => t.toValue (e.eval env)

def evalOn (q : Select Γ R) (db : MemDb) : List R :=
  let keep := (envs db Γ).filter fun env =>
    q.query.ons.all (·.eval env) && q.query.filter.eval env
  let sorted := keep.mergeSort fun a b => keyLe (orderKey a q.query.order) (orderKey b q.query.order)
  let limited := match q.query.limit with
    | some n => sorted.take n
    | none => sorted
  limited.map q.eval

/-- `FROM a t0 JOIN b t1 ON … JOIN c t2 ON …`: the `k`-th join condition belongs to table `k + 1`. -/
def renderSchemas (d : Dialect) (q : Query Γ) (names : List String) : RenderM String := do
  let ons ← q.ons.mapM (·.render d)
  let mut out := ""
  let mut i := 0
  for n in names do
    if i == 0 then out := s!"FROM {n} t0"
    else out := out ++ s!" JOIN {n} t{i} ON {(ons[i - 1]?).getD "(1 = 1)"}"
    i := i + 1
  return out

/-- SQL text and bind parameters. `MSSQL` spells a row limit as `TOP`. -/
def render (q : Select Γ R) (d : Dialect) : String × Array Value :=
  let m : RenderM String := do
    let cols ← q.cols.mapM fun ⟨_, e⟩ => e.render d
    let top := match d, q.query.limit with
      | .mssql, some n => s!"TOP ({n}) "
      | _, _ => ""
    let src ← renderSchemas d q.query (Γ.map (·.table))
    let whr ← match q.query.filter with
      | .true => pure ""
      | f => pure (" WHERE " ++ (← f.render d))
    let ord ← q.query.order.mapM fun o => do
      let k ← o.key.render d
      pure (k ++ match o.dir with | .asc => "" | .desc => " DESC")
    let ordS := if ord.isEmpty then "" else " ORDER BY " ++ ", ".intercalate ord
    let lim := match d, q.query.limit with
      | .mssql, _ => ""
      | _, some n => s!" LIMIT {n}"
      | _, none => ""
    return s!"SELECT {top}{", ".intercalate cols} {src}{whr}{ordS}{lim}"
  m.run #[]

end Select

end Dbapi
