module

import EspalJson
meta import EspalJson
import EspalRoute
meta import EspalRoute

/-!
Tests for `Created`. A handler that makes a resource answers `201` with a `Location` header, and
gets the link to another row of its own table through a `LinkTo` instance argument.
-/

open Espal Routing Json

namespace ApiCreatedTests

structure NewUser where
  name : String
  deriving Json

structure User where
  id : Int32
  name : String
  deriving Json

inductive SignupError where
  | conflict
  deriving Problem

def showUser (_ : Public) (id : Nat) (tab : Option String) : Text :=
  s!"user {id} {tab}"

def createUser (_ : Public) [LinkTo showUser (Nat → Option String → Link)] (user : NewUser) :
    Created User :=
  ⟨linkTo showUser 7 (some "a b"), ⟨7, user.name⟩⟩

def signUp (_ : Public) [LinkTo showUser (Nat → Option String → Link)] (user : NewUser) :
    Fails SignupError (Created Text) :=
  if user.name == "taken" then .error .conflict else .ok ⟨linkTo showUser 8 none, "welcome"⟩

api Users where
  GET "/users/:id" => showUser
  POST "/users" => createUser
  POST "/signup" => signUp

/-- The status, `Location` header and text that `POST path` answers the JSON `body` with. -/
def post (path : List String) (body : String) : Option (UInt16 × Option String × String) := do
  let (_, endpoint) ← matchTable Users.routes .post path
  let reply := endpoint.reply [] (some "application/json") body.toUTF8
  return (reply.status, (reply.headers.find? (·.1 == "location")).map (·.2),
      ← String.fromUTF8? reply.body)

/-! The reply is `201`, with the link as a URL and the value's own body. -/

#guard
  post ["users"] "{\"name\":\"Ada\"}" ==
    some (201, some "/users/7?tab=a%20b", "{\"id\":7,\"name\":\"Ada\"}")

#guard
  ((matchTable Users.routes .post ["users"]).map fun (_, endpoint) =>
      (endpoint.reply [] (some "application/json") "{\"name\":\"Ada\"}".toUTF8).contentType) ==
    some "application/json"

/-! A handler that can fail answers `201` only when it succeeds. -/

#guard post ["signup"] "{\"name\":\"Bo\"}" == some (201, some "/users/8", "welcome")

#guard (post ["signup"] "{\"name\":\"taken\"}").map (fun r => (r.1, r.2.1)) == some (409, none)

/-! The link in `Location` reaches the row it names, with the arguments it was built from. -/

example :
    (matchTable Users.routes .get (linkTo showUser 7 (some "a b")).path).map
        (fun m => m.2.reply (linkTo showUser 7 (some "a b")).query none .empty) =
      some (toReply (showUser {} 7 (some "a b"))) :=
  Users.linkTo_showUser 7 (some "a b") none .empty

/-! A handler with a link argument has its own `linkTo`, without that argument. -/

#guard linkTo createUser == ⟨["users"], []⟩

/-! A value in a link can't put a line break into the header. -/

#guard
  (toReply (⟨⟨["a\r\nx: y"], [("k", "v\r\nz")]⟩, ("" : Text)⟩ : Created Text)).headers ==
    [("location", "/a%0D%0Ax:%20y?k=v%0D%0Az")]

/-! Any other implicit argument is still refused. -/

def implicitArg (_ : Public) {n : Nat} : Text :=
  s!"{n}"

/--
error: handler `ApiCreatedTests.implicitArg` takes `n` as an implicit argument, which an `api` row has no way to fill.
-/
#guard_msgs in
api Bad where
  GET "/x" => implicitArg

end ApiCreatedTests
