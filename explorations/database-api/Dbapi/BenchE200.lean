import Dbapi.Demo
namespace BenchE200
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
open Dbapi.QuerySyntax in
def q50 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 50
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q51 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 51
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q52 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 52
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q53 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 53
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q54 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 54
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q55 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 55
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q56 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 56
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q57 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 57
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q58 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 58
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q59 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 59
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q60 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 60
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q61 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 61
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q62 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 62
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q63 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 63
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q64 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 64
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q65 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 65
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q66 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 66
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q67 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 67
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q68 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 68
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q69 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 69
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q70 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 70
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q71 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 71
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q72 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 72
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q73 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 73
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q74 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 74
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q75 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 75
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q76 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 76
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q77 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 77
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q78 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 78
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q79 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 79
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q80 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 80
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q81 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 81
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q82 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 82
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q83 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 83
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q84 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 84
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q85 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 85
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q86 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 86
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q87 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 87
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q88 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 88
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q89 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 89
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q90 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 90
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q91 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 91
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q92 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 92
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q93 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 93
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q94 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 94
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q95 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 95
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q96 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 96
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q97 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 97
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q98 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 98
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q99 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 99
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q100 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 100
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q101 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 101
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q102 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 102
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q103 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 103
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q104 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 104
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q105 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 105
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q106 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 106
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q107 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 107
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q108 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 108
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q109 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 109
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q110 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 110
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q111 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 111
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q112 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 112
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q113 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 113
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q114 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 114
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q115 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 115
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q116 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 116
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q117 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 117
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q118 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 118
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q119 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 119
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q120 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 120
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q121 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 121
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q122 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 122
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q123 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 123
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q124 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 124
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q125 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 125
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q126 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 126
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q127 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 127
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q128 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 128
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q129 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 129
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q130 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 130
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q131 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 131
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q132 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 132
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q133 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 133
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q134 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 134
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q135 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 135
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q136 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 136
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q137 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 137
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q138 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 138
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q139 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 139
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q140 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 140
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q141 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 141
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q142 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 142
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q143 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 143
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q144 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 144
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q145 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 145
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q146 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 146
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q147 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 147
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q148 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 148
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q149 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 149
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q150 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 150
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q151 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 151
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q152 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 152
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q153 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 153
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q154 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 154
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q155 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 155
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q156 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 156
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q157 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 157
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q158 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 158
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q159 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 159
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q160 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 160
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q161 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 161
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q162 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 162
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q163 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 163
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q164 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 164
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q165 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 165
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q166 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 166
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q167 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 167
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q168 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 168
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q169 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 169
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q170 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 170
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q171 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 171
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q172 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 172
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q173 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 173
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q174 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 174
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q175 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 175
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q176 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 176
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q177 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 177
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q178 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 178
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q179 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 179
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q180 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 180
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q181 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 181
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q182 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 182
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q183 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 183
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q184 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 184
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q185 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 185
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q186 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 186
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q187 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 187
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q188 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 188
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q189 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 189
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q190 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 190
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q191 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 191
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q192 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 192
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q193 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 193
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q194 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 194
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q195 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 195
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q196 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 196
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q197 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 197
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q198 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 198
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
open Dbapi.QuerySyntax in
def q199 (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 199
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
end BenchE200
