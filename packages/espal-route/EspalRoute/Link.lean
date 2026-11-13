/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Query
public import Routing.Handler
import all Std.Http.Data.URI.Encoding
import all Std.Http.Internal.Char

/-!
# Links as URLs

`Link.toString` writes a `Link` as the path and query of a URL, such as `/search?q=lean&page=2`.
Each path segment is percent-encoded as lean-routing encodes its own links.

A query key or value keeps only letters, digits, `-`, `.`, `_` and `~`, and every other byte is
percent-encoded. So a space is `%20` and `+` is `%2B`. A decoder that reads `+` as a space and
one that doesn't then read the same value.

`Link.toString_local` shows that the URL stays on its host.

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

/-! ## A link stays on its host

A browser reads a `Location` that starts with `//` or `/\` as another host. A link's URL starts
with one `/` and never with two, so a redirect to a link stays on the site. -/

/-- An encoded string never starts with a one-byte character its rule and the encoder leave out. -/
theorem head?_toList_encodedString_ne {r : UInt8 → Bool} (encoded : URI.EncodedString r) (c : Char)
    (hsize : c.utf8Size = 1) (hc : URI.isEncodedChar r c.val.toUInt8 = false) :
    (toString encoded).toList.head? ≠ some c := by
  intro h
  have hbytes : (toString encoded).toList.utf8Encode = encoded.toByteArray :=
    String.utf8Encode_toList
  cases hl : (toString encoded).toList with
  | nil => simp [hl] at h
  | cons d ds =>
    rw [hl] at h hbytes
    simp at h
    subst h
    have hvalid := encoded.valid
    rw [← hbytes, List.utf8Encode_cons] at hvalid
    simp [List.utf8Encode, String.utf8EncodeChar_eq_singleton hsize,
      URI.IsAllowedEncodedChars] at hvalid
    simp_all

/-- A path whose parts start with neither `/` nor `\` starts with exactly one `/`. -/
theorem toList_encodedPath (parts : List String)
    (h : ∀ p ∈ parts, p.toList.head? ≠ some '/' ∧ p.toList.head? ≠ some '\\') :
    ∃ rest,
      (Routing.encodedPath parts).toList = '/' :: rest ∧
        rest.head? ≠ some '/' ∧ rest.head? ≠ some '\\' := by
  unfold Routing.encodedPath
  split
  · exact
      ⟨_, by
        simp [String.toList_append]; rfl, by simp, by simp⟩
  · rename_i hne
    cases parts with
    | nil => exact ⟨[], by simp, by simp, by simp⟩
    | cons p
      ps =>
      refine ⟨("/".intercalate (p :: ps)).toList, by simp [String.toList_append], ?_⟩
      have hp := h p (by simp)
      cases hpl : p.toList with
      | nil =>
        have : p = "" := by simpa using hpl
        subst this
        cases ps with
        | nil => simp
        | cons q qs => exact absurd rfl (hne q qs)
      | cons c cs =>
        rw [hpl] at hp
        have : ("/".intercalate (p :: ps)).toList.head? = some c := by
          cases ps with
          | nil => simp [hpl]
          | cons q qs => simp [String.toList_intercalate, hpl, List.intercalate]
        rw [this]
        simpa using hp

/-- The URL of a link starts with `/`, and its second character is neither `/` nor `\`. A browser
that follows it stays on the same host. -/
theorem Link.toString_local (link : Link) :
    link.toString.toList.head? = some '/' ∧
      link.toString.toList[1]? ≠ some '/' ∧ link.toString.toList[1]? ≠ some '\\' := by
  obtain ⟨rest, hpath, hslash, hback⟩ :=
    toList_encodedPath (link.path.map fun s => toString (URI.EncodedSegment.encode s))
      (by
        intro p hp
        obtain ⟨s, _, rfl⟩ := List.mem_map.mp hp
        exact
          ⟨head?_toList_encodedString_ne _ '/' (by decide) (by decide +kernel),
            head?_toList_encodedString_ne _ '\\' (by decide) (by decide +kernel)⟩)
  unfold Link.toString
  simp only []
  split
  · rw [hpath]
    cases rest <;> simp_all
  · simp only [String.toList_append, hpath]
    cases rest <;> simp_all

end Espal
