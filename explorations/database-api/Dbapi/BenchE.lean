import Dbapi.Demo
namespace BenchE
open Dbapi Demo
open Dbapi.QuerySyntax in
def q0 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 0
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q1 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 1
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q2 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 2
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q3 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 3
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q4 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 4
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q5 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 5
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q6 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 6
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q7 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 7
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q8 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 8
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q9 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 9
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q10 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 10
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q11 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 11
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q12 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 12
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q13 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 13
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q14 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 14
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q15 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 15
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q16 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 16
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q17 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 17
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q18 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 18
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q19 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 19
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q20 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 20
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q21 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 21
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q22 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 22
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q23 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 23
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q24 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 24
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q25 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 25
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q26 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 26
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q27 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 27
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q28 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 28
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q29 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 29
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q30 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 30
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q31 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 31
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q32 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 32
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q33 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 33
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q34 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 34
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q35 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 35
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q36 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 36
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q37 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 37
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q38 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 38
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q39 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 39
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q40 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 40
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q41 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 41
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q42 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 42
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q43 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 43
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q44 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 44
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q45 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 45
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q46 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 46
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q47 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 47
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q48 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 48
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q49 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 49
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
end BenchE
