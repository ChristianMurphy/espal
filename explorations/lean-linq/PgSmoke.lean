import Trial.Budget
import LeanLinq.Driver.Postgres

/-!
Runs `Trial.bounded` against Postgres through lean-linq's own libpq driver, from a package that
depends on lean-linq the way Espal would. Expects the test database from lean-linq's
`docker-compose.yml` on port 5433.
-/

open LeanLinq Trial

def conninfo : String :=
  "host=127.0.0.1 port=5433 user=testuser password=testpass dbname=testdb"

def main : IO Unit := do
  let conn ← Pg.connect conninfo
  conn.execRaw "DROP TABLE IF EXISTS submissions, assessments"
  conn.createTable assessments (primaryKey := [.column "id"])
  conn.createTable submissions (primaryKey := [.column "id"])
  let _ ← conn.execInsert <| assessments.insert (ts := Exam)
    |>.value "id" 1 |>.value "tenant_id" 7 |>.value "title" "Midterm"
  for i in [1, 2, 3] do
    let _ ← conn.execInsert <| submissions.insert (ts := Exam)
      |>.value "id" (SqlExpr.long (Int.ofNat i)) |>.value "tenant_id" 7 |>.value "assessment_id" 1
      |>.valueNull "score"
  let counts ← (bounded 7 2).execPg conn 3
  IO.println s!"bounded 7 2 over Postgres: {counts}"
  conn.execRaw "DROP TABLE submissions, assessments"
  conn.close
