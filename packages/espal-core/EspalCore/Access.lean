/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

/-!
# Access values

Every handler takes an access value as its first argument, which says who may call it. `Public`
is the access value of an endpoint that anyone may call.
-/

@[expose] public section

namespace Espal

/-- The access value of an endpoint that anyone may call. -/
structure Public where
  deriving Inhabited

end Espal
