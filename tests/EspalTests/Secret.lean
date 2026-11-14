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

/-! ## Bodies that hold a secret

`deriving Json` would write an encoder, so a body with a secret derives `JsonDecode` alone. The
decoder reads fields, decides checks and reports unknown keys as the full one does. -/

structure SignIn where
  name : String
  password : Secret String
  note? : Option String
  short : name.length ≤ 8
  deriving JsonDecode

def signIn (_ : Public) (body : SignIn) : Text :=
  if body.password.reveal == "hunter2" then s!"hello {body.name}" else "no"

api Auth where
  POST "/sign-in" => signIn

def post (body : String) : Option (UInt16 × String) :=
  (Auth.reply? .post ["sign-in"] [] (some "application/json") body.toUTF8).map fun r =>
    (r.status, (String.fromUTF8? r.body).getD "")

#guard post "{\"name\":\"ada\",\"password\":\"hunter2\"}" == some (200, "hello ada")

#guard
  post "{\"name\":\"adaadaada\",\"pass\":\"hunter2\"}" ==
    some
      (422,
        "{\"type\":\"/problems/validation\",\"title\":\"The request body failed validation\",\"status\":422,\"errors\":[{\"pointer\":\"#/password\",\"detail\":\"missing\"},{\"pointer\":\"#/pass\",\"detail\":\"unknown key\"}]}")

#guard (post "{\"name\":\"adaadaada\",\"password\":\"x\"}").map (·.1) == some 422

/-! The full derive still refuses the same structure, since it would encode the secret. -/

/--
error: cannot derive Json for Leaky: the field password has type Secret String, which has no LawfulDecode instance
-/
#guard_msgs in
structure Leaky where
  password : Secret String
  deriving Json

/-! The decoder alone has its own refusals. -/

/--
error: cannot derive JsonDecode for Wrapped: the handler takes a structure without parameters
-/
#guard_msgs in
structure Wrapped (α : Type) where
  value : α
  deriving JsonDecode

/--
error: cannot derive JsonDecode for Opaque: the field run has type Nat → Nat, which has no JsonDecode instance
-/
#guard_msgs in
structure Opaque where
  run : Nat → Nat
  deriving JsonDecode

end SecretTests
