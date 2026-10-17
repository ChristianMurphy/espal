import Dbapi.DemoDo
namespace BenchD200
open Dbapi Demo
open Dbapi.Do in
def q0 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 0)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q1 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 1)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q2 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 2)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q3 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 3)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q4 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 4)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q5 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 5)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q6 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 6)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q7 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 7)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q8 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 8)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q9 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 9)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q10 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 10)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q11 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 11)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q12 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 12)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q13 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 13)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q14 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 14)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q15 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 15)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q16 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 16)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q17 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 17)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q18 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 18)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q19 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 19)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q20 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 20)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q21 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 21)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q22 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 22)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q23 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 23)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q24 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 24)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q25 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 25)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q26 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 26)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q27 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 27)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q28 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 28)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q29 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 29)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q30 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 30)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q31 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 31)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q32 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 32)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q33 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 33)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q34 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 34)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q35 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 35)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q36 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 36)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q37 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 37)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q38 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 38)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q39 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 39)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q40 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 40)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q41 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 41)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q42 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 42)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q43 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 43)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q44 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 44)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q45 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 45)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q46 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 46)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q47 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 47)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q48 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 48)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q49 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 49)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q50 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 50)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q51 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 51)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q52 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 52)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q53 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 53)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q54 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 54)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q55 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 55)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q56 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 56)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q57 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 57)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q58 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 58)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q59 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 59)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q60 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 60)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q61 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 61)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q62 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 62)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q63 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 63)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q64 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 64)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q65 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 65)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q66 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 66)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q67 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 67)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q68 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 68)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q69 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 69)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q70 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 70)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q71 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 71)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q72 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 72)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q73 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 73)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q74 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 74)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q75 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 75)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q76 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 76)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q77 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 77)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q78 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 78)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q79 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 79)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q80 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 80)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q81 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 81)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q82 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 82)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q83 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 83)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q84 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 84)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q85 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 85)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q86 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 86)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q87 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 87)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q88 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 88)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q89 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 89)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q90 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 90)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q91 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 91)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q92 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 92)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q93 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 93)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q94 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 94)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q95 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 95)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q96 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 96)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q97 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 97)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q98 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 98)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q99 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 99)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q100 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 100)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q101 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 101)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q102 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 102)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q103 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 103)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q104 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 104)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q105 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 105)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q106 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 106)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q107 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 107)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q108 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 108)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q109 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 109)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q110 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 110)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q111 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 111)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q112 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 112)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q113 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 113)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q114 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 114)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q115 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 115)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q116 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 116)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q117 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 117)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q118 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 118)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q119 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 119)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q120 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 120)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q121 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 121)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q122 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 122)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q123 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 123)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q124 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 124)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q125 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 125)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q126 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 126)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q127 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 127)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q128 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 128)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q129 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 129)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q130 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 130)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q131 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 131)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q132 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 132)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q133 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 133)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q134 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 134)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q135 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 135)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q136 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 136)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q137 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 137)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q138 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 138)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q139 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 139)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q140 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 140)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q141 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 141)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q142 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 142)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q143 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 143)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q144 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 144)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q145 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 145)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q146 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 146)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q147 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 147)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q148 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 148)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q149 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 149)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q150 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 150)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q151 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 151)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q152 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 152)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q153 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 153)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q154 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 154)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q155 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 155)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q156 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 156)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q157 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 157)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q158 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 158)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q159 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 159)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q160 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 160)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q161 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 161)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q162 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 162)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q163 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 163)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q164 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 164)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q165 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 165)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q166 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 166)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q167 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 167)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q168 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 168)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q169 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 169)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q170 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 170)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q171 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 171)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q172 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 172)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q173 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 173)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q174 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 174)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q175 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 175)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q176 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 176)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q177 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 177)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q178 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 178)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q179 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 179)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q180 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 180)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q181 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 181)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q182 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 182)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q183 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 183)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q184 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 184)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q185 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 185)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q186 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 186)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q187 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 187)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q188 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 188)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q189 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 189)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q190 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 190)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q191 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 191)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q192 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 192)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q193 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 193)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q194 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 194)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q195 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 195)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q196 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 196)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q197 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 197)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q198 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 198)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.Do in
def q199 (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 199)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
end BenchD200
