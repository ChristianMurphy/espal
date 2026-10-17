import Dbapi.Builder

/-!
# Embedded query syntax

```
open Dbapi.QuerySyntax in
def topScores (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 50
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
```

The keywords are scoped to `Dbapi.QuerySyntax`, so they reserve nothing outside files that open
it, and `desc` is a keyword only there. The macro expands to builder calls; inside clauses, `==`, `<`, `&&`, `||`, `!` and `∈` become
SQL operators, and any other term is a column or a Lean value bound as a parameter.
-/

namespace Dbapi.QuerySyntax
open Lean

/-- Rewrites Lean comparison and boolean syntax into SQL expression builders. -/
partial def sqlTerm (t : Term) : MacroM Term := do
  match t with
  | `(($a)) => sqlTerm a
  | `($a == $b) => `(Dbapi.eqE $(← sqlTerm a) $(← sqlTerm b))
  | `($a != $b) => `(Dbapi.neE $(← sqlTerm a) $(← sqlTerm b))
  | `($a < $b) => `(Dbapi.ltE $(← sqlTerm a) $(← sqlTerm b))
  | `($a <= $b) => `(Dbapi.leE $(← sqlTerm a) $(← sqlTerm b))
  | `($a > $b) => `(Dbapi.gtE $(← sqlTerm a) $(← sqlTerm b))
  | `($a >= $b) => `(Dbapi.geE $(← sqlTerm a) $(← sqlTerm b))
  | `($a && $b) => `(Dbapi.Expr.and $(← sqlTerm a) $(← sqlTerm b))
  | `($a || $b) => `(Dbapi.Expr.or $(← sqlTerm a) $(← sqlTerm b))
  | `(!$a) => `(Dbapi.Expr.not $(← sqlTerm a))
  | `($a ∈ $xs) => `(Dbapi.Expr.inList (Dbapi.IntoExpr.into $(← sqlTerm a)) $xs)
  | _ => pure t

syntax joinClause := " join " ident " in " ident " on " term

scoped syntax (name := queryStx) "query " " from " ident " in " ident (ppLine joinClause)*
  (ppLine " where " term)? (ppLine " order " " by " term (" desc")?)? (ppLine " limit " num)?
  ppLine " select " term : term

macro_rules
  | `(query from $a in $t $js:joinClause* $[where $w]? $[order by $k $[desc%$dsc]?]? $[limit $n]?
      select $sel) => do
    if js.size > 2 then Macro.throwError "the builder supports at most three tables"
    let mut aliases : Array Ident := #[a]
    let mut q ← `(Dbapi.selectFrom $t)
    for j in js do
      let `(joinClause| join $b in $u on $c) := j | Macro.throwUnsupported
      aliases := aliases.push b
      let c' ← sqlTerm c
      q ← `(($q).join $u (fun $aliases* => $c'))
    if let some w := w then
      q ← `(($q).filter (fun $aliases* => $(← sqlTerm w)))
    if let some k := k then
      let dir ← match dsc with
        | some (some _) => `(Dbapi.Dir.desc)
        | _ => `(Dbapi.Dir.asc)
      q ← `(($q).orderBy (fun $aliases* => $(← sqlTerm k)) $dir)
    if let some n := n then
      q ← `(($q).limit $n)
    `(($q).select (fun $aliases* => $sel))

end Dbapi.QuerySyntax
