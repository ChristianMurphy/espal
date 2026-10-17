import Dbapi.Demo
import Lean.Data.Json

/-! Writes DDL, seed rows, queries and reference results as JSON for `difftest.py`. -/

namespace Demo
open Dbapi Lean

def Value.toJson : Value → Json
  | .int i => Json.num (JsonNumber.fromInt i)
  | .text s => Json.str s
  | .bool b => Json.bool b

def rendered {Γ R} (q : Select Γ R) (d : Dialect) : Json :=
  let (sql, ps) := q.render d
  Json.mkObj [("sql", sql), ("params", Json.arr (ps.map Value.toJson))]

def caseQ {Γ R} (name : String) (q : Select Γ R) (db : MemDb) : Json :=
  Json.mkObj [("name", name), ("sqlite", rendered q .sqlite), ("postgres", rendered q .postgres),
    ("expected", Json.arr ((q.evalValues db).toArray.map fun r => Json.arr (r.toArray.map Value.toJson)))]

/-- Extra rows whose names sort differently by code point and by language rules. -/
def seed2 : MemDb :=
  let ins (db : MemDb) (r : Student) := db.insert (Model.schema Student.Of) (Model.toRow r)
  let db := ins seed { id := 20, schoolId := 2, name := "adam", age := 14 }
  let db := ins db { id := 21, schoolId := 2, name := "Zoe", age := 14 }
  ins db { id := 22, schoolId := 2, name := "Émile", age := 14 }

open Dbapi.QuerySyntax in
def byName (school : Int) := query
  from s in Student
  where s.schoolId == school
  order by s.name
  select s.name

open Dbapi.QuerySyntax in
def exactName (n : String) := query
  from s in Student
  where s.name == n
  select s.id

def schemas : List Schema :=
  [Model.schema School.Of, Model.schema Student.Of, Model.schema Submission.Of]

def seedRows (db : MemDb) : Json :=
  Json.arr <| (schemas.flatMap fun s => (db.rows s).map fun r =>
    let (sql, ps) := (Write.insert s r).render .postgres
    let (sqlL, _) := (Write.insert s r).render .sqlite
    Json.mkObj [("postgres", sql), ("sqlite", sqlL), ("params", Json.arr (ps.map Value.toJson))]).toArray

def exportJson : Json :=
  let db := seed2
  Json.mkObj [
    ("ddl", Json.mkObj [
      ("postgres", Json.arr (schemas.toArray.map fun s => Json.str (s.createTable .postgres))),
      ("sqlite", Json.arr (schemas.toArray.map fun s => Json.str (s.createTable .sqlite)))]),
    ("seed", seedRows db),
    ("queries", Json.arr #[
      caseQ "olderStudents (builder)" (olderStudentsB 1) db,
      caseQ "olderStudents (embedded)" (olderStudentsE 1) db,
      caseQ "topScores (builder)" (topScoresB 7) db,
      caseQ "topScores (embedded)" (topScoresE 7) db,
      caseQ "schoolScores (3 tables)" (schoolScoresE 7 "Northside") db,
      caseQ "byName (text ordering)" (byName 2) db,
      caseQ "exactName 'ada' (case)" (exactName "ada") db,
      caseQ "inList preload" ((selectFrom Submission).filter (fun s =>
        Expr.inList s.studentId [10, 11]) |>.orderBy (fun s => s.id) |>.select fun s => s) db])]

#eval IO.FS.writeFile "difftest.json" exportJson.pretty

end Demo
