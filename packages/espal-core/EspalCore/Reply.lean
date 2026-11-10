/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Query

/-!
# Replies and endpoints

A `Reply` is a response before it reaches the server: a status, a content type, bytes and any
other headers. An `Endpoint` is what a route does once its path matched. It answers from the
request's query, and some endpoints need the request body as well. The `api` command wraps each
handler into an `Endpoint`, so one table holds handlers with different result and body types.

`ToReply` says how a handler's result becomes a reply, and `FromBody` says how a request body
becomes a handler's argument. `Text` is a string sent as plain text.

`FromBody` also names the media type it reads. A request whose `Content-Type` names another type,
or none, gets `415`, and the body is never decoded. A browser can't send `application/json` to
another site without a preflight request, so a form on another site can't post to a JSON route.
-/

@[expose] public section

namespace Espal

/-- A response before it reaches the server. -/
structure Reply where
  /-- The HTTP status code. -/
  status : UInt16
  /-- The value of the `Content-Type` header. -/
  contentType : String
  /-- The bytes of the body. -/
  body : ByteArray
  /-- Any other headers, as names and values. -/
  headers : List (String × String) := []
  deriving Inhabited

/-- What a route does once its path matched. -/
inductive Endpoint where
  /-- The route answers from the query, without reading the request body. -/
  | noBody (run : Query → Reply)
  /-- The route answers from the query and the bytes of a request body of type `mediaType`. -/
  | withBody (mediaType : String) (run : Query → ByteArray → Reply)

/-- How a handler's result becomes a reply. -/
class ToReply (α : Type) where
  /-- The reply for `a`. -/
  toReply : α → Reply

/-- How a request body becomes a handler's argument, or the reply that refuses it. -/
class FromBody (β : Type) where
  /-- The media type that the body must declare, such as `application/json`, in lower case. -/
  mediaType : String
  /-- The value in `body`, or the reply for a body that doesn't hold one. -/
  fromBody : ByteArray → Except Reply β

export ToReply (toReply)
export FromBody (fromBody)

instance : ToReply Reply :=
  ⟨id⟩

/-- A string that travels as plain text. -/
structure Text where
  /-- The text. -/
  text : String
  deriving Inhabited, BEq, DecidableEq, Repr

instance : Coe String Text :=
  ⟨Text.mk⟩

/-- Text answers `200 OK` with a plain-text body. -/
instance : ToReply Text :=
  ⟨fun t => ⟨200, "text/plain; charset=utf-8", t.text.toUTF8, []⟩⟩

/-- The `413` reply for a request body over the server's limit, as an RFC 9457 problem. -/
def Reply.tooLarge : Reply :=
  ⟨413, "application/problem+json",
    "{\"type\":\"/problems/body-too-large\",\"title\":\"The request body is too large\",\"status\":413}".toUTF8,
    []⟩

/-- `s` as a JSON string, with its quotes. -/
def jsonString (s : String) : String :=
  let hex (n : Nat) : Char := if n < 10 then Char.ofNat (0x30 + n) else Char.ofNat (0x61 + n - 10)
  let body :=
    s.foldl (init := "") fun acc c =>
      if c == '"' then acc ++ "\\\""
      else
        if c == '\\' then acc ++ "\\\\"
        else
          if c.toNat < 0x20 then
            (acc ++ "\\u00").push (hex (c.toNat / 16)) |>.push (hex (c.toNat % 16))
          else acc.push c
  "\"" ++ body ++ "\""

/-- The `400` reply for a query parameter that is missing or malformed, as an RFC 9457 problem. -/
def Reply.badQuery (parameter detail : String) : Reply :=
  ⟨400, "application/problem+json",
    ("{\"type\":\"/problems/query\",\"title\":\"A query parameter is invalid\",\"status\":400,\"parameter\":" ++
        jsonString parameter ++
        ",\"detail\":" ++
        jsonString detail ++
        "}").toUTF8,
    []⟩

/-- The `405` reply for a path that answers only the methods in `allow`, as an RFC 9457 problem.
The `Allow` header lists them. -/
def Reply.methodNotAllowed (allow : List String) : Reply :=
  ⟨405, "application/problem+json",
    "{\"type\":\"/problems/method-not-allowed\",\"title\":\"The method is not allowed for this path\",\"status\":405}".toUTF8,
    [("allow", ", ".intercalate allow)]⟩

/-- The `415` reply for a body that doesn't declare `mediaType`, as an RFC 9457 problem. The
`Accept-Post` header names the type. -/
def Reply.unsupportedMedia (mediaType : String) : Reply :=
  ⟨415, "application/problem+json",
    "{\"type\":\"/problems/unsupported-media-type\",\"title\":\"The request body has an unsupported media type\",\"status\":415}".toUTF8,
    [("accept-post", mediaType)]⟩

/-- Whether a `Content-Type` header names `mediaType`. Letter case, parameters such as `charset`
and spaces around the type make no difference. A missing header names no type. -/
def declaresMedia (mediaType : String) (contentType : Option String) : Bool :=
  match contentType with
  | none => false
  | some value => ((value.splitOn ";").headD "").trimAscii.toString.toLower == mediaType

/-- Reads the query parameter `name` and answers with `next`'s reply. A parameter that
`fromQuery` refuses gets the `400` problem, and `next` doesn't run. -/
def withQuery {α : Type} [FromQuery α] (query : Query) (name : String) (next : α → Reply) : Reply :=
  match fromQuery (query.first? name) with
  | .ok value => next value
  | .error detail => .badQuery name detail

/-- Reads the request body and answers with `next`'s reply. A body that `fromBody` refuses gets
its reply, and `next` doesn't run. -/
def withBytes {β : Type} [FromBody β] (bytes : ByteArray) (next : β → Reply) : Reply :=
  match fromBody bytes with
  | .ok body => next body
  | .error reply => reply

/-- The endpoint of a handler that takes no query parameter and no body. -/
def Endpoint.ofValue {ρ : Type} [ToReply ρ] (result : ρ) : Endpoint :=
  .noBody fun _ => toReply result

/-- The endpoint of a handler that takes a body and no query parameter. A body that `fromBody`
refuses gets its reply, and the handler doesn't run. -/
def Endpoint.ofBody {β ρ : Type} [FromBody β] [ToReply ρ] (handler : β → ρ) : Endpoint :=
  .withBody (FromBody.mediaType β) fun _ bytes => withBytes bytes fun body => toReply (handler body)

/-- The endpoint of a handler that takes query parameters and a body. `run` gets the query and a
function that decodes the body, so it can check the query first. -/
def Endpoint.ofQueryBody {β : Type} [FromBody β] (run : Query → ((β → Reply) → Reply) → Reply) :
    Endpoint :=
  .withBody (FromBody.mediaType β) fun query bytes => run query (withBytes bytes)

/-- The `415` reply, if `endpoint` takes a body and `contentType` doesn't declare its media
type. The server checks this before it reads the body. -/
def Endpoint.refusal? (endpoint : Endpoint) (contentType : Option String) : Option Reply :=
  match endpoint with
  | .noBody _ => none
  | .withBody mediaType _ =>
    if declaresMedia mediaType contentType then none else some (.unsupportedMedia mediaType)

/-- The reply of `endpoint` to a request with the given query, `Content-Type` header and body. -/
def Endpoint.reply (endpoint : Endpoint) (query : Query) (contentType : Option String)
    (body : ByteArray) : Reply :=
  match endpoint.refusal? contentType, endpoint with
  | some refusal, _ => refusal
  | none, .noBody run => run query
  | none, .withBody _ run => run query body

end Espal
