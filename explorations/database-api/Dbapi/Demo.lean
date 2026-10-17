import Dbapi.Schema
import Dbapi.Embedded

/-! The same queries in each style, run on the in-memory database and rendered per dialect. -/

namespace Demo
open Dbapi

/-! ## One table -/

def olderStudentsB (school : Int) :=
  (selectFrom Student)
    |>.filter (fun s => s.schoolId ==. school &&. s.age >=. 12)
    |>.orderBy (fun s => s.name)
    |>.limit 20
    |>.select (fun s => (s.name, s.age))

open Dbapi.QuerySyntax in
def olderStudentsE (school : Int) := query
  from s in Student
  where s.schoolId == school && s.age >= 12
  order by s.name
  limit 20
  select (s.name, s.age)

/-! ## Two tables -/

def topScoresB (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 50)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))

open Dbapi.QuerySyntax in
def topScoresE (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 50
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)

/-! ## Three tables -/

open Dbapi.QuerySyntax in
def schoolScoresE (a : Int) (school : String) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  join sc in School on st.schoolId == sc.id
  where s.assessmentId == a && sc.name == school
  order by st.name
  select (st.name, s.score)

/-! ## Models and relations, with statement budgets -/

/-- Two statements however many students the school has. -/
def schoolReport (school : Int) : DbM 2 (List (Student × List Submission)) :=
  (DbM.all ((selectFrom Student).filter (fun s => s.schoolId ==. school) |>.select fun s => s)).bind
    Student.withSubmissions

/-- Insert, then read back: two statements. -/
def recordScore (row : Submission) : DbM 2 (Option Submission) :=
  (Submission.insert row).bind fun _ => Submission.find row.id

/-! ## Results -/

def showAll {Γ R} (q : Select Γ R) : String :=
  "\n".intercalate ([Dialect.postgres, .sqlite, .mysql, .mssql].map fun d =>
    let (sql, ps) := q.render d
    s!"{repr d}: {sql}   -- {ps.size} params")

#eval (olderStudentsB 1).evalOn seed
#eval (olderStudentsE 1).evalOn seed
#eval IO.println (showAll (topScoresB 7))
#eval (topScoresE 7).evalOn seed
#eval (schoolScoresE 7 "Northside").evalOn seed
#eval IO.println (showAll (schoolScoresE 7 "Northside"))

#eval
  let r : List (Student × List Submission) × MemDb × List String :=
    (schoolReport 1).runMem .postgres seed
  (r.1.map fun p => (p.1.name, p.2.map (·.score)), r.2.2)

#eval
  let r : Option Submission × MemDb × List String :=
    (recordScore { id := 104, studentId := 11, assessmentId := 8, score := 70 }).runMem .mysql seed
  (r.1.map (·.score), r.2.2)

/-- The builder and the embedded syntax produce the same SQL. -/
example : (topScoresB 7).render .postgres = (topScoresE 7).render .postgres := by native_decide

end Demo
