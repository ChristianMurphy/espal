import Dbapi.Schema
import Dbapi.DoNotation

/-! The demo queries in `do` notation. -/

namespace Demo
open Dbapi

open Dbapi.Do in
def olderStudentsD (school : Int) := query% do
  let s ← from Student
  guard (s.schoolId == school && s.age >= 12)
  orderBy s.name
  limit 20
  select (s.name, s.age)

open Dbapi.Do in
def topScoresD (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 50)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)

open Dbapi.Do in
def schoolScoresD (a : Int) (school : String) := query% do
  let s ← from Submission
  let st ← from Student
  let sc ← from School
  guard (s.studentId == st.id && st.schoolId == sc.id)
  guard (s.assessmentId == a && sc.name == school)
  orderBy st.name
  select (st.name, s.score)

open Dbapi.Do in
/-- Optional filters use ordinary `if`; each call builds a different statement. -/
def search (school : Option Int) (minAge : Option Int) := query% do
  let s ← from Student
  if let some sc := school then guard (s.schoolId == sc)
  if let some m := minAge then guard (s.age >= m)
  orderBy s.name
  select (s.name, s.age)

#eval Do.evalOn (topScoresD 7) seed
#eval Do.evalOn (schoolScoresD 7 "Northside") seed
#eval (Do.render (topScoresD 7) .postgres).1
#eval (Do.render (search none none) .postgres).1
#eval (Do.render (search (some 1) (some 13)) .postgres)
#eval Do.evalOn (search (some 1) (some 13)) seed

end Demo
