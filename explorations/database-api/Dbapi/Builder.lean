import Dbapi.Core

/-!
# Models and the query builder

A model is a structure with one parameter `f : SqlTy → Type`, the "higher-kinded data" pattern.
`Student.Of SqlTy.denote` is a row with plain Lean values; `Student.Of (Expr Γ)` holds one column
expression per field, so `s.age` in a query is the typed column `t0.age`.

The builder supports one to three tables. Each arity has its own query type, because a lambda over
the tables needs one binder per table.
-/

namespace Dbapi

class Model (F : (SqlTy → Type) → Type) where
  schema : Schema
  build : {f : SqlTy → Type} → ({t : SqlTy} → Col schema.cols t → f t) → F f
  get : {f : SqlTy → Type} → F f → {t : SqlTy} → Col schema.cols t → f t

/-- Links a row type such as `Student` to its model `Student.Of`. -/
class RowOf (R : Type) (F : outParam ((SqlTy → Type) → Type)) : Prop where

def allCols : (cs : List (String × SqlTy)) → List ((t : SqlTy) × Col cs t)
  | [] => []
  | (_, t) :: cs => ⟨t, .here⟩ :: (allCols cs).map fun ⟨t', j⟩ => ⟨t', .there j⟩

def decodeRow : (cs : List (String × SqlTy)) → List Value →
    Option (HList (fun c : String × SqlTy => c.2.denote) cs × List Value)
  | [], vs => some (.nil, vs)
  | (_, t) :: cs, v :: vs => do
    let x ← t.ofValue v
    let (xs, rest) ← decodeRow cs vs
    return (.cons x xs, rest)
  | _ :: _, [] => none

namespace Model

def toRow [Model F] (x : F SqlTy.denote) : Row (schema F) :=
  go (schema F).cols fun j => get x j
where
  go : (cs : List (String × SqlTy)) → ({t : SqlTy} → Col cs t → t.denote) →
      HList (fun c : String × SqlTy => c.2.denote) cs
    | [], _ => .nil
    | (_, _) :: cs, g => .cons (g .here) (go cs fun j => g (.there j))

def ofRow [Model F] (r : Row (schema F)) : F SqlTy.denote :=
  build fun j => j.get r

end Model

instance [Model F] : Selectable Γ (F (Expr Γ)) (F SqlTy.denote) where
  cols x := (allCols (Model.schema F).cols).map fun ⟨t, j⟩ => ⟨t, Model.get x j⟩
  eval x env := Model.build fun j => (Model.get x j).eval env
  decode _ vs := (decodeRow (Model.schema F).cols vs).map fun (r, rest) => (Model.ofRow r, rest)

/-! ## Operators -/

/-- Values that can stand in an expression: a column expression, or a Lean value bound as a
parameter. -/
class IntoExpr (Γ : List Schema) (t : outParam SqlTy) (α : Type) where
  into : α → Expr Γ t

instance : IntoExpr Γ t (Expr Γ t) := ⟨id⟩
instance : IntoExpr Γ .int Int := ⟨fun v => .param (t := .int) v⟩
instance : IntoExpr Γ .int Nat := ⟨fun n => .param (Int.ofNat n)⟩
instance : IntoExpr Γ .text String := ⟨fun v => .param (t := .text) v⟩
instance : IntoExpr Γ .bool Bool := ⟨fun v => .param (t := .bool) v⟩

section
variable {Γ : List Schema} {t : SqlTy} {α β : Type} [IntoExpr Γ t α] [IntoExpr Γ t β]
open IntoExpr

def eqE (a : α) (b : β) : Expr Γ .bool := .eq (into a) (into b)
def neE (a : α) (b : β) : Expr Γ .bool := .not (.eq (into a) (into b))
def ltE (a : α) (b : β) : Expr Γ .bool := .lt (into a) (into b)
def leE (a : α) (b : β) : Expr Γ .bool := .le (into a) (into b)
def gtE (a : α) (b : β) : Expr Γ .bool := .lt (into b) (into a)
def geE (a : α) (b : β) : Expr Γ .bool := .le (into b) (into a)
end

infix:50 " ==. " => eqE
infix:50 " !=. " => neE
infix:50 " <. " => ltE
infix:50 " <=. " => leE
infix:50 " >. " => gtE
infix:50 " >=. " => geE
infixl:35 " &&. " => Expr.and
infixl:30 " ||. " => Expr.or

/-! ## Weakening, for adding a table to a query that already has clauses -/

def Tbl.weaken : Tbl Γ s → Tbl (Γ ++ Δ) s
  | .here => .here
  | .there i => .there i.weaken

