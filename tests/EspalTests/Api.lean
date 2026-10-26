module

import EspalRoute
meta import EspalRoute

/-!
Tests for the `api` command in `EspalRoute.Api`. They cover a table it accepts, the paths and
theorems it declares, and the message for each table it rejects.
-/

open Espal Routing

def plaintext (_ : Public) : String :=
  "Hello, World!"

def newUser (_ : Public) : String :=
  "form"

def showUser (_ : Public) (id : Nat) : String :=
  s!"user {id}"

def updateUser (_ : Public) (id : Nat) : String :=
  s!"update {id}"

def showPost (_ : Public) (slug : String) (id : Nat) : String :=
  s!"post {id} {slug}"

/-! The same path under two methods is fine, and the arguments of `showPost` come in a different
order from its captures. -/

api Bench where
  GET "/plaintext" => plaintext
  GET "/users/new" => newUser
  GET "/users/:id" => showUser
  POST "/users/:id" => updateUser
  GET "/users/:id/posts/:slug" => showPost

#guard pathTo plaintext == ["plaintext"]

#guard pathTo showPost "hello" 7 == ["users", "7", "posts", "hello"]

#guard (matchTable Bench.routes .get (pathTo showPost "hello" 7)).map (·.2) == some "post 7 hello"

#guard (matchTable Bench.routes .get ["users", "new"]).map (·.2) == some "form"

#guard (matchTable Bench.routes .post (pathTo updateUser 7)).map (·.2) == some "update 7"

/-! The route index finds the same routes. -/

#guard (Bench.index.matchTable .get (pathTo showPost "hello" 7)).map (·.2) == some "post 7 hello"

#guard (Bench.index.matchTable .get ["users", "new"]).map (·.2) == some "form"

#guard (Bench.index.matchTable .delete ["users", "7"]).isNone

/--
info: Bench.pathTo_showPost (slug : String) (id : Nat) (h_slug : unlinkable slug = false) :
  matchTable Bench.routes Std.Http.Method.get (pathTo showPost slug id) =
    some
      ({ method := Std.Http.Method.get,
          segs :=
            [PathSeg.lit "users" ⋯, PathSeg.capture "id" CaptureKind.nat, PathSeg.lit "posts" ⋯,
              PathSeg.capture "slug" CaptureKind.string] },
        showPost { } slug id)
-/
#guard_msgs in
#check Bench.pathTo_showPost

example (id : Nat) :
    (matchTable Bench.routes .get (pathTo showUser id)).map (·.2) = some (showUser {} id) := by
  rw [Bench.pathTo_showUser]
  rfl

/-! `042` is no link to a `Nat` capture, so the literal route can follow it. -/

api Padded where
  GET "/users/:id" => showUser
  GET "/users/042" => newUser

#guard (matchTable Padded.routes .get ["users", "042"]).map (·.2) == some "form"

/-! Each table below fails, and the test pins its message. -/

def noAccess : String :=
  "no access"

def wrongAccess (id : Nat) : String :=
  s!"{id}"

def intUser (_ : Public) (id : Int) : String :=
  s!"{id}"

def implicitArg (_ : Public) {n : Nat} : String :=
  s!"{n}"

def count (_ : Public) : Nat :=
  0

def dependent (_ : Public) (n : Nat) : Fin (n + 1) :=
  0

def byName (_ : Public) (name : String) : String :=
  s!"user {name}"

/--
error: `FETCH` is not a method an `api` row accepts. Use GET, HEAD, POST, PUT, PATCH, DELETE or OPTIONS.
-/
#guard_msgs in
api BadMethod where
  FETCH "/a" => newUser

/-- error: path `users` must start with `/`. -/
#guard_msgs in
api NoSlash where
  GET "users" => newUser

/-- error: path `/users//x` has an empty segment. -/
#guard_msgs in
api EmptySegment where
  GET "/users//x" => newUser

/-- error: path `/users/` has an empty segment. -/
#guard_msgs in
api TrailingSlash where
  GET "/users/" => newUser

/-- error: path `/a/./b` has the segment `.`, which a client removes before sending. -/
#guard_msgs in
api DotSegment where
  GET "/a/./b" => newUser

/-- error: path `/users/:` has a capture with no name. -/
#guard_msgs in
api UnnamedCapture where
  GET "/users/:" => newUser

/-- error: path `/a/:id/:id` captures `id` twice. -/
#guard_msgs in
api RepeatedCapture where
  GET "/a/:id/:id" => showUser

/-- error: Unknown constant `missingHandler` -/
#guard_msgs in
api MissingHandler where
  GET "/a" => missingHandler

/-- error: handler `newUser` appears twice in `api Twice`, so a link to it would be ambiguous. -/
#guard_msgs in
api Twice where
  GET "/a" => newUser
  POST "/a" => newUser

/--
error: handler `noAccess` takes no access value, so nothing says who may call it.
Add `(_ : Public)` as its first argument for a public endpoint.
-/
#guard_msgs in
api NoAccess where
  GET "/a" => noAccess

/--
error: handler `wrongAccess` takes no access value, so nothing says who may call it.
Add `(_ : Public)` as its first argument for a public endpoint.
-/
#guard_msgs in
api WrongAccess where
  GET "/a/:id" => wrongAccess

/-- error: path `/users/:id` captures `id`, but handler `newUser` has no argument named `id`. -/
#guard_msgs in
api UnusedCapture where
  GET "/users/:id" => newUser

/-- error: handler `showUser` takes `id`, but path `/users` has no capture `:id`. -/
#guard_msgs in
api MissingCapture where
  GET "/users" => showUser

/-- error: handler `intUser` takes `id : Int`, but a path capture fills only a `Nat` or `String` argument. -/
#guard_msgs in
api IntCapture where
  GET "/users/:id" => intUser

/-- error: handler `implicitArg` takes `n` as an implicit argument, which an `api` row has no way to fill. -/
#guard_msgs in
api Implicit where
  GET "/a" => implicitArg

/--
error: handler `count` returns `Nat`, but handler `newUser` returns `String`. Every handler in one `api` table returns the same type.
-/
#guard_msgs in
api TwoResults where
  GET "/a" => newUser
  GET "/b" => count

/--
error: handler `dependent` has a result type that depends on its arguments, so its table has no single result type.
-/
#guard_msgs in
api Dependent where
  GET "/a/:n" => dependent

/--
error: `GET /users/:name` (handler `byName`) accepts links built for the later route `GET /users/new` (handler `newUser`).
Those links would reach the wrong handler. Change one of the two paths.
-/
#guard_msgs in
api Shadowed where
  GET "/users/:name" => byName
  GET "/users/new" => newUser

/--
error: `GET /users/:id` (handler `showUser`) accepts links built for the later route `GET /users/42` (handler `newUser`).
Those links would reach the wrong handler. Change one of the two paths.
-/
#guard_msgs in
api DigitLiteral where
  GET "/users/:id" => showUser
  GET "/users/42" => newUser
