/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

/-!
# Secrets

`Secret α` holds a value that must not leave the server, such as a password or an API key. It has
no `ToString`, `ToJson` or `ToReply` instance, so code that would log it, encode it or answer with
it fails to compile. Its `Repr` prints `<secret>`, so a structure that holds one can still derive
`Repr`.

`Secret.reveal` gives the value back, for the code that checks a password or signs a request. It is
the one way out, so a search for it finds every place a secret is read.
-/

public section

namespace Espal

/-- A value that code can hold and pass on, and can't print, encode or send. -/
structure Secret (α : Type) where private mk ::
  private value : α

/-- Wraps `value` as a secret. -/
def Secret.wrap {α : Type} (value : α) : Secret α :=
  ⟨value⟩

/-- The value inside a secret. Every use of a secret's value goes through this function. -/
def Secret.reveal {α : Type} (secret : Secret α) : α :=
  secret.value

/-- A secret prints as `<secret>`, whatever it holds. -/
instance {α : Type} : Repr (Secret α) :=
  ⟨fun _ _ => "<secret>"⟩

@[simp]
theorem Secret.reveal_wrap {α : Type} (value : α) : (Secret.wrap value).reveal = value := by
  simp only [Secret.reveal, Secret.wrap]

end Espal
