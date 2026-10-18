import Trial.Schema

/-!
How lean-linq's operation budgets compare with Espal's statement budget. Each section is one
program shape, with the error message lean-linq gives when it rejects it.
-/

open LeanLinq

namespace Trial

/-! A bounded fan-out type-checks: at most `n` rows, then one query for each, so `n + 1`. -/

def bounded (t : Int) (n : Nat) : Db Exam (Grade.nat n + 1) (List Nat) := db! {
  let subs ← (ofTenant t).fetchLimit n
  let counts ← for s in subs.val do
    Query.from' (ts := Exam) assessments
      |>.where' (fun a => a["id"] ==. s["assessment_id"])
      |>.execQuery
      |>.map (·.length)
  return counts
}

#guard ((bounded 1 5).exec 6 empty).toOption == some []

/-! A query for each element of a list derived from fetched rows doesn't type-check, but the error
names a type class instead of the loop. -/

/--
error: failed to synthesize instance of type class
  HasBillF
-/
#guard_msgs (substring := true) in
def derived (t : Int) := db! {
  let subs ← (ofTenant t).execQuery
  let ids := subs.map (·["assessment_id"])
  let titles ← for i in ids do
    (Query.from' (ts := Exam) assessments |>.where' (fun a => a["id"] ==. SqlExpr.long i)).execQuery
  return titles.length
}

/-! A query for each fetched row type-checks, priced by the table's size. -/

def perRow (t : Int) : Db Exam (submissions.size + 1) (List Nat) := db! {
  let subs ← (ofTenant t).execQuery
  let counts ← for s in subs do
    Query.from' (ts := Exam) assessments
      |>.where' (fun a => a["id"] ==. s["assessment_id"])
      |>.execQuery
      |>.map (·.length)
  return counts
}

/-! No fixed budget covers a price in table sizes, so `exec` (and `execPg`) refuse it. -/

/-- error: could not synthesize default value for parameter '_h' using tactics -/
#guard_msgs (substring := true) in
#check (perRow 1).exec 1000 empty

/-! `mapM` needs a `Monad`, which `Db` doesn't have. -/

/-- error: Application type mismatch -/
#guard_msgs (substring := true) in
def viaMapM (ids : List Int) := db! {
  let rows ← ids.mapM fun i =>
    (Query.from' (ts := Exam) assessments |>.where' (fun a => a["id"] ==. SqlExpr.long i)).execQuery
  return rows.length
}

/-! Branches with different costs need one bound. `weaken` raises the cheaper branch to it. -/

/-- error: Application type mismatch -/
#guard_msgs (substring := true) in
def branch (flag : Bool) : Db Exam 1 Nat :=
  if flag then (Query.from' (ts := Exam) assessments).execQuery |>.map (·.length)
  else Db.pure 0

def branchWeakened (flag : Bool) : Db Exam 1 Nat :=
  if flag then (Query.from' (ts := Exam) assessments).execQuery |>.map (·.length)
  else (DbP.relax (Db.pure 0)).weaken 1

#guard ((branchWeakened false).exec 1 empty).toOption == some 0

end Trial