def Expr.weaken : Expr Γ t → Expr (Γ ++ Δ) t
  | .col i j => .col i.weaken j
  | .param v => .param v
  | .eq a b => .eq a.weaken b.weaken
  | .lt a b => .lt a.weaken b.weaken
  | .le a b => .le a.weaken b.weaken
  | .and a b => .and a.weaken b.weaken
  | .or a b => .or a.weaken b.weaken
  | .not a => .not a.weaken
  | .inList a vs => .inList a.weaken vs
  | .true => .true

def Query.weaken (q : Query Γ) : Query (Γ ++ Δ) where
  ons := q.ons.map Expr.weaken
  filter := q.filter.weaken
  order := q.order.map fun o => { ty := o.ty, key := o.key.weaken, dir := o.dir }
  limit := q.limit

def Query.select [Selectable Γ E R] (q : Query Γ) (e : E) : Select Γ R where
  query := q
  cols := Selectable.cols e
  eval := Selectable.eval e
  decode vs := (Selectable.decode (Γ := Γ) e vs).map (·.1)

/-! ## Builders for one, two and three tables -/

abbrev Ctx1 (F1) [Model F1] := [Model.schema F1]
abbrev Ctx2 (F1 F2) [Model F1] [Model F2] := [Model.schema F1, Model.schema F2]
abbrev Ctx3 (F1 F2 F3) [Model F1] [Model F2] [Model F3] :=
  [Model.schema F1, Model.schema F2, Model.schema F3]

structure Q1 (F1) [Model F1] where
  q : Query (Ctx1 F1)

structure Q2 (F1 F2) [Model F1] [Model F2] where
  q : Query (Ctx2 F1 F2)

structure Q3 (F1 F2 F3) [Model F1] [Model F2] [Model F3] where
  q : Query (Ctx3 F1 F2 F3)

section
variable {F1 F2 F3 : (SqlTy → Type) → Type} [Model F1] [Model F2] [Model F3]

def refAt {ctx : List Schema} (F : (SqlTy → Type) → Type) [Model F] (i : Tbl ctx (Model.schema F)) :
    F (Expr ctx) :=
  Model.build fun j => .col i j

def selectFrom (R : Type) {F : (SqlTy → Type) → Type} [RowOf R F] [Model F] : Q1 F := ⟨{}⟩

namespace Q1
variable (q : Q1 F1)
local notation "Γ" => Ctx1 F1
local notation "r1" => refAt F1 (ctx := Γ) Tbl.here

def filter (p : F1 (Expr Γ) → Expr Γ .bool) : Q1 F1 :=
  ⟨{ q.q with filter := Expr.andAlso q.q.filter (p r1) }⟩
def orderBy (k : F1 (Expr Γ) → Expr Γ t) (d : Dir := .asc) : Q1 F1 :=
  ⟨{ q.q with order := q.q.order ++ [{ ty := t, key := k r1, dir := d }] }⟩
def limit (n : Nat) : Q1 F1 := ⟨{ q.q with limit := some n }⟩
def select [Selectable Γ E R] (f : F1 (Expr Γ) → E) : Select Γ R := q.q.select (f r1)
def join (R2 : Type) {F2 : (SqlTy → Type) → Type} [RowOf R2 F2] [Model F2]
    (on : F1 (Expr (Ctx2 F1 F2)) → F2 (Expr (Ctx2 F1 F2)) → Expr (Ctx2 F1 F2) .bool) :
    Q2 F1 F2 :=
  let q' : Query (Ctx2 F1 F2) := q.q.weaken (Δ := [Model.schema F2])
  ⟨{ q' with ons := q'.ons ++ [on (refAt F1 .here) (refAt F2 (.there .here))] }⟩
end Q1

namespace Q2
variable (q : Q2 F1 F2)
local notation "Γ" => Ctx2 F1 F2
local notation "r1" => refAt F1 (ctx := Γ) Tbl.here
local notation "r2" => refAt F2 (ctx := Γ) (Tbl.there Tbl.here)

def filter (p : F1 (Expr Γ) → F2 (Expr Γ) → Expr Γ .bool) : Q2 F1 F2 :=
  ⟨{ q.q with filter := Expr.andAlso q.q.filter (p r1 r2) }⟩
def orderBy (k : F1 (Expr Γ) → F2 (Expr Γ) → Expr Γ t) (d : Dir := .asc) : Q2 F1 F2 :=
  ⟨{ q.q with order := q.q.order ++ [{ ty := t, key := k r1 r2, dir := d }] }⟩
def limit (n : Nat) : Q2 F1 F2 := ⟨{ q.q with limit := some n }⟩
def select [Selectable Γ E R] (f : F1 (Expr Γ) → F2 (Expr Γ) → E) : Select Γ R :=
  q.q.select (f r1 r2)
