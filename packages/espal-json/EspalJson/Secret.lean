/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Secret
public import EspalJson.Decode

/-!
# Secrets in JSON

A secret is read from JSON as the value it holds, since a password arrives in a request body. It
has no `ToJson` instance, so no reply and no derived encoder can write one.
-/

public section

namespace Espal

open Json

/-- A secret is read as the value it holds. -/
instance {α : Type} [JsonDecode α] : JsonDecode (Secret α) where
  decode pointer j := Secret.wrap <$> decode pointer j

end Espal
