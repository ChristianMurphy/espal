import Dbapi.Demo
namespace BenchB
open Dbapi Demo
def q0 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 0)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q1 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 1)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q2 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 2)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q3 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 3)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q4 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 4)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q5 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 5)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q6 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 6)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q7 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 7)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q8 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 8)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q9 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 9)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q10 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 10)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q11 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 11)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q12 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 12)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q13 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 13)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q14 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 14)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q15 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 15)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q16 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 16)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q17 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 17)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q18 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 18)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q19 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 19)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q20 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 20)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q21 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 21)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q22 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 22)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q23 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 23)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q24 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 24)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q25 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 25)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q26 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 26)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q27 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 27)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q28 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 28)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q29 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 29)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q30 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 30)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q31 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 31)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q32 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 32)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q33 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 33)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q34 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 34)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q35 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 35)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q36 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 36)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q37 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 37)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q38 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 38)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q39 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 39)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q40 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 40)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q41 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 41)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q42 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 42)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q43 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 43)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q44 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 44)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q45 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 45)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q46 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 46)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q47 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 47)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q48 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 48)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q49 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 49)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
end BenchB
