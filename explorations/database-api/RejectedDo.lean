import Dbapi.DemoDo

namespace Demo
open Dbapi

-- A: comparing an integer column with a text column
open Dbapi.Do in
def a2 := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.score == st.name)
  select s.id

-- B: misspelled column
open Dbapi.Do in
def b2 := query% do
  let s ← from Student
  guard (s.agee > 12)
  select s.name

-- C: a table variable from outside the query
open Dbapi.Do in
def c2 (r : Student.Of (Do.PExpr Do.Alias)) := query% do
  let sc ← from School
  guard (r.age > 12)
  select sc.name

end Demo