def join (R3 : Type) {F3 : (SqlTy → Type) → Type} [RowOf R3 F3] [Model F3]
    (on : F1 (Expr (Ctx3 F1 F2 F3)) → F2 (Expr (Ctx3 F1 F2 F3)) → F3 (Expr (Ctx3 F1 F2 F3)) →
      Expr (Ctx3 F1 F2 F3) .bool) : Q3 F1 F2 F3 :=
  let q' : Query (Ctx3 F1 F2 F3) := q.q.weaken (Δ := [Model.schema F3])
  ⟨{ q' with
      ons := q'.ons ++ [on (refAt F1 .here) (refAt F2 (.there .here))
        (refAt F3 (.there (.there .here)))] }⟩
end Q2

namespace Q3
variable (q : Q3 F1 F2 F3)
local notation "Γ" => Ctx3 F1 F2 F3
local notation "r1" => refAt F1 (ctx := Γ) Tbl.here
local notation "r2" => refAt F2 (ctx := Γ) (Tbl.there Tbl.here)
local notation "r3" => refAt F3 (ctx := Γ) (Tbl.there (Tbl.there Tbl.here))

def filter (p : F1 (Expr Γ) → F2 (Expr Γ) → F3 (Expr Γ) → Expr Γ .bool) : Q3 F1 F2 F3 :=
  ⟨{ q.q with filter := Expr.andAlso q.q.filter (p r1 r2 r3) }⟩
def orderBy (k : F1 (Expr Γ) → F2 (Expr Γ) → F3 (Expr Γ) → Expr Γ t) (d : Dir := .asc) :
    Q3 F1 F2 F3 :=
  ⟨{ q.q with order := q.q.order ++ [{ ty := t, key := k r1 r2 r3, dir := d }] }⟩
def limit (n : Nat) : Q3 F1 F2 F3 := ⟨{ q.q with limit := some n }⟩
def select [Selectable Γ E R] (f : F1 (Expr Γ) → F2 (Expr Γ) → F3 (Expr Γ) → E) :
    Select Γ R :=
  q.q.select (f r1 r2 r3)
end Q3

end

/-! ## Statement budgets -/

/-- A write statement. Updates and deletes would follow the same shape. -/
inductive Write where
  | insert (s : Schema) (r : Row s)

def Write.render (d : Dialect) : Write → String × Array Value
  | .insert s r =>
    let vals := go s.cols r
    let phs := (List.range vals.length).map fun i => d.placeholder (i + 1)
    (s!"INSERT INTO {s.table} ({", ".intercalate (s.cols.map (·.1))}) VALUES ({", ".intercalate phs})",
      vals.toArray)
where
  go : (cs : List (String × SqlTy)) → HList (fun c : String × SqlTy => c.2.denote) cs → List Value
    | [], .nil => []
    | (_, t) :: cs, .cons x xs => t.toValue x :: go cs xs

def Write.apply (db : MemDb) : Write → MemDb
  | .insert s r => db.insert s r

/-- A database program that sends exactly `n` statements. -/
inductive DbM : Nat → Type → Type 1 where
  | pure (a : α) : DbM 0 α
  | fetch {Γ : List Schema} {R : Type} (q : Select Γ R) (k : List R → DbM n α) : DbM (n + 1) α
  | exec (w : Write) (k : Unit → DbM n α) : DbM (n + 1) α

namespace DbM

def bind : DbM m α → (α → DbM n β) → DbM (n + m) β
  | .pure a, f => f a
  | .fetch q k, f => .fetch q fun rows => (k rows).bind f
  | .exec w k, f => .exec w fun u => (k u).bind f

def map (f : α → β) : DbM n α → DbM n β
  | .pure a => .pure (f a)
  | .fetch q k => .fetch q fun rows => (k rows).map f
  | .exec w k => .exec w fun u => (k u).map f

def all (q : Select Γ R) : DbM 1 (List R) := .fetch q .pure

def one (q : Select Γ R) : DbM 1 (Option R) := (all q).map (·.head?)

def run (w : Write) : DbM 1 Unit := .exec w .pure

/-- Run against the in-memory database, recording the SQL each statement would send. -/
def runMem (d : Dialect) (db : MemDb) : DbM n α → α × MemDb × List String
  | .pure a => (a, db, [])
  | .fetch q k =>
    let (a, db', sent) := (k (q.evalOn db)).runMem d db
    (a, db', (q.render d).1 :: sent)
  | .exec w k =>
    let (a, db', sent) := (k ()).runMem d (w.apply db)
    (a, db', (w.render d).1 :: sent)

end DbM

end Dbapi
