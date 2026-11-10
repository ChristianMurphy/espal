/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalJson.Decode
public import Json.Parser

/-!
# Problem details for request bodies

`decodeBody` parses and decodes a request body. A body that isn't JSON gives a `400` problem. A
body that parses but fails its types or checks gives a `422` problem, which lists every failure.
Each failure has its JSON Pointer as a URI fragment, such as `#/items/1/price`. `Problem` encodes
to the `application/problem+json` shape of RFC 9457.
-/

@[expose] public section

namespace Espal

open Json

/-- An RFC 9457 problem. `errors` is empty unless the body failed validation. -/
structure Problem where
  /-- A URI reference that names the kind of problem. -/
  type : String
  /-- A short summary of the kind of problem. -/
  title : String
  /-- The HTTP status code. -/
  status : Nat
  /-- Each failure in the body, if the body failed validation. -/
  errors : Array DecodeError
  deriving Repr, BEq, DecidableEq, Inhabited

/-- Whether a URI fragment may hold the byte as it is, by RFC 3986. -/
def fragmentByte (b : UInt8) : Bool :=
  (0x61 ≤ b && b ≤ 0x7a) || (0x41 ≤ b && b ≤ 0x5a) || (0x30 ≤ b && b ≤ 0x39) ||
    "-._~!$&'()*+,;=:@/?".toUTF8.data.contains b

/-- The hexadecimal digit for a number below 16, in upper case. -/
def hexDigit (n : UInt8) : Char :=
  if n < 10 then Char.ofNat (0x30 + n.toNat) else Char.ofNat (0x41 + n.toNat - 10)

/-- The pointer as a URI fragment, such as `#/items/1/price`. Bytes that a fragment can't hold are
percent-encoded, as RFC 6901 says. -/
def DecodeError.fragment (e : DecodeError) : String :=
  e.pointerString.toUTF8.foldl (init := "#") fun s b =>
    if fragmentByte b then s.push (Char.ofNat b.toNat)
    else (s.push '%').push (hexDigit (b >>> 4)) |>.push (hexDigit (b &&& 0xf))

instance : ToJson Problem where
  toJson p :=
    let base : Array (String × Json) :=
      #[("type", .str p.type), ("title", .str p.title), ("status", .num (Number.ofNat p.status))]
    if p.errors.isEmpty then .obj base
    else
      .obj
        (base.push
          ("errors",
            .arr
              (p.errors.map fun e =>
                .obj #[("pointer", .str e.fragment), ("detail", .str e.detail)])))

/-- The `400` problem for a body that isn't JSON. -/
def Problem.malformedJson : Problem :=
  ⟨"/problems/malformed-json", "The request body is not valid JSON", 400, #[]⟩

/-- The `422` problem for a body that parsed but failed its types or checks. -/
def Problem.validation (errors : Array DecodeError) : Problem :=
  ⟨"/problems/validation", "The request body failed validation", 422, errors⟩

/-- Parses and decodes a request body. Malformed JSON gives a `400` problem, and a body that
parses but fails its types or checks gives a `422`. -/
def decodeBody (α : Type) [JsonDecode α] (body : ByteArray) : Except Problem α :=
  match parseBytes body with
  | .error _ => .error .malformedJson
  | .ok j =>
    match decode [] j with
    | .ok x => .ok x
    | .error errors => .error (.validation errors)

/-- A `400` means the body didn't parse, and a `422` carries exactly the decoder's failures. -/
theorem status_of_decodeBody_error {α : Type} [JsonDecode α] {body : ByteArray} {p : Problem}
    (h : decodeBody α body = .error p) :
    (p.status = 400 ∧ (parseBytes body).toOption = none) ∨
      (p.status = 422 ∧
        ∃ j, parseBytes body = .ok j ∧ (decode [] j : Except _ α) = .error p.errors) := by
  unfold decodeBody at h
  split at h
  · rename_i hp
    cases h
    exact .inl ⟨rfl, by simp [hp, Except.toOption]⟩
  · rename_i j hp
    split at h
    · exact absurd h nofun
    · rename_i errors hd
      cases h
      exact .inr ⟨rfl, j, hp, hd⟩

end Espal
