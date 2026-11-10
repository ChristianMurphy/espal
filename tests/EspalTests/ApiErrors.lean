module

import EspalJson
meta import EspalJson
import EspalRoute
meta import EspalRoute

/-!
Tests for handlers that can fail. A `Fails ε α` answers its value's reply, or an error's
problem with the error's own status. `deriving instance Problem` takes each constructor's status from
a `status` attribute or from a well-known name, and refuses a constructor it can't give one.
-/

open Espal Routing Json

namespace ApiErrorTests

inductive SubmitError where
  | notFound
  | closed (deadline : Int64) (reason : String)
  | tooManyTries

attribute [status 409] SubmitError.closed

attribute [status 430] SubmitError.tooManyTries

deriving instance Problem for SubmitError

structure Submission where
  answer : String
  deriving Json

structure Receipt where
  id : Int32
  deriving Json

def submit (_ : Public) (id : Nat) (body : Submission) : Fails SubmitError Receipt := do
  if id == 0 then
    throw .notFound
  if body.answer == "late" then
    throw (.closed 1700000000 "past the deadline")
  if body.answer == "again" then
    throw .tooManyTries
  return ⟨7⟩

def find (_ : Public) (id : Nat) : Fails NotFound Text :=
  if id == 0 then throw {} else pure s!"item {id}"

def hello (_ : Public) : Handler Text :=
  pure "Hello, World!"

api Work where
  GET "/hello" => hello
  GET "/items/:id" => find
  POST "/work/:id" => submit

/-- The status and text that the route for `method` and `path` answers `body` with. -/
def answer (method : Std.Http.Method) (path : List String) (body : String := "") :
    Option (UInt16 × String) := do
  let (_, endpoint) ← matchTable Work.routes method path
  let reply := endpoint.reply [] body.toUTF8
  return (reply.status, ← String.fromUTF8? reply.body)

/-! A handler that can't fail, and one that succeeds, answer with the value. -/

#guard answer .get ["hello"] == some (200, "Hello, World!")

#guard answer .get (pathTo find 3) == some (200, "item 3")

#guard answer .post (pathTo submit 3) "{\"answer\":\"ok\"}" == some (200, "{\"id\":7}")

/-! An error answers its own status as a problem. A well-known name needs no `status` attribute, and
each argument becomes a member. -/

#guard
  answer .get (pathTo find 0) ==
    some (404, "{\"type\":\"/problems/not-found\",\"title\":\"Not found\",\"status\":404}")

#guard
  answer .post (pathTo submit 0) "{\"answer\":\"ok\"}" ==
    some (404, "{\"type\":\"/problems/not-found\",\"title\":\"Not found\",\"status\":404}")

#guard
  answer .post (pathTo submit 3) "{\"answer\":\"late\"}" ==
    some
      (409,
        "{\"type\":\"/problems/closed\",\"title\":\"Closed\",\"status\":409,\
          \"deadline\":\"1700000000\",\"reason\":\"past the deadline\"}")

#guard
  answer .post (pathTo submit 3) "{\"answer\":\"again\"}" ==
    some
      (430, "{\"type\":\"/problems/too-many-tries\",\"title\":\"Too many tries\",\"status\":430}")

/-! A body that doesn't decode still gets its `422`, before the handler can fail. -/

#guard (answer .post (pathTo submit 0) "{}").map (·.1) == some 422

/-! The handler refuses a constructor it can't answer for. -/

/--
error: cannot derive Problem for NoStatus: the constructor outOfStock has no status. Add `attribute [status 409] ApiErrorTests.NoStatus.outOfStock` before deriving
-/
#guard_msgs in
inductive NoStatus where
  | outOfStock
  deriving Problem

inductive BadStatus where
  | fine

attribute [status 200] BadStatus.fine

/-- error: cannot derive Problem for BadStatus: the constructor fine has status 200, which is no error status -/
#guard_msgs in
deriving instance Problem for BadStatus

/--
error: cannot derive Problem for Unnamed: an argument of gone has no name to use as its key. Name it, as in `gone (reason : String)`
-/
#guard_msgs in
inductive Unnamed where
  | gone : String → Unnamed
  deriving Problem

/-- error: cannot derive Problem for Clash: the argument title of conflict uses a key every problem has -/
#guard_msgs in
inductive Clash where
  | conflict (title : String)
  deriving Problem

/-- A type with no JSON encoder. -/
structure Opaque where
  n : Nat

/--
error: cannot derive Problem for NoJson: the argument cause of conflict has type Opaque, which has no ToJson instance
-/
#guard_msgs in
inductive NoJson where
  | conflict (cause : Opaque)
  deriving Problem

end ApiErrorTests
