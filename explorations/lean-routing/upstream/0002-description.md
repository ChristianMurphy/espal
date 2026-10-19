Stacked on #11, so only the last commit, [1e48799](https://github.com/ChristianMurphy/lean-routing/commit/1e48799212604510ceb42a17408f60b00008eb7f), is new here. I'll rebase it once #11 merges.

A `Nat` capture now matches only the digits `toString` prints. `String.toNat?` accepts leading zeros and `_` separators, so `/users/042` and `/users/4_2` both reach user 42 today. `linkFor` only ever builds `/users/42`. It follows 0.8.0 and 0.9.0, which stopped matching segments that no link can produce.

This changes behaviour for every consumer, since a request for `/users/042` gets a 404.

- `dispatch` reads a `Nat` capture with a new `parseNat?`, which keeps only what `toString` prints back.
- `parseNat?_toString` and `toString_of_parseNat?` prove both directions. Two `#guard` tests pin `042` and `4_2`.
- The trie proof from #11 needed a one-line change. The trie benchmark stayed within run-to-run noise.
- A percent-encoded `/users/%34%32` still reaches user 42, because Std.Http decodes the path before dispatch.
- If #10 merges first, its `dispatch_pathOf` needs these theorems, so they move to `RoundTrip.lean`. I've checked that all three PRs pass `lake test` together.
