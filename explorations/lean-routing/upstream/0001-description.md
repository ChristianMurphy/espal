The README lists the round trip from `linkFor` to `dispatch` as unproved, citing missing lemmas for `String.splitOn` and `String.toNat?`. This PR proves it, and names the one step that rests on `Std.Http` as an assumption, which the tests fuzz.

`requestSegments_linkFor` follows a link from `linkFor` through `Std.Http`'s request-target parser and `decodedPath`, as `respond?` reads a request. Dispatching the result against the link's route calls the handler with the values passed to `linkFor`. Since the server splits a path with `Std.Http`, the proof doesn't need `String.splitOn`. For a `Nat` capture, Lean 4.35.0 proves `Nat.toNat?_repr`, which shows that `String.toNat?` reads back what `toString` prints. `encode_repr` proves that percent-encoding leaves a number's digits alone.

`Std.Http`'s parser and decoder have no lemmas, so the theorem takes one premise about them. `ReadsBack` says that a link reads back as the segments it joins, unless they are `[""]`, whose link `/` reads back as `[]`. The link also has to fit `Std.Http`'s default limits on a path and on a request target.

`Handler.lean` fuzzes `readsBack` with Plausible, using its existing generator. A second check starts every list with an empty segment. The theorem also leaves out a route that starts with an empty literal, since a browser sends its link to another host (#9). It covers one route, so in a table an earlier route can still match the link first.

The PR adds `decodedPath`, which `respond?` and `Router` now call, so the theorem names the function the server runs. The theorems are in a new test file, `test/RoutingTests/RoundTrip.lean`. The PR also updates two README sections, the CHANGELOG and the comment above the examples in `Handler.lean`.
