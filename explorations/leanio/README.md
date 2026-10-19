# LeanIO trial

This trial checks [LeanIO](https://github.com/ecyrbe/leanio) for streamed multipart uploads, ranges and ETags, for the dependency trials in the [spikes and a baseline](../../ROADMAP.md#spikes-and-a-baseline) milestone. It pins commit `0bb212d` from 27 August 2026, which is release 0.6.0, under the MIT license.

## Files

- `setup.sh` clones LeanIO into `leanio/` and applies `patches/lean-4.35.patch`.
- `MultipartSplit.lean` parses multipart bodies whole and split into chunks, and `multipart-split.txt` holds its output.
- `upload_check.sh` sends uploads to LeanIO's upload example, and `upload-check.txt` holds its output.
- `Trial/Behaviour.lean` checks the claims below about ranges and ETags with `#guard`.

## Running it

```bash
./setup.sh
lake build                       # fails if any #guard in Trial/ fails
.lake/build/bin/multipart-split  # -v lists every split that differs
./upload_check.sh
```

## Builds and tests

| Lean | Change to LeanIO | Build warnings | `lake test` |
|---|---|---|---|
| 4.35.0 | four header names removed | 0 | passes |
| 4.36.0-rc1 | the same | 0 | passes |

Std.Http in Lean 4.35.0 declares `contentEncoding`, `ifNoneMatch`, `lastModified` and `ifModifiedSince` in the namespace where LeanIO declares them, so LeanIO fails to build without the patch.

`lake test` builds the `Tests` library. Its 191 `#guard` checks cover route patterns, the router, multipart header parameters and base64. None of them parses a multipart body.

## What Espal would take

Espal's endpoints declare their parameters and body on top of lean-routing's `Route`, so LeanIO's router and extractors would duplicate them. That leaves these parts.

- `MultiPartForm`, a streamed `multipart/form-data` parser. It finds each boundary with the Knuth-Morris-Pratt algorithm over a buffer of chunks.
- `RangeFile`, which answers a `Range` request for a file with `206` and `Content-Range`.
- ETags for files and JSON, `304` for a matching `If-None-Match`, and `CacheControl` presets.
- A table from file extensions to MIME types.

## Multipart uploads

`multipart-split` parses two bodies whole, then split three ways. It splits each body in two at every byte, and it cuts it into chunks of every size. It also sends the first part's headers whole, with the rest in chunks of every size. One body holds a text field, a file and another text field. The other holds only a file.

| Body | Splits | Splits that differ from the whole body |
|---|---|---|
| Field, file, field | 776 | 456 |
| File only | 244 | 139 |

Each difference has one of two causes.

- **Text fields and part headers lose their start.** `readUntilGo` moves its cursor past bytes that hold no boundary. When it finds the boundary, it returns only the bytes after the cursor. Headers cut this way fail to parse, and the parser then ends the form.
- **A file takes in the closing boundary when chunks are shorter than the boundary line.** `streamRaw` passes a chunk to the file when the whole chunk could be the start of the boundary. With the 7-byte line `\r\n--XyZ`, chunks of 1 to 6 bytes do it. Browsers use boundary lines of about 40 bytes.

`upload_check.sh` sent these to LeanIO's upload example on Lean 4.36.0-rc1.

| Sent | Arrived |
|---|---|
| A text field of 100 bytes | 100 bytes |
| A text field of 20,000 bytes | 3,913 bytes |
| A text field of 200,000 bytes | 6,562 bytes |
| A text field of 50,000,000 bytes | 3,298 bytes, and 3,297 in an earlier run |
| A file of 200 MB | every byte, with the same SHA-256 |

No request got an error. The server's peak memory went from 71.9 MB at start to 78.2 MB after all five. A text field is read into memory whole, so a parser that kept every byte would also need a limit on field size.

## Ranges and ETags

`Trial/Behaviour.lean` checks each of these, and requests to LeanIO's LeanPlay example gave the same responses.

| `Range` on a 1,893-byte file | LeanIO's response | RFC 9110 |
|---|---|---|
| `bytes=0-9` | 206 with bytes 0 to 9 | the same |
| `bytes=1993-` | 206 with `Content-Range: bytes 0-0/1893` and an empty body | no byte is in range, so 416 |
| `bytes=20-10` | 206 with byte 20 | the range is invalid |
| `bytes=0-1_0` | 206 with bytes 0 to 10 | the range is invalid, since positions are digits |

With several ranges, LeanIO serves the first one alone. Its docstring says it picks the one with the lowest start.

- `etagMatches` compares the whole `If-None-Match` value with one tag. A list of tags, `*` or a weak `W/` tag never matches, so the client gets a 200 where a 304 would do.
- A 304 carries no `ETag` or `Cache-Control`, which RFC 9110 asks a 304 to repeat from the 200.
- A file's tag joins its modification seconds, nanoseconds and size with no separator. Two versions of a file can share a tag, and a browser then keeps the old one. `Trial/Behaviour.lean` checks one such pair.

Requests to LeanPlay confirmed the first two of these ETag findings.

## Binary size

Each example binary is 120 MB, or 81 MB stripped, against Espal's target of 10 MB. Several LeanIO modules import `Lean` at run time, and `IntoResponse` imports `Lean.Data.Json`. So every executable links the Lean package.

## Code style

Espal's `scripts/Lint.lean` reports 41 problems in LeanIO on Lean 4.35.0.

- 9 `partial` definitions, among them the multipart stream functions and the boundary search.
- 30 calls that can panic. 17 of them index with `!`.
- The `TypeName` instance for its route type, which Lean implements with `unsafe` code that depends on the axiom `lcProof`.

On Lean 4.36.0-rc1 the lint reports 10 more. Lean 4.36 generates an `unsafe` definition named `ctorIdx._impl` for each inductive type. A probe type in Espal gets the same report, so Espal's lint needs to accept these before Espal moves to 4.36.

Its one proof is a lemma about `String.find?`.

## Size and activity

- 3,282 lines of Lean in the library and 588 in tests.
- 137 commits from 22 June to 27 August 2026. Its author ecyrbe wrote 132. Paul Butcher, who maintains lean-routing, wrote 4.
- It still pins Lean 4.33.0.

## Options

1. **Depend on LeanIO, upstream first.** Espal uses its multipart parser, `RangeFile`, ETags and MIME table, and offers fixes for the build, both multipart bugs, ranges and ETags. Binaries stay over 10 MB until LeanIO's imports of `Lean` become `meta` imports. This suits Espal if the maintainer merges changes within days.
2. **Copy parts under the MIT notice.** Espal takes the MIME table, the `CacheControl` presets and the boundary search, and fixes them in its own tree. Little code moves, and Espal's rules for totality and proofs apply to all of it.
3. **Write Espal's own.** Espal writes the multipart parser as a pure step function over bytes, which can carry the proof from [streaming decoders agree with whole-body decoders](../../ROADMAP.md#streaming-decoders-agree-with-whole-body-decoders). That proof rules out both multipart bugs above. Ranges and ETags follow RFC 9110, with a test for each case above, and Espal reads LeanIO's code for reference.
