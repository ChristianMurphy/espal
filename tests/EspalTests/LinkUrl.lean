module

import EspalHttp
meta import EspalHttp
import EspalRoute
meta import EspalRoute
import Plausible
import Std.Http.Data.URI
import Std.Http.Server.Config

/-!
Tests for `Link.toString`. The server must read a written link back as the same path and query.
`Std.Http`'s parser has no lemmas, so Plausible checks the claim on generated links.
-/

open Espal Routing Std.Http

/-! A written link keeps only unreserved characters in its query. -/

#guard toString (⟨[], []⟩ : Link) == "/"

#guard toString (⟨["search"], [("q", "lean"), ("page", "2")]⟩ : Link) == "/search?q=lean&page=2"

#guard toString (⟨["a b", "c/d"], [("k", "")]⟩ : Link) == "/a%20b/c%2Fd?k="

#guard
  toString (⟨["s"], [("q", "a+b c&d=e#f%41é~"), ("", "x")]⟩ : Link) ==
    "/s?q=a%2Bb%20c%26d%3De%23f%2541%C3%A9~&=x"

#guard encodeQueryPart "\x00\x0f\x7f" == "%00%0F%7F"

/-- The path and query the server reads from the request target `target`. -/
def readTarget (target : String) : Option Link :=
  (RequestTarget.parse? target).map fun parsed => ⟨decodedPath parsed, targetQuery parsed⟩

/-- Whether the URL for `link` is within `Std.Http`'s default limits. -/
def fits (link : Link) : Bool :=
  let config : URI.Config := {}
  link.path.length ≤ config.maxPathSegments &&
    link.path.all
      (fun x => (toString (URI.EncodedSegment.encode x)).utf8ByteSize ≤ config.maxSegmentLength) &&
    link.query.length ≤ config.maxQueryParams &&
    (toString link).utf8ByteSize ≤ config.maxQueryLength &&
    (toString link).utf8ByteSize ≤ ({} : Config).maxUriLength

/-- Whether the server reads the URL for `link` back as `link`. A link carries no path segment
that is empty, `.` or `..`, hence the first condition. -/
def readsBack (link : Link) : Bool :=
  link.path.any unlinkable || !fits link || readTarget (toString link) == some link

/-- What a written link trusts the HTTP layer to do. -/
def ReadsBack : Prop :=
  ∀ link, readsBack link = true

/-! The characters a query treats specially read back, each on its own and in a key. -/

#guard
  "+ &=#%?/;:@!$'()*,[]\"<>\\^`{|}é\x00\n".toList.all fun c =>
    readsBack ⟨["s"], [("q", String.singleton c)]⟩ && readsBack ⟨["s"], [(String.singleton c, "v")]⟩

#guard readsBack ⟨["s"], [("a", "1"), ("a", "2"), ("", ""), ("a", "")]⟩

#guard readsBack ⟨[], [("q", "a+b")]⟩

/-- Strings weighted towards the characters a URL treats specially, and towards the empty
string. -/
local instance (priority := high) : Plausible.Arbitrary String where
  arbitrary :=
    Plausible.Gen.frequency (pure "")
      [(4, do
          let chars ←
            Plausible.Gen.listOf
                (Plausible.Char.arbitraryFromList 3 "./%?#:;@+&= aZ0é~-_\x00".toList
                    (by decide)).arbitrary
          pure (String.ofList chars)),
        (1, pure "")]

local instance : Plausible.Arbitrary Link where
  arbitrary := do
    let path ← Plausible.Arbitrary.arbitrary (α := List String)
    let query ← Plausible.Arbitrary.arbitrary (α := List (String × String))
    pure ⟨path.filter (!unlinkable ·), query⟩

local instance : Plausible.Shrinkable Link :=
  ⟨fun _ => []⟩

/-- info: Unable to find a counter-example -/
#guard_msgs in
#eval
  Plausible.Testable.check (∀ link : Link, readsBack link = true)
    { numInst := 2000, randomSeed := some 2026 }
