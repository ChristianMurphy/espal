module

import EspalHttp
meta import EspalHttp
import EspalJson
meta import EspalJson

/-!
Tests for `Api.toHandler` in `EspalHttp.Serve`. A request reaches the handler its route names, with
its captures, its query parameters and its body. Any other request gets `404 Not Found`, a body that doesn't decode gets
its problem, and a body over the limit gets `413`.
-/

open Espal Routing Std Async Http

structure Note where
  text : String
  deriving Json

def plaintext (_ : Public) : Text :=
  "Hello, World!"

def showUser (_ : Public) (id : Nat) : Text :=
  s!"user {id}"

def echo (_ : Public) (note : Note) : Note :=
  note

def rows (_ : Public) (queries : Clamp 1 500) (label : Option String) : Text :=
  s!"{queries.val} rows {label}"

api Bench where
  GET "/plaintext" => plaintext
  GET "/users/:id" => showUser
  POST "/notes" => echo
  GET "/queries" => rows

/-- The status and text body that `Bench.toHandler` answers `request` with, reading at most 64
bytes of a request body. -/
def answer (request : Request Body.Stream) : IO (Status × String) :=
  Async.block <|
    ContextAsync.run do
      let response ← (Bench.toHandler (maxBody := 64)).onRequest request
      let text ←
        match ← response.body.recv with
        | some chunk =>
          pure ((String.fromUTF8? chunk.data).getD "")
        | none =>
          pure ""
      return (response.line.status, text)

/-- The request target `target`, or an error that names it. -/
def parseTarget (target : String) : IO RequestTarget :=
  match RequestTarget.parse? target with
  | some uri => pure uri
  | none => throw (IO.userError s!"test target {target.quote} is not a valid request target")

/-- What a `GET` for `target` is answered with. -/
def get (target : String) : IO (Status × String) := do
  let uri ← parseTarget target
  let body ← Async.block Body.empty
  answer ((Request.get uri).body body)

/-- What a `POST` of `content` to `target` is answered with. -/
def post (target content : String) : IO (Status × String) := do
  let uri ← parseTarget target
  let body ← Async.block (Body.fromBytes content.toUTF8)
  answer ((Request.post uri).body body)

/-- Fails with `label` unless `ok`. -/
def check (label : String) (ok : Bool) : IO Unit :=
  unless ok do
    throw (IO.userError label)

#eval
  show IO Unit from do
    for (target, status, text) in
      [("/plaintext", Status.ok, "Hello, World!"), ("/users/7", .ok, "user 7"),
        ("/users/new", .notFound, "Not Found"), ("/nope", .notFound, "Not Found"),
        ("/queries?queries=20", .ok, "20 rows none"), ("/queries", .ok, "1 rows none"),
        ("/queries?queries=900&label=a%20b", .ok, "500 rows (some (a b))"),
        ("/queries?label", .ok, "1 rows (some )")] do
      let result ← get target
      check s!"{target} should get {repr (status, text)}, got {repr result}"
          (result == (status, text))

#eval
  show IO Unit from do
    let malformed :=
      "{\"type\":\"/problems/malformed-json\",\"title\":\"The request body is not valid JSON\",\
        \"status\":400}"
    let tooLarge :=
      "{\"type\":\"/problems/body-too-large\",\"title\":\"The request body is too large\",\
        \"status\":413}"
    for (content, status, text) in
      [("{\"text\":\"hi\"}", Status.ok, "{\"text\":\"hi\"}"),
        ("{\"text\":", .badRequest, malformed),
        ("{\"text\":\"" ++ String.ofList (List.replicate 80 'a') ++ "\"}", .payloadTooLarge,
          tooLarge)] do
      let result ← post "/notes" content
      check s!"POST {content} should get {repr (status, text)}, got {repr result}"
          (result == (status, text))
    let (status, text) ← post "/notes" "{\"text\":3}"
    check s!"a body of the wrong type should get 422, got {repr (status, text)}"
        (status == .unprocessableEntity && (text.splitOn "#/text").length == 2)
