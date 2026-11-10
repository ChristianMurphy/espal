/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Reply

/-!
# Handlers that can fail

A handler that can't fail returns `Handler α`. One that can returns `Fails ε α`: a value of type
`α`, or one of the errors that `ε` lists. Both are `Except`, so `do`, `throw` and `return` work as
usual. An error answers with its own reply, and the handler's value is never encoded.

The value comes last in both, since Lean finds a monad by dropping a type's last argument. One
name with an optional error type would put the value first, and `do` would not elaborate.

`NotFound` is the error of a handler whose only failure is a missing resource.
-/

@[expose] public section

namespace Espal

/-- The result of a handler that can't fail. -/
abbrev Handler (α : Type) :=
  Except Empty α

/-- The result of a handler that can fail, which is a value or one of the errors `ε` lists. -/
abbrev Fails (ε α : Type) :=
  Except ε α

/-- No error has this type, so no reply is ever built. -/
instance : ToReply Empty :=
  ⟨nofun⟩

/-- A result answers with its value's reply, and an error with its own. -/
instance {ε α : Type} [ToReply ε] [ToReply α] : ToReply (Except ε α) where
  toReply
    | .ok value => toReply value
    | .error error => toReply error

/-- The error of a handler whose only failure is a missing resource. -/
structure NotFound where
  deriving Inhabited, BEq, DecidableEq, Repr

/-- `NotFound` answers `404` as an RFC 9457 problem. -/
instance : ToReply NotFound :=
  ⟨fun _ =>
    ⟨404, "application/problem+json",
      "{\"type\":\"/problems/not-found\",\"title\":\"Not found\",\"status\":404}".toUTF8⟩⟩

end Espal
