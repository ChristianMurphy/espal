/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Reply
public import EspalRoute.Link

/-!
# Created resources

A handler that makes a resource returns `Created`, with a link to the resource and a value. The
reply is `201 Created`. Its `Location` header holds the link as a URL, and its body is the one the
value answers with on its own.

A handler gets the link from `linkTo`. The `api` command declares `linkTo` for a table's handlers
after they exist, so a handler that links to another row takes the instance as an argument:

```
def createUser (_ : Public) [LinkTo showUser (Nat → Link)] (user : NewUser) : Created User :=
  ⟨linkTo showUser 7, ⟨7, user.name⟩⟩
```

The command fills that argument when it builds the table.
-/

@[expose] public section

namespace Espal

/-- A new resource, which answers `201 Created`. -/
structure Created (α : Type) where
  /-- The link to the resource, sent in the `Location` header. -/
  location : Link
  /-- The value whose reply gives the body and its content type. -/
  value : α

/-- `Created` answers `201` with the link in `Location` and the value's own body. -/
instance {α : Type} [ToReply α] : ToReply (Created α) :=
  ⟨fun created =>
    let reply := toReply created.value
    { reply with
      status := 201, headers := ("location", toString created.location) :: reply.headers }⟩

end Espal
