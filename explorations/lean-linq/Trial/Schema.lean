import LeanLinq

/-!
A cut-down tenant app schema: assessments and the submissions made against them, each tagged with
its tenant.
-/

open LeanLinq

namespace Trial

abbrev AssessmentsS : Schema := [("id", .long), ("tenant_id", .long), ("title", .string)]
def assessments : Table "assessments" AssessmentsS := ⟨⟩

abbrev SubmissionsS : Schema :=
  [("id", .long), ("tenant_id", .long), ("assessment_id", .long), ("score", .null .int)]
def submissions : Table "submissions" SubmissionsS := ⟨⟩

abbrev Exam : Ctx :=
  { tables := [("assessments", AssessmentsS), ("submissions", SubmissionsS)] }

/-- One tenant's submissions. -/
def ofTenant (t : Int) :=
  Query.from' (ts := Exam) submissions |>.where' (fun s => s["tenant_id"] ==. SqlExpr.long t)

/-- An empty database for the in-memory evaluator. -/
def empty : TableEnv Exam.tables := .cons [] (.cons [] .nil)

end Trial
