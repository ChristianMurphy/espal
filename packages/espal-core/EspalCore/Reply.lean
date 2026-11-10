/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Query

/-!
# Replies and endpoints

A `Reply` is a response before it reaches the server: a status, a content type and bytes. An
`Endpoint` is what a route does once its path matched. It answers from the request's query, and
some endpoints need the request body as well. The `api` command wraps each handler into an `Endpoint`, so one table
holds handlers with different result and body types.

`ToReply` says how a handler's result becomes a reply, and `FromBody` says how a request body
becomes a handler's argument. `Text` is a string sent as plain text.
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
  deriving Inhabited

/-- What a route does once its path matched. -/
inductive Endpoint where
  /-- The route answers from the query, without reading the request body. -/
  | noBody (run : Query → Reply)
  /-- The route answers from the query and the bytes of the request body. -/
  | withBody (run : Query → ByteArray → Reply)

/-- How a handler's result becomes a reply. -/
class ToReply (α : Type) where
  /-- The reply for `a`. -/
  toReply : α → Reply

/-- How a request body becomes a handler's argument, or the reply that refuses it. -/
class FromBody (β : Type) where
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
  ⟨fun t => ⟨200, "text/plain; charset=utf-8", t.text.toUTF8⟩⟩

/-- The `413` reply for a request body over the server's limit, as an RFC 9457 problem. -/
def Reply.tooLarge : Reply :=
  ⟨413, "application/problem+json",
    "{\"type\":\"/problems/body-too-large\",\"title\":\"The request body is too large\",\"status\":413}".toUTF8⟩

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
        "}").toUTF8⟩

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
  .withBody fun _ bytes => withBytes bytes fun body => toReply (handler body)

/-- The reply of `endpoint` to a request with the given query and body. -/
def Endpoint.reply (endpoint : Endpoint) (query : Query) (body : ByteArray) : Reply :=
  match endpoint with
  | .noBody run => run query
  | .withBody run => run query body

end Espal
