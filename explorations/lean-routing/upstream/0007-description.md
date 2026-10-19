Closes #8.

`toHandler` and `Router.toHandler` now find a request's route with a segment trie, built once over the table. A request for a route takes 0.55 to 0.85 µs whether a table has 20 routes or 2,000. A path that matches nothing takes under 0.3 µs, including the trailing-slash check. `RouteIndex.first_of` and `RouteIndex.wantsSlash_of` prove that the trie gives the answers `matchTable` gives, for every table, method and path.

One walk of the trie collects the routes that could match the path, or the path with a trailing slash added. A literal edge carries the segment's text, and both kinds of capture share one edge. So the trie only narrows the table, and `Route.tryMatch` still decides, run on the candidates in table order. That walk answers both questions that `respond?` and `Router` ask. One is which route matches, and the other is whether one would with a trailing slash. The proof needs two facts about the trie. It never drops a route that matches, and the candidates come out sorted.

The trie lives in `Routing.Internal`, and the public functions keep their signatures. `respond?`, `wantsSlash` and `slashRedirect?` still take a list and scan it, and `respond?` shares its response code with the trie's path. The trie keeps its edges in `Std.HashMap`s keyed by node number, because Lean rejects an inductive type nested through `HashMap`. `Routing/Trie.lean` is 92 lines, and the proof in `test/RoutingTests/Trie.lean` is 308 lines. It uses only Lean's standard axioms. The `Server` and `Router` tests, which send real requests, pass unchanged through the trie.

Median times in µs over three runs, from this [benchmark](https://github.com/ChristianMurphy/espal/blob/explore/lean-routing/explorations/lean-routing/trie/results.md). Each pattern there has a `GET` and a `POST` route, and the no-match columns include the trailing-slash check.

| Routes | First route, scan | First route, trie | Last route, scan | Last route, trie | No match, scan | No match, trie |
|---|---|---|---|---|---|---|
| 20 | 0.26 | 0.57 | 0.74 | 0.70 | 0.72 | 0.19 |
| 200 | 0.24 | 0.55 | 3.42 | 0.62 | 5.23 | 0.17 |
| 2,000 | 0.37 | 0.85 | 33.64 | 0.79 | 57.87 | 0.18 |

The trie costs about 0.3 µs more than the scan for a route near the top of a small table. Building it takes about 0.36 ms for 2,000 routes, once per handler. Both costs are small next to the 360 µs of CPU that Std.Http spends on a request on the same VM.

A request that a sub-router serves walks that router's trie twice. The first walk answers the parent's question of whether the sub-router takes the request, and the second serves it. Before, the first took two scans of the table and the second at least one.

This PR and #10 both add a line to the README's formal verification list, so whichever merges second needs a small rebase. I'll do that rebase.
