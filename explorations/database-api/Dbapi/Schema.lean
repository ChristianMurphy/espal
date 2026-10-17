import Dbapi.Models

/-! The example schema, declared with the `model` command. -/

namespace Demo
open Dbapi

model School "schools" where
  id : Int
  name : String

model Student "students" where
  id : Int
  schoolId : Int
  name : String
  age : Int
  belongsTo school : School via schoolId

model Submission "submissions" where
  id : Int
  studentId : Int
  assessmentId : Int
  score : Int
  belongsTo student : Student via studentId

relations School where
  hasMany students : Student via schoolId

relations Student where
  hasMany submissions : Submission via studentId

/-- Seed data for the in-memory database. -/
def seed : MemDb :=
  let ins {F} [Model F] (db : MemDb) (r : F SqlTy.denote) := db.insert (Model.schema F) (Model.toRow r)
  let db : MemDb := []
  let db := ins db ({ id := 1, name := "Northside" } : School)
  let db := ins db ({ id := 2, name := "Riverside" } : School)
  let db := ins db ({ id := 10, schoolId := 1, name := "Ada", age := 12 } : Student)
  let db := ins db ({ id := 11, schoolId := 1, name := "Grace", age := 13 } : Student)
  let db := ins db ({ id := 12, schoolId := 2, name := "Alan", age := 12 } : Student)
  let db := ins db ({ id := 100, studentId := 10, assessmentId := 7, score := 91 } : Submission)
  let db := ins db ({ id := 101, studentId := 11, assessmentId := 7, score := 78 } : Submission)
  let db := ins db ({ id := 102, studentId := 12, assessmentId := 7, score := 85 } : Submission)
  let db := ins db ({ id := 103, studentId := 10, assessmentId := 8, score := 64 } : Submission)
  db

end Demo
