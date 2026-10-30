# lean-json for JSON

Espal reads and writes JSON with [lean-json](https://github.com/paulbutcher/lean-json), and adds a round-trip class whose instances a deriving handler proves. This note records the decision for the JSON part of the [packages, endpoints and the JSON API](../../ROADMAP.md#packages-endpoints-and-the-json-api) milestone, made in October 2026. It covers lean-json at commit `4a0cf59`, on Lean 4.35.0.

## What Espal takes

- The `Json` value type. Objects keep their order, and a number is an `Int` mantissa with an `Int` exponent.
- `parse`, `parseBytes` and `compress`, with lean-json's strict defaults. The parser refuses repeated keys and lone surrogates, nesting deeper than 1,024 levels, and numbers longer than 1,000 digits.
- The `ToJson` and `FromJson` classes, and their instances for common types.

## Why

- It imports only `Std`. A program that parses and prints JSON with it is 3.3 MB stripped, while `Lean.Data.Json` made the spike's server 120 MB.
- Paul Butcher proves its parser sound and complete against the grammar of RFC 8259. `parse_compress` proves that parsing printed JSON gives the same value back. These proofs use only `propext`, `Classical.choice` and `Quot.sound`.
- It has no `sorry`, `partial`, `unsafe`, `implemented_by` or `extern`. Its traversals keep pending work on the heap, so deep nesting gives an error, not a crash.
- It built with no warnings on Lean 4.35.0, and its tests passed.
- Building the same parts ourselves would go against the [contributing guide](../../CONTRIBUTING.md), which prefers an existing library under a compatible license.

## What Espal adds

- The classes and the theorem below. `deriving Json` writes the instances for a structure or an inductive type and proves them. A parameter that a field's type mentions takes codec instances, and `NotNullJson` only when a field needs it. A phantom parameter, as in `Key α`, takes none. A field can also hold the type itself, or an `Array`, `List` or `Option` of it. That decoder counts down from the depth of its input, so it needs no `partial`, and its proof is by induction on the count.
- A structure travels as an object with one key per data field. An inductive type whose constructors take no arguments travels as a string, such as `"red"`. Any other inductive type travels as an object whose `kind` key names the constructor, such as `{"kind": "circle", "radius": 2}`. That is the shape of a TypeScript discriminated union and of an OpenAPI `discriminator`.
- `espal-json` holds `LawfulJson` and `NotNullJson`, with instances for `Bool`, `String`, `Unit`, `Json`, `Number`, `Array`, `List`, pairs and `Option`. They take the form lean-json would give them, in case lean-json#6 moves them there.
- `JsonDecode` returns every failure with its JSON Pointer, which problem details need. A type with only a `FromJson` instance reports its one failure at its own pointer. Arrays and lists add the index of each element.
- Integers of 64 bits or more, such as `Nat`, `Int`, `UInt64` and `Int64`, travel as decimal strings, as [client and server agreement](../../ROADMAP.md#client-and-server-agree) says. Smaller integers travel as numbers. lean-json prints `Nat` and `Int` as numbers. Its decoder refuses a number with more than 1,000 trailing zeros, so neither type round trips for every value. Espal gives them no `LawfulJson` instance, so a derived codec rejects a `Nat` field. `Int32` and `Small`, a natural number below 2^53, travel as numbers. A decimal-string wrapper for larger integers comes later.
- Streaming decoders with the [chunk-split proof](../../ROADMAP.md#streaming-decoders-agree-with-whole-body-decoders).

## The round-trip statements

```lean
/-- `fromJson?` reads back what `toJson` writes. -/
class LawfulJson (α : Type u) [ToJson α] [FromJson α] : Prop where
  fromJson?_toJson (x : α) : fromJson? (toJson x) = .ok x

/-- `toJson` never writes `null`, so `Option α` can use `null` for `none`. -/
class NotNullJson (α : Type u) [ToJson α] : Prop where
  toJson_ne_null (x : α) : toJson x ≠ .null

instance [ToJson α] [FromJson α] [LawfulJson α] [NotNullJson α] : LawfulJson (Option α)

/-- One failure while decoding, at a JSON Pointer into the body. -/
structure DecodeError where
  pointer : List String
  detail : String

/-- Decodes a value at `pointer`, returning every failure in it. -/
class JsonDecode (α : Type u) where
  decode (pointer : List String) : Json → Except (Array DecodeError) α

/-- `decode` reads back what `toJson` writes, from any position. -/
class LawfulDecode (α : Type u) [ToJson α] [JsonDecode α] : Prop where
  decode_toJson (pointer : List String) (x : α) : JsonDecode.decode pointer (toJson x) = .ok x

/-- Every number in `j` is exactly a finite IEEE 754 double. -/
def DoubleNumbers (j : Json) : Prop :=
  ∀ n ∈ j.numbers, ∃ f : Float, Number.ofFloat? f = some n

/-- What `toJson` writes prints as text that the parser, and a JavaScript reader, read back
unchanged. -/
class WireJson (α : Type u) [ToJson α] : Prop where
  canonicalNumbers (x : α) : (toJson x).CanonicalNumbers
  uniqueKeys (x : α) : (toJson x).UniqueKeys
  doubleNumbers (x : α) : DoubleNumbers (toJson x)

/-- The full trip through text, with the parser's default settings. -/
theorem fromJson?_parse_compress [ToJson α] [FromJson α] [LawfulJson α] [WireJson α]
    (x : α) (hdepth : (toJson x).depth ≤ 1024) :
    ((parse (compress (toJson x))).toOption.bind
      fun j => (fromJson? j : Except String α).toOption) = some x
```

- `LawfulJson` covers the trip from a value to a tree and back. A handwritten instance can prove this class alone.
- `LawfulDecode` holds at every pointer, so a derived proof uses its fields' instances wherever they sit. The `FromJson` that `deriving Json` writes reads through `decode`, so `LawfulJson` follows from `LawfulDecode`.
- `Option α` writes `none` as `null`, so `none` and `some none` share an encoding in `Option (Option α)`. `NotNullJson α` rules that out, and the `Option` instance needs it.
- `WireJson` adds what printing and parsing need. A number has one spelling, and no object repeats a key.
- `DoubleNumbers` covers JavaScript readers. `JSON.parse` rounds each number to the nearest double, so a number that is already a double reads back unchanged. Lean can't prove a claim about JavaScript, so a Node test checks the values Espal prints.
- Depth appears once, as the theorem's hypothesis, since no class can bound the depth of every value of a recursive type.
- The theorem covers the default settings, which keep the 1,000-digit limit. `parse_compress` holds only with that limit off. The longest exact decimal of a double has 767 digits, so `DoubleNumbers` keeps every number within the limit. The proof needs one more lemma in lean-json, which covers parsing under a digit limit.

## Changes offered upstream

Espal offers lean-json these changes before building them here.

- [lean-json#5](https://github.com/paulbutcher/lean-json/issues/5) asks for a lemma that gives the round trip under the parser's default digit limit.
- [lean-json#6](https://github.com/paulbutcher/lean-json/issues/6) proposes `LawfulJson` and `WireJson`, with a deriving handler that proves them. It asks whether the finite-double rule belongs in `WireJson` or in Espal. `Json.numbers` waits on that answer.
- [lean-json#7](https://github.com/paulbutcher/lean-json/issues/7) asks for decode errors that carry a path, and for an option to reject unknown keys. The [app code note](app-code.md) needs both.

## If lean-json stalls

Espal copies the library with its Apache 2.0 notice, as the contributing guide allows, and keeps it current by hand. That happens if lean-json stops following Lean releases or turns down a change Espal needs.

## Risks

- One person maintains lean-json, and its first release came in October 2026.
- `parseBytes` checks UTF-8 and then parses a `String`, which costs a copy of each request body. A parser that reads bytes directly would avoid it.
- Espal's instances for large integers must not clash with lean-json's instances for the same types.
