module

import EspalHttp
meta import EspalHttp

/-!
Tests for `Api.toHandler` in `EspalHttp.Serve`. A request reaches the handler its route names, with
its captures, and any other request gets `404 Not Found`.
-/

open Espal Routing Std Async Http

def plaintext (_ : Public) : String :=
  "Hello, World!"

def showUser (_ : Public) (id : Nat) : String :=
  s!"user {id}"

api Bench where
  GET "/plaintext" => plaintext
  GET "/users/:id" => showUser

/-- The status and text body that `Bench.toHandler` answers a `GET` for `target` with. -/
def answer (target : String) : IO (Status × String) :=
  Async.block <|
    ContextAsync.run do
      let some uri := RequestTarget.parse? target
        | throw (IO.userError s!"test target {target.quote} is not a valid request target")
      let response ← Bench.toHandler.onRequest ((Request.get uri).body (← Body.empty))
      let text ←
        match ← response.body.recv with
        | some chunk =>
          pure ((String.fromUTF8? chunk.data).getD "")
        | none =>
          pure ""
      return (response.line.status, text)

/-- Fails with `label` unless `ok`. -/
def check (label : String) (ok : Bool) : IO Unit :=
  unless ok do
    throw (IO.userError label)

#eval
  show IO Unit from do
    for (target, status, text) in
      [("/plaintext", Status.ok, "Hello, World!"), ("/users/7", .ok, "user 7"),
        ("/users/new", .notFound, "Not Found"), ("/nope", .notFound, "Not Found")] do
      let result ← answer target
      check s!"{target} should get {repr (status, text)}, got {repr result}"
          (result == (status, text))
