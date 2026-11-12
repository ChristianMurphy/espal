module

import EspalHttp
meta import EspalHttp
import EspalJson
meta import EspalJson

/-!
Tests for `Api.toHandler` in `EspalHttp.Serve`. A request reaches the handler its route names, with
its captures, its query parameters and its body. Any other request gets `404 Not Found`, a body that doesn't decode gets
its problem, and a body over the limit gets `413`. A known path under another method gets `405`,
and a body that doesn't declare JSON gets `415`.
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

def clock (_ : Public) : Handler Text := do
  let t ← now
  return s!"{t}"

api Bench where
  GET "/clock" => clock
  GET "/plaintext" => plaintext
  GET "/users/:id" => showUser
  POST "/notes" => echo
  GET "/queries" => rows

/-- The status, text body and `header` value that `Bench.toHandler` answers `request` with, reading
at most 64 bytes of a request body. -/
def answerWith (header : String) (request : Request Body.Stream) :
    IO (Status × String × Option String) :=
  Async.block <|
    ContextAsync.run do
      let response ← (Bench.toHandler (maxBody := 64)).onRequest request
      let text ←
        match ← response.body.recv with
        | some chunk =>
          pure ((String.fromUTF8? chunk.data).getD "")
        | none =>
          pure ""
      let value := (Header.Name.ofString? header).bind response.line.headers.get?
      return (response.line.status, text, value.map (·.value))

/-- The status and text body that `Bench.toHandler` answers `request` with. -/
def answer (request : Request Body.Stream) : IO (Status × String) := do
  let (status, text, _) ← answerWith "allow" request
  return (status, text)

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

/-- A `POST` of `content` to `target`, declaring `contentType` if there is one. -/
def postRequest (target content : String) (contentType : Option String) :
    IO (Request Body.Stream) := do
  let uri ← parseTarget target
  let body ← Async.block (Body.fromBytes content.toUTF8)
  let builder := Request.post uri
  return ((contentType.bind (builder.header? "content-type")).getD builder).body body

/-- What a `POST` of the JSON `content` to `target` is answered with. -/
def post (target content : String) : IO (Status × String) := do
  answer (← postRequest target content (some "application/json"))

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

#eval
  show IO Unit from do
    let problem :=
      "{\"type\":\"/problems/method-not-allowed\",\
        \"title\":\"The method is not allowed for this path\",\"status\":405}"
    let uri ← parseTarget "/notes"
    let body ← Async.block Body.empty
    let result ← answerWith "allow" ((Request.get uri).body body)
    check s!"GET /notes should get 405 with Allow: POST, got {repr result}"
        (result == (.methodNotAllowed, problem, some "POST"))
    let result ← answerWith "allow" (← postRequest "/users/7" "" none)
    check s!"POST /users/7 should get 405 with Allow: GET, got {repr result}"
        (result == (.methodNotAllowed, problem, some "GET"))
    let result ← answerWith "allow" (← postRequest "/nope" "" none)
    check s!"POST /nope should get 404 without Allow, got {repr result}"
        (result == (.notFound, "Not Found", none))

#eval
  show IO Unit from do
    let problem :=
      "{\"type\":\"/problems/unsupported-media-type\",\
        \"title\":\"The request body has an unsupported media type\",\"status\":415}"
    for contentType in [none, some "text/plain", some "application/x-www-form-urlencoded"] do
      let result ← answerWith "accept-post" (← postRequest "/notes" "{\"text\":\"hi\"}" contentType)
      check s!"a body declared as {repr contentType} should get 415, got {repr result}"
          (result == (.unsupportedMediaType, problem, some "application/json"))
    let result ←
      answer (← postRequest "/notes" "{\"text\":\"hi\"}" (some "application/json; charset=utf-8"))
    check s!"a JSON body with a charset should get 200, got {repr result}" (result.1 == .ok)
    let oversized := "{\"text\":\"" ++ String.ofList (List.replicate 80 'a') ++ "\"}"
    let result ← answer (← postRequest "/notes" oversized (some "text/plain"))
    check s!"an oversized body of the wrong type should get 415, got {repr result}"
        (result.1 == .unsupportedMediaType)

/-! The server answers an effectful handler from the machine's own clock. -/

#eval
  show IO Unit from do
    let (status, text) ← get "/clock"
    check s!"GET /clock should get a current timestamp, got {repr (status, text)}"
        (status == .ok && (text.toNat?.getD 0) > 1700000000000)
