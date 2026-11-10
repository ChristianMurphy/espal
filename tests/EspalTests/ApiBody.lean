module

import EspalJson
meta import EspalJson
import EspalRoute
meta import EspalRoute

/-!
Tests for request bodies in the `api` command. A handler's argument that no capture names is the
body. Its endpoint decodes the bytes before the handler runs, and answers the `400` or `422`
problem when they don't decode. Handlers in one table can return different types.
-/

open Espal Routing Json

namespace ApiBodyTests

structure NewUser where
  name : String
  age : Small
  adult : age.val ≥ 18
  deriving Json

structure Created where
  id : Int32
  name : String
  deriving Json

def hello (_ : Public) : Text :=
  "Hello, World!"

def createUser (_ : Public) (user : NewUser) : Created :=
  ⟨1, user.name⟩

def renameUser (_ : Public) (id : Nat) (user : NewUser) : Text :=
  s!"{id} is now {user.name}"

api Users where
  GET "/hello" => hello
  POST "/users" => createUser
  PUT "/users/:id" => renameUser

/-- The status, content type and text that the route for `method` and `path` answers `body`
with. -/
def answer (method : Std.Http.Method) (path : List String) (body : String)
    (contentType : Option String := some "application/json") : Option (UInt16 × String × String) :=
  do
  let (_, endpoint) ← matchTable Users.routes method path
  let reply := endpoint.reply [] contentType body.toUTF8
  return (reply.status, reply.contentType, ← String.fromUTF8? reply.body)

/-! A row without a body answers at once, and a row with one decodes it first. -/

#guard answer .get ["hello"] "" == some (200, "text/plain; charset=utf-8", "Hello, World!")

#guard
  answer .post ["users"] "{\"name\":\"Ada\",\"age\":36}" ==
    some (200, "application/json", "{\"id\":1,\"name\":\"Ada\"}")

#guard
  answer .put (pathTo renameUser 7) "{\"name\":\"Ada\",\"age\":36}" ==
    some (200, "text/plain; charset=utf-8", "7 is now Ada")

/-! A body that isn't JSON gets the `400` problem, and one that fails its types or checks gets the
`422` problem. The handler doesn't run for either. -/

#guard
  answer .post ["users"] "{\"name\":" ==
    some
      (400, "application/problem+json",
        "{\"type\":\"/problems/malformed-json\",\"title\":\"The request body is not valid JSON\",\
          \"status\":400}")

#guard
  answer .post ["users"] "{\"name\":3,\"age\":36,\"x\":1}" ==
    some
      (422, "application/problem+json",
        "{\"type\":\"/problems/validation\",\"title\":\"The request body failed validation\",\
          \"status\":422,\"errors\":[{\"pointer\":\"#/name\",\"detail\":\"expected a string\"},\
          {\"pointer\":\"#/x\",\"detail\":\"unknown key\"}]}")

#guard (answer .post ["users"] "{\"name\":\"Bo\",\"age\":9}").map (·.1) == some 422

/-! The link theorem names the endpoint that wraps the handler. -/

/--
info: ApiBodyTests.Users.pathTo_renameUser (id : Nat) :
  matchTable Users.routes Std.Http.Method.put (pathTo renameUser id) =
    some
      ({ method := Std.Http.Method.put, segs := [PathSeg.lit "users" ⋯, PathSeg.capture "id" CaptureKind.nat] },
        Endpoint.ofBody fun user => renameUser { } id user)
-/
#guard_msgs in
#check Users.pathTo_renameUser

/-! A body must declare the route's media type. The check ignores letter case and parameters, and
a missing or different type gets `415` with the type in `Accept-Post`. A row without a body
ignores the header. -/

#guard
  (answer .post ["users"] "{\"name\":\"Ada\",\"age\":36}"
          (some "Application/JSON; charset=utf-8")).map
      (·.1) ==
    some 200

#guard
  answer .post ["users"] "{\"name\":\"Ada\",\"age\":36}" none ==
    some
      (415, "application/problem+json",
        "{\"type\":\"/problems/unsupported-media-type\",\
          \"title\":\"The request body has an unsupported media type\",\"status\":415}")

#guard
  ["text/plain", "application/x-www-form-urlencoded", "application/jsonx", "application/json+x", "",
        "json"].all
    fun type =>
    (answer .post ["users"] "{\"name\":\"Ada\",\"age\":36}" (some type)).map (·.1) == some 415

#guard
  ((matchTable Users.routes .post ["users"]).map fun (_, endpoint) =>
      (endpoint.reply [] (some "text/plain") ByteArray.empty).headers) ==
    some [("accept-post", "application/json")]

#guard (answer .get ["hello"] "" none).map (·.1) == some 200

end ApiBodyTests
