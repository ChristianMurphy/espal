import Cedar.Spec
import Cedar.Slice.PolicySlice

/-!
Times Cedar's `isAuthorized` on policies shaped like Espal's tenant app, a grading app with users,
roles, courses, assignments and submissions. It checks each request's decision first, then times
every combination of policy count and entity count over several runs, against all policies and
against the scope-based slice that `Cedar.Thm.isAuthorized_eq_for_scope_based_policy_slice` proves
gives the same response.
-/

open Cedar.Spec Cedar.Data Cedar.Slice

def ty (id : String) : EntityType := { id, path := [] }
def uid (t e : String) : EntityUID := { ty := ty t, eid := e }
def act (a : String) : EntityUID := uid "Action" a

def principal : Expr := .var .principal
def resource : Expr := .var .resource
def attr (e : Expr) (a : String) : Expr := .getAttr e a
def mem (a b : Expr) : Expr := .binaryApp .mem a b
def eq (a b : Expr) : Expr := .binaryApp .eq a b

def policy (id : String) (effect : Effect) (p : Scope) (a : ActionScope) (r : Scope)
    (when : List Expr := []) : Policy :=
  { id, effect, principalScope := .principalScope p, actionScope := a,
    resourceScope := .resourceScope r, condition := when.map ({ kind := .when, body := · }) }

/-- The rules a grading app needs. A forbid closes an assignment to submissions. -/
def basePolicies : Policies := [
  policy "admin" .permit (.mem (uid "Role" "admin")) (.actionScope .any) .any,
  policy "grade" .permit (.mem (uid "Role" "teacher")) (.actionScope (.eq (act "grade")))
    (.is (ty "Submission")) [mem principal (attr resource "course")],
  policy "submit" .permit .any (.actionScope (.eq (act "submit"))) (.is (ty "Assignment"))
    [mem principal (attr resource "course")],
  policy "view-own" .permit .any (.actionScope (.eq (act "view"))) (.is (ty "Submission"))
    [eq (attr resource "owner") principal],
  policy "closed" .forbid .any (.actionScope (.eq (act "submit"))) (.is (ty "Assignment"))
    [attr resource "closed"],
  policy "suspended" .forbid (.mem (uid "Role" "suspended")) (.actionScope .any) .any]

/-- `n` more permits, one per course, such as a teaching assistant's grading rights. -/
def extraPolicies (n : Nat) : Policies :=
  (List.range n).map fun i =>
    policy s!"ta-{i}" .permit (.eq (uid "User" s!"ta{i}")) (.actionScope (.eq (act "grade")))
      (.mem (uid "Course" s!"c{i + 100}"))

def entity (attrs : List (Attr × Value)) (ancestors : List EntityUID) : EntityData :=
  { attrs := Map.make attrs, ancestors := Set.make ancestors, tags := Map.empty }

def ref (u : EntityUID) : Value := .prim (.entityUID u)

/--
The entities the four requests touch, plus `n` users that none of them touch. The extra users sort
first, so each lookup of a user in `Map.find?`'s linear scan passes all of them.
-/
def entities (n : Nat) : Entities :=
  let c1 := uid "Course" "c1"
  Map.make <| [
    (uid "User" "teacher", entity [] [uid "Role" "teacher", c1]),
    (uid "User" "student", entity [] [c1]),
    (uid "User" "other", entity [] [c1]),
    (uid "Submission" "s1", entity [("course", ref c1), ("owner", ref (uid "User" "student"))] [c1]),
    (uid "Assignment" "a1", entity [("course", ref c1), ("closed", .prim (.bool true))] [c1])] ++
    (List.range n).map fun i => (uid "User" s!"a{i}", entity [] [uid "Course" s!"c{i}"])

def request (p a r : EntityUID) : Request :=
  { principal := p, action := a, resource := r, context := Map.empty }

/-- Four requests and the decision each should get. -/
def requests : Array (String × Request × Decision) := #[
  ("teacher grades a submission", request (uid "User" "teacher") (act "grade") (uid "Submission" "s1"), .allow),
  ("student views own submission", request (uid "User" "student") (act "view") (uid "Submission" "s1"), .allow),
  ("student submits to a closed assignment", request (uid "User" "student") (act "submit") (uid "Assignment" "a1"), .deny),
  ("other user views the submission", request (uid "User" "other") (act "view") (uid "Submission" "s1"), .deny)]

def decision (r : Response) : String :=
  match r.decision with
  | .allow => "allow"
  | .deny => "deny"

/-- Mean µs per call of `authorize` over `iters` calls that cycle through the requests. -/
def time (iters : Nat) (authorize : Request → Response) : IO Float := do
  let start ← IO.monoNanosNow
  let mut allows := 0
  for k in [0:iters] do
    if let some (_, req, _) := requests[k % requests.size]? then
      if (authorize req).decision == Decision.allow then allows := allows + 1
  let stop ← IO.monoNanosNow
  if allows == 12345678 then IO.println "unlikely"
  return (stop - start).toFloat / iters.toFloat / 1000.0

def fmt (x : Float) : String :=
  let c := (x * 100).round.toUInt64.toNat
  s!"{c / 100}.{if c % 100 < 10 then "0" else ""}{c % 100}"

def main (args : List String) : IO UInt32 := do
  let runs := (args.head? >>= String.toNat?).getD 5
  let mut wrong := 0
  for n in [0, 100, 1000] do
    for m in [0, 100, 1000] do
      for (name, req, want) in requests do
        let ps := basePolicies ++ extraPolicies n
        let es := entities m
        let got := (isAuthorized req es ps).decision
        let sliced := (isAuthorized req es (BoundAnalysis.slice scopeAnalysis req es ps)).decision
        if got != want || sliced != want then
          IO.println s!"wrong decision for {name} with {n} extra policies and {m} extra entities"
          wrong := wrong + 1
  if wrong > 0 then return 1
  IO.println "all decisions as expected"
  IO.println "policies,entities,run,us_all_policies,us_sliced"
  for n in [0, 100, 1000] do
    for m in [0, 100, 1000] do
      let ps := basePolicies ++ extraPolicies n
      let es := entities m
      let iters := if n + m ≥ 1000 then 2000 else 20000
      for r in [0:runs] do
        let all ← time iters (isAuthorized · es ps)
        let sliced ← time iters fun req => isAuthorized req es (BoundAnalysis.slice scopeAnalysis req es ps)
        IO.println s!"{ps.length},{m + 5},{r},{fmt all},{fmt sliced}"
  return 0
