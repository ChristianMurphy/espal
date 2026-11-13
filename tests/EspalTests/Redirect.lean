module

import EspalJson
meta import EspalJson
import EspalRoute
meta import EspalRoute

/-!
Tests for `Redirect`. A handler sends the client to another row of its table, and the `Location`
header holds that row's link. `Link.toString_local` shows that the link stays on the same host.
-/

open Espal Routing Json

namespace RedirectTests

structure NewUser where
  name : String
  deriving Json

def showUser (_ : Public) (id : Nat) : Text :=
  s!"user {id}"

def createUser (_ : Public) [links_to% showUser] (_ : NewUser) : Redirect :=
  .seeOther (linkTo showUser 7)

def oldUser (_ : Public) [links_to% showUser] (id : Nat) : Redirect :=
  .permanent (linkTo showUser id)

api Users where
  GET "/users/:id" => showUser
  POST "/users" => createUser
  GET "/people/:id" => oldUser

/-! Each kind of redirect answers its own status, with the link in `Location` and no body. -/

#guard
  (Users.reply? .post ["users"] [] (some "application/json") "{\"name\":\"Ada\"}".toUTF8).map
      (fun r => (r.status, r.headers, r.body.size)) ==
    some (303, [("location", "/users/7")], 0)

#guard
  (Users.reply? .get ["people", "42"] [] none .empty).map (fun r => (r.status, r.headers)) ==
    some (308, [("location", "/users/42")])

#guard (toReply (Redirect.temporary ⟨["a b"], [("q", "x y")]⟩)).status == 307

#guard
  (toReply (Redirect.temporary ⟨["a b"], [("q", "x y")]⟩)).headers ==
    [("location", "/a%20b?q=x%20y")]

/-! A link whose path would read as another host is written so that it doesn't. -/

#guard (⟨["", "evil.example"], []⟩ : Link).toString == "/.//evil.example"

#guard (⟨["\\evil.example"], []⟩ : Link).toString == "/%5Cevil.example"

#guard (⟨[""], [("next", "//evil.example")]⟩ : Link).toString == "/?next=%2F%2Fevil.example"

/-! `Link.toString_local` covers every link, so it covers every redirect. -/

example (redirect : Redirect) :
    (toString redirect.location).toList.head? = some '/' ∧
      (toString redirect.location).toList[1]? ≠ some '/' :=
  ⟨(Link.toString_local redirect.location).1, (Link.toString_local redirect.location).2.1⟩

end RedirectTests
