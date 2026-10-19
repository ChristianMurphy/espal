The README says the round trip from `linkFor` to `dispatch` isn't proved, because `String.splitOn` and `String.toNat?` have no lemmas in core. Lean 4.35.0 now proves `Nat.toNat?_repr`, which shows that `String.toNat?` reads back what `toString` prints for a `Nat`. With it, this PR proves the round trip down to a link's segments:

- `dispatch_pathOf`: dispatching a link's decoded segments calls the handler with the values passed to `linkFor`, when every `String` capture is linkable.
- `applyLink_linkFor`: the string `linkFor` builds is those segments, encoded and joined with `/`.

Splitting the string back into segments has no proof yet, since `String.splitOn` has no lemmas. The examples in `Handler.lean` and the Plausible property still cover that step.

The theorems are in a new test file, `test/RoutingTests/RoundTrip.lean`. The PR also updates the README's formal verification section and the comment above those examples. The library itself doesn't change.
