module

import EspalRoute
meta import EspalRoute
import Plausible
import Std.Http.Data.URI
import Std.Http.Server.Config

/-!
Property tests for what `Espal.Route` trusts the HTTP layer to do. `Std.Http` must split a link's
path into segments and percent-decode them back to the segments the link joins. Its parser and
decoder have no lemmas, so Plausible checks the claim on generated paths.
-/

open Espal Route Std.Http

/-- The link whose path joins `xs`, with each segment percent-encoded. -/
def joinEncoded (xs : List String) : String :=
  "/" ++ "/".intercalate (xs.map fun x => toString (URI.EncodedSegment.encode x))

/-- Whether the link for `xs` is within `Std.Http`'s default limits on a path and a request
target. -/
def fits (xs : List String) : Bool :=
  let config : URI.Config := {}
  xs.length ≤ config.maxPathSegments &&
    xs.all
      (fun x => (toString (URI.EncodedSegment.encode x)).utf8ByteSize ≤ config.maxSegmentLength) &&
    (joinEncoded xs).utf8ByteSize ≤ config.maxTotalPathLength &&
    (joinEncoded xs).utf8ByteSize ≤ ({} : Config).maxUriLength

/-- Whether `Std.Http` reads the link for `xs` back as `xs`. The link `/` for `[""]` reads back as
`[]`, hence the first condition. -/
def readsBack (xs : List String) : Bool :=
  xs == [""] || !fits xs ||
    (RequestTarget.parse? (joinEncoded xs)).map (·.path.toDecodedSegments.toList) == some xs

/-- What `Espal.Route` trusts the HTTP layer to do. -/
def ReadsBack : Prop :=
  ∀ xs, readsBack xs = true

/-- Numbers at the edges of machine integers and of digit counts. Plausible's own numbers stay
under 100. -/
def edgeNats : List Nat :=
  [0, 9, 10, 99, 100, 255, 256, 65535, 65536, 2 ^ 31, 2 ^ 32, 2 ^ 63, 2 ^ 64 - 1, 2 ^ 64, 10 ^ 30]

/-- Segments weighted towards the characters a path treats specially, towards numbers as `natSeg`
prints them, and towards the empty segment. -/
local instance (priority := high) : Plausible.Arbitrary String where
  arbitrary :=
    Plausible.Gen.frequency (pure "")
      [(3, do
          let chars ←
            Plausible.Gen.listOf
                (Plausible.Char.arbitraryFromList 3 "./%?#:;@+&= aZ0é".toList (by decide)).arbitrary
          pure (String.ofList chars)),
        (1, do
          pure (natSeg (← Plausible.Gen.elements edgeNats (by decide)))),
        (1, pure "")]

/-- info: Unable to find a counter-example -/
#guard_msgs in
#eval
  Plausible.Testable.check (∀ xs : List String, readsBack xs = true)
    { numInst := 1000, randomSeed := some 2026 }

-- Every list starts with an empty segment, as the link `//a` does.
/-- info: Unable to find a counter-example -/
#guard_msgs in
#eval
  Plausible.Testable.check (∀ xs : List String, readsBack ("" :: xs) = true)
    { numInst := 1000, randomSeed := some 2026 }
