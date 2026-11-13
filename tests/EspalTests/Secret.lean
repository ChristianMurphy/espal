module

import EspalJson
meta import EspalJson
import EspalRoute
meta import EspalRoute

/-!
Tests for `Secret`. A secret is read from a request body, and code can't print it, encode it or
answer with it.
-/

open Espal Routing Json

namespace SecretTests

/-! A secret is read from JSON, and `reveal` gives the value back. -/

#guard
  match (decode [] (Json.str "hunter2") : Except _ (Secret String)) with
  | .ok secret => secret.reveal == "hunter2"
  | .error _ => false

example (password : String) : (Secret.wrap password).reveal = password := by simp

/-! It prints as `<secret>`, alone and inside a structure. -/

structure Login where
  name : String
  password : Secret String
  deriving Repr

/-- info: <secret> -/
#guard_msgs in
#eval Secret.wrap "hunter2"

/-- info: { name := "ada", password := <secret> } -/
#guard_msgs in
#eval ({ name := "ada", password := .wrap "hunter2" } : Login)

/-! It has no encoder, so none of these compile. -/

/--
error: failed to synthesize instance of type class
  ToJson (Secret String)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs in
example : Json :=
  toJson (Secret.wrap "hunter2")

/--
error: failed to synthesize instance of type class
  ToString (Secret String)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs in
example : String :=
  toString (Secret.wrap "hunter2")

/--
error: failed to synthesize instance of type class
  ToReply (Secret String)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs in
example : Reply :=
  toReply (Secret.wrap "hunter2")

/-! A handler can't log one or return one. -/

/--
error: Application type mismatch: The argument
  password
has type
  Secret String
but is expected to have type
  String
in the application
  log password
-/
#guard_msgs in
def leak (_ : Public) (password : Secret String) : Handler Text := do
  log password
  return "ok"

end SecretTests
