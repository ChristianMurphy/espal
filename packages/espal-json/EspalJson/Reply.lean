/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Reply
public import EspalJson.Problem
public import Json.Printer

/-!
# JSON replies and bodies

A handler's result with a `ToJson` instance answers `200 OK` with its JSON. A handler's body
argument with a `JsonDecode` instance is read with `decodeBody`. So a body that isn't JSON gets the
`400` problem, and one that fails its types or checks gets the `422` problem.
-/

@[expose] public section

namespace Espal

open Json

/-- A problem answers its own status as `application/problem+json`. -/
instance : ToReply Problem :=
  ⟨fun p => ⟨p.status.toUInt16, "application/problem+json", (compress (toJson p)).toUTF8⟩⟩

/-- A value with a JSON encoding answers `200 OK` with it. -/
instance (priority := low) {α : Type} [ToJson α] : ToReply α :=
  ⟨fun x => ⟨200, "application/json", (compress (toJson x)).toUTF8⟩⟩

/-- A body with a JSON decoder is read with `decodeBody`. -/
instance {β : Type} [JsonDecode β] : FromBody β :=
  ⟨fun bytes => (decodeBody β bytes).mapError toReply⟩

end Espal
