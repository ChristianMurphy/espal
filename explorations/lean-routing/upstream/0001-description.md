The README lists the round trip from `linkFor` to `dispatch` as unproved, citing missing lemmas for `String.splitOn` and `String.toNat?`. This PR proves it, and names the steps that rest on `Std.Http` as assumptions, which the tests fuzz.

`requestSegments_linkFor` follows a link from `linkFor` through `Std.Http`'s request-target parser and decoder, as `toHandler` reads a request. Dispatching the result against the link's route calls the handler with the values passed to `linkFor`. Since the server splits a path with `Std.Http`, the proof doesn't need `String.splitOn`. For a `Nat` capture, Lean 4.35.0 proves `Nat.toNat?_repr`, which shows that `String.toNat?` reads back what `toString` prints.

`Std.Http`'s parser, decoder and encoder have no lemmas. So the theorem takes these two premises about them.

- `ReadsBack`: a link reads back as the segments it joins, if its first segment isn't empty. It also has to fit `Std.Http`'s default limits.
- `EncodesDigits`: percent-encoding leaves a number's digits alone.

`Handler.lean` fuzzes both with Plausible, using its existing generator. Without the first-segment condition, Plausible finds `[""]`, whose link `/` reads back as `[]`. The theorem also leaves out a route that starts with an empty literal, which #9 describes. It covers one route, so in a table an earlier route can still match the link first.

The theorems are in a new test file, `test/RoutingTests/RoundTrip.lean`. The library doesn't change. The PR also updates two README sections and the comment above the examples in `Handler.lean`.
