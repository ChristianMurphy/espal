import Dbapi.Demo
namespace BenchB200
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
def q50 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 50)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q51 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 51)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q52 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 52)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q53 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 53)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q54 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 54)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q55 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 55)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q56 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 56)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q57 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 57)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q58 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 58)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q59 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 59)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q60 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 60)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q61 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 61)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q62 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 62)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q63 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 63)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q64 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 64)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q65 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 65)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q66 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 66)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q67 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 67)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q68 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 68)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q69 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 69)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q70 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 70)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q71 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 71)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q72 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 72)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q73 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 73)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q74 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 74)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q75 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 75)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q76 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 76)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q77 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 77)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q78 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 78)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q79 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 79)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q80 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 80)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q81 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 81)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q82 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 82)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q83 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 83)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q84 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 84)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q85 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 85)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q86 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 86)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q87 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 87)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q88 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 88)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q89 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 89)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q90 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 90)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q91 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 91)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q92 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 92)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q93 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 93)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q94 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 94)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q95 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 95)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q96 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 96)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q97 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 97)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q98 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 98)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q99 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 99)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q100 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 100)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q101 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 101)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q102 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 102)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q103 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 103)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q104 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 104)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q105 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 105)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q106 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 106)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q107 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 107)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q108 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 108)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q109 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 109)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q110 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 110)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q111 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 111)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q112 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 112)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q113 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 113)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q114 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 114)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q115 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 115)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q116 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 116)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q117 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 117)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q118 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 118)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q119 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 119)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q120 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 120)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q121 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 121)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q122 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 122)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q123 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 123)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q124 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 124)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q125 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 125)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q126 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 126)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q127 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 127)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q128 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 128)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q129 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 129)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q130 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 130)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q131 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 131)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q132 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 132)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q133 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 133)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q134 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 134)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q135 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 135)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q136 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 136)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q137 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 137)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q138 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 138)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q139 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 139)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q140 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 140)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q141 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 141)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q142 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 142)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q143 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 143)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q144 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 144)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q145 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 145)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q146 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 146)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q147 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 147)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q148 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 148)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q149 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 149)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q150 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 150)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q151 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 151)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q152 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 152)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q153 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 153)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q154 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 154)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q155 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 155)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q156 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 156)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q157 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 157)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q158 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 158)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q159 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 159)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q160 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 160)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q161 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 161)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q162 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 162)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q163 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 163)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q164 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 164)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q165 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 165)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q166 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 166)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q167 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 167)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q168 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 168)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q169 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 169)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q170 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 170)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q171 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 171)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q172 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 172)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q173 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 173)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q174 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 174)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q175 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 175)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q176 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 176)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q177 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 177)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q178 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 178)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q179 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 179)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q180 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 180)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q181 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 181)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q182 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 182)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q183 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 183)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q184 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 184)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q185 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 185)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q186 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 186)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q187 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 187)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q188 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 188)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q189 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 189)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q190 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 190)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q191 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 191)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q192 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 192)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q193 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 193)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q194 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 194)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q195 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 195)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q196 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 196)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q197 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 197)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q198 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 198)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
def q199 (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 199)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
end BenchB200
