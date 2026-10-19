# Changes to offer lean-routing

Each patch applies on commit `75d8bc3`, except `0002`, which applies on top of `0001`. `0007` touches the same README list as `0001`, so the second to merge needs a small rebase. On Lean 4.35.0, `lake test` passed with no warnings on each branch.

| Patch | Change | Size | What changes for users |
|---|---|---|---|
| `0001` | Prove that a request for a link reaches its handler, given two fuzzed assumptions about Std.Http, described in `0001-description.md`, opened as [#10](https://github.com/paulbutcher/lean-routing/pull/10) | 141 lines added, mostly one new test file | Nothing |
| `0002` | A `Nat` capture matches only the digits a link renders | 25 lines on top of `0001` | `/users/042` gets a 404 |
| `0003` | Reject two `route_table` rows with the same pattern | 20 lines | A table with two such rows fails to compile |
| `0004` | Spacing and line-break hints for `route_table` | 6 lines | Printed tables keep one row per line |
| `0005` | An issue asking about matching routes with a trie, opened as [#8](https://github.com/paulbutcher/lean-routing/issues/8) | An issue, with a prototype | Nothing until a pull request lands |
| `0006` | An issue about links to another host from a mount root that starts with an empty segment, opened as [#9](https://github.com/paulbutcher/lean-routing/issues/9) | An issue | Nothing until a fix lands |
| `0007` | Match requests with a trie, for issue #8, described in `0007-description.md` | 92 lines of library code and 447 lines of proof | Matching no longer slows as a table grows |

## How realistic each one is

- **`0001`.** lean-routing's `CLAUDE.md` prefers a proven theorem over a property, and asks contributors to check whether a property has become provable. Its README names `String.toNat?` as an obstacle. Lean's standard library now proves `Nat.toNat?_repr` ([lean4#12828](https://github.com/leanprover/lean4/pull/12828)), which Lean 4.35.0 includes. The server splits a path with Std.Http, so the proof doesn't need `String.splitOn`. Std.Http's parser, decoder and encoder have no lemmas, so the theorem assumes two properties of them, and the tests fuzz both.
- **`0002`.** It applies a rule from earlier releases to `Nat` captures. Releases 0.8.0 and 0.9.0 refuse segments that no link can produce. It changes behaviour for every consumer, which lean-routing's `CLAUDE.md` asks a proposal to say. In `dispatch-bench`, dispatch time stayed within run-to-run noise.
- **`0003`.** It mirrors the existing check for a repeated name. It catches identical patterns only. A partial overlap, such as a `String` capture listed before a literal, stays legal, since the order of routes decides it.
- **`0004`.** It only changes how tables print. lean-fmt then prints one row per line with spaces around `:=`. It puts the opening bracket on the table's first line, where the README's examples put it on the next.
- **`0005`.** Dispatch costs about 15 ns per route, so it grows with the number of routes. A trie keeps the same results with no change to the API, and it stays near 0.5 µs whether or not routes share a prefix. It's a question rather than a patch, since the maintainer may prefer another structure.
- **`0006`.** A browser sends a link that starts with `//` to another host. A test in Chromium confirmed it for links from `linkFor` and `mountLink`, and for the 308 redirect. Only a root or route built by hand can start with an empty segment, because `route_table` and `mount_routes` reject one.
- **`0007`.** The maintainer's reply on #8 asks that a trie keep or improve the formal guarantees, and keep the code lean. `RouteIndex.matchTable_of` proves that the trie picks the route `matchTable` picks. The prototype behind #8 returned only the lowest-numbered route whose pattern matched, so it skipped a later route with the right method. Its check used `GET` routes only, which hid that. The trie in `0007` collects every candidate and lets `Route.tryMatch` decide. The [benchmark](../trie/results.md) checks mixed methods.

lean-routing has merged outside pull requests before. Val's [#1](https://github.com/paulbutcher/lean-routing/pull/1) moved it to Lean 4.34.1, and [#2](https://github.com/paulbutcher/lean-routing/pull/2) percent-encoded `String` captures in links.

## Asks dropped after prototyping

- **Theorems in the library.** lean-routing's `CLAUDE.md` says that a theorem belongs in test code unless the production code needs it. lean-routing exposes its definitions, so Espal can prove what it needs in its own package. The proofs in `0001` compile from lean-routing's test package, which uses the library as any dependent does.
- **A `Router` for other handler types.** A pure handler fits `Router` unchanged. Espal's interpreter turns the handler's effects into a Std.Http response inside the function that `Router` calls, and a probe of that compiled.
- **Capture types through a codec class.** A capture's type would have to live in `PathSeg`, which would then lose `DecidableEq` and move up a universe. `MatchedRoute` needs `DecidableEq`, and Std.Http's request extensions need its `TypeName` instance for a type in `Type`. Espal can declare richer types in its endpoint layer over a `String` capture, with its own codec for each.

## What Espal builds itself

- **One URL per resource.** Std.Http decodes the path before dispatch, so `/users/%34%32` reaches user 42 even with `0002`. Espal compares the request's encoded path, which `URI.Path.segments` keeps, with the link rebuilt from the captured values. When they differ, it redirects to the link. That check also covers `042` and `4_2`, so `0002` helps lean-routing's other users more than it helps Espal.
- **The reachability check.** Dispatch takes the first route that matches. Give each capture in a later route a value that equals no literal in an earlier route. Make each `String` capture's value something other than a number. That path reaches the later route unless one earlier route accepts every segment of it. So a check of each pair of routes decides reachability, and the proof is where the work lies. A `.lit ""` segment and the trailing slash that `dispatch` tolerates need their own cases.
