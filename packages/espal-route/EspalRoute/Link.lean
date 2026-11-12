/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Query
public import Routing.Handler

/-!
# Links as URLs

`Link.toString` writes a `Link` as the path and query of a URL, such as `/search?q=lean&page=2`.
Each path segment is percent-encoded as lean-routing encodes its own links.

A query key or value keeps only letters, digits, `-`, `.`, `_` and `~`, and every other byte is
percent-encoded. So a space is `%20` and `+` is `%2B`. A decoder that reads `+` as a space and
one that doesn't then read the same value.

No theorem here says the server reads a written link back. That depends on `Std.Http`'s parser,
so a property test checks it on generated links.
-/

@[expose] public section

namespace Espal

open Std.Http

/-- Whether a query key or value keeps the byte `b` as it is. -/
def queryKeeps (b : UInt8) : Bool :=
  (b ≥ 0x41 && b ≤ 0x5a) || (b ≥ 0x61 && b ≤ 0x7a) || (b ≥ 0x30 && b ≤ 0x39) || b == 0x2d ||
    b == 0x2e ||
    b == 0x5f ||
    b == 0x7e

/-- The upper-case hexadecimal digit for `n`, which is below 16. -/
def hexUpper (n : UInt8) : Char :=
  Char.ofNat (if n < 10 then 0x30 + n.toNat else 0x41 + n.toNat - 10)

/-- A query key or value, with every byte that `queryKeeps` rejects percent-encoded. -/
def encodeQueryPart (s : String) : String :=
  s.toUTF8.foldl (init := "") fun acc b =>
    if queryKeeps b then acc.push (Char.ofNat b.toNat)
    else ((acc.push '%').push (hexUpper (b >>> 4))).push (hexUpper (b &&& 0xf))

/-- The path and query of the URL for `link`. An empty query writes no `?`. -/
protected def Link.toString (link : Link) : String :=
  let path := Routing.encodedPath (link.path.map fun s => toString (URI.EncodedSegment.encode s))
  if link.query.isEmpty then path
  else
    path ++ "?" ++
      "&".intercalate
        (link.query.map fun (key, value) => encodeQueryPart key ++ "=" ++ encodeQueryPart value)

instance : ToString Link :=
  ⟨Link.toString⟩

end Espal
