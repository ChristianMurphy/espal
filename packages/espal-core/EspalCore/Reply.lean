/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

/-!
# Replies and endpoints

A `Reply` is a response before it reaches the server: a status, a content type and bytes. An
`Endpoint` is what a route does once its path matched. It either has its reply already, or needs
the request body first. The `api` command wraps each handler into an `Endpoint`, so one table
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
  /-- The route answers without reading the request body. -/
  | noBody (reply : Reply)
  /-- The route answers from the bytes of the request body. -/
  | withBody (run : ByteArray → Reply)

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

/-- The endpoint of a handler that takes no body. -/
def Endpoint.ofValue {ρ : Type} [ToReply ρ] (result : ρ) : Endpoint :=
  .noBody (toReply result)

/-- The endpoint of a handler that takes a body. A body that `fromBody` refuses gets its reply,
and the handler doesn't run. -/
def Endpoint.ofBody {β ρ : Type} [FromBody β] [ToReply ρ] (handler : β → ρ) : Endpoint :=
  .withBody fun bytes =>
    match fromBody bytes with
    | .ok body => toReply (handler body)
    | .error reply => reply

end Espal
