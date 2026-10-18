import Trial.Schema

/-!
Checks on the SQL lean-linq emits, against the cases listed under Espal's injection property.
These are tests, not proofs: lean-linq has no theorem that the text is independent of values.
-/

open LeanLinq

namespace Trial

def titled (t : String) :=
  Query.from' (ts := Exam) assessments |>.where' (fun a => a["title"] ==. t)

/-! Values travel as parameters, so the text doesn't change with them. -/

#guard ((titled "Midterm").toSql .postgres).sql ==
  ((titled "'; DROP TABLE assessments; --").toSql .postgres).sql

/-! A user's `%` reaches a `LIKE` pattern unescaped. -/

def titleLike (p : String) :=
  Query.from' (ts := Exam) assessments |>.where' (fun a => a["title"].like (SqlExpr.str p))

#guard ((titleLike "50%").toSql .postgres).params.map (·.2) == #[.string "50%"]

/-! Identifiers are quoted, with embedded quote characters doubled. -/

abbrev OddS : Schema := [("we\"ird", .long)]
def odd : Table "odd]table" OddS := ⟨⟩
abbrev OddDb : Ctx := { tables := [("odd]table", OddS)] }

#guard ((Query.from' (ts := OddDb) odd).toSql .postgres).sql ==
  "SELECT \"a0\".\"we\"\"ird\" AS \"we\"\"ird\" FROM \"odd]table\" \"a0\""
#guard ((Query.from' (ts := OddDb) odd).toSql .sqlServer).sql ==
  "SELECT [a0].[we\"ird] AS [we\"ird] FROM [odd]]table] [a0]"

/-! Checked compilation accepts more bind parameters than the databases allow: Postgres takes
65,535 and SQL Server 2,100. -/

def manyIds (n : Nat) :=
  Query.from' (ts := Exam) submissions
    |>.where' (fun s => s["id"].inValues ((List.range n).map fun i => SqlExpr.long (Int.ofNat i)))

#guard (((manyIds 70000).toSqlChecked .postgres).map (·.params.size)).toOption == some 70000
#guard (((manyIds 3000).toSqlChecked .sqlServer).map (·.params.size)).toOption == some 3000

end Trial
