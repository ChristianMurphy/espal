import Dbapi.Demo

namespace Demo
open Dbapi

-- A: comparing an integer column with a text column, builder
def a1 := (selectFrom Submission) |>.join Student (fun s st => s.score ==. st.name) |>.select fun s _ => s.id

-- B: the same mistake, embedded syntax
open Dbapi.QuerySyntax in
def b1 := query
  from s in Submission
  join st in Student on s.score == st.name
  select s.id

-- C: misspelled column, builder
def c1 := (selectFrom Student) |>.filter (fun s => s.agee >. 12) |>.select fun s => s.name

-- D: misspelled column, embedded
open Dbapi.QuerySyntax in
def d1 := query
  from s in Student
  where s.agee > 12
  select s.name

-- E: a query per student (N+1)
def e1 (students : List Student) := students.mapM (·.submissions)

-- F: an early return sends fewer statements than the other branch
def f1 (sid : Int) : DbM 2 (Option School) :=
  (Student.find sid).bind fun
    | some st => st.school
    | none => DbM.pure none

-- G: unsupported column type in a model
model Event "events" where
  id : Int
  startsAt : Float

-- H: four tables
open Dbapi.QuerySyntax in
def h1 := query
  from s in Submission
  join st in Student on s.studentId == st.id
  join sc in School on st.schoolId == sc.id
  join sc2 in School on sc2.id == sc.id
  select s.id

-- I: query keywords are free identifiers outside `open Dbapi.QuerySyntax`
def select := 1
def limit := 2
#eval select + limit

end Demo
