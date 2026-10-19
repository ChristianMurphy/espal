# Uploads, ranges and ETags without LeanIO

Espal writes its own multipart parser, range handling and ETags, and doesn't depend on [LeanIO](https://github.com/ecyrbe/leanio). This note records the decision from the LeanIO trial in the [spikes and a baseline](../../ROADMAP.md#spikes-and-a-baseline) milestone, made in October 2026. The [trial's README](https://github.com/ChristianMurphy/espal/blob/explore/leanio/explorations/leanio/README.md) on the `explore/leanio` branch has the setup and every result.

## Why

- Espal's endpoints already declare their parameters and body on top of lean-routing, so LeanIO's router and extractors would duplicate them.
- The roadmap puts file uploads and HTTP caching after 0.1, so release 0.1 needs no part of LeanIO.
- Its multipart parser loses data. A text field or part headers that span two chunks lose their start, with no error. A file part takes in the closing boundary when chunks are shorter than the boundary line.
- A range past the end of a file gets a 206 with an empty body. `If-None-Match` never matches a list of tags or a weak tag.
- Every executable that links it is about 120 MB, against the 10 MB target, because its modules import `Lean` at run time.
- Its parser is `partial` and keeps its state in an `IO.Ref`. Espal's handlers are pure, and its lint rejects `partial`.
- It doesn't build on Lean 4.34.0 or later without a patch. Its latest merge was on 27 August. Six pull requests from the following days haven't merged.

## What Espal builds

This work starts when uploads arrive after 0.1.

- A multipart parser as a pure step function over bytes. A theorem says that any split of the body into chunks gives the same parts as the whole body. [Streaming decoders agree with whole-body decoders](../../ROADMAP.md#streaming-decoders-agree-with-whole-body-decoders) asks the same of JSON. Each field gets a size limit, which counts toward the [memory bound per request](../../ROADMAP.md#memory-per-request-stays-within-a-declared-bound).
- Range and ETag handling as pure functions, with a test for each case the trial found.
- A table from file extensions to media types. Espal may copy LeanIO's with its MIT notice.

## Changes offered upstream

Espal reported each finding to LeanIO as its own issue, and doesn't wait on a fix. The trial's `MultipartSplit.lean` and `Trial/Behaviour.lean` reproduce them.

- [ecyrbe/leanio#33](https://github.com/ecyrbe/leanio/issues/33) covers the failed build from Lean 4.34.0 on, where Std.Http declares four of LeanIO's header names.
- [ecyrbe/leanio#34](https://github.com/ecyrbe/leanio/issues/34) covers text fields and part headers that span two chunks.
- [ecyrbe/leanio#35](https://github.com/ecyrbe/leanio/issues/35) covers the closing boundary that a file part takes in.
- [ecyrbe/leanio#36](https://github.com/ecyrbe/leanio/issues/36) covers ranges past the end of a file, and invalid ranges.
- [ecyrbe/leanio#37](https://github.com/ecyrbe/leanio/issues/37) covers lists and weak tags in `If-None-Match`, headers on a 304, and file tags that collide.
