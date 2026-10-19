Closes #8.

`toHandler` and `Router.toHandler` now find a request's route with a segment trie, built once over the table. Matching takes between 0.5 and 0.7 µs whether a table has 20 routes or 2,000. The scan grows by about 15 ns per route. `RouteIndex.matchTable_of` proves that the trie picks the route `matchTable` picks, for every table, method and path.

A lookup follows the path's segments through the trie and collects the routes whose pattern could match. A literal edge carries the segment's text, and both kinds of capture share one edge. So the trie only narrows the table, and `Route.tryMatch` still decides, run on the candidates in table order. The proof needs two facts about the trie. It never drops a route that matches, and the candidates come out sorted. Inserting a route only adds edges, which keeps the proof of the first fact short.

The trie keeps its edges in `Std.HashMap`s keyed by node number, because Lean rejects an inductive type nested through `HashMap`. `Routing/Trie.lean` adds 77 lines. The proof in `test/RoutingTests/Trie.lean` is 253 lines and uses only Lean's standard axioms. The `Server` and `Router` tests, which send real requests, pass unchanged through the trie.

`respond?`, `wantsSlash` and `slashRedirect?` now take a `RouteIndex` instead of a list of routes, so code that calls them directly needs `RouteIndex.of`. Keeping the list signatures would rebuild the trie on every call. If you'd prefer that, I can add wrappers that do so.

Median times in µs over three runs, from this [benchmark](https://github.com/ChristianMurphy/espal/blob/explore/lean-routing/explorations/lean-routing/trie/results.md). Each pattern there has a `GET` and a `POST` route.

| Routes | First route, scan | First route, trie | Last route, scan | Last route, trie | No match, scan | No match, trie |
|---|---|---|---|---|---|---|
| 20 | 0.26 | 0.50 | 0.56 | 0.56 | 0.37 | 0.12 |
| 200 | 0.26 | 0.50 | 3.12 | 0.48 | 2.72 | 0.11 |
| 2,000 | 0.24 | 0.47 | 26.92 | 0.55 | 24.69 | 0.11 |

The trie costs about 0.25 µs more than the scan for a route near the top of a small table. Building it takes about 0.36 ms for 2,000 routes, once per handler. Both costs are small next to the 360 µs of CPU that Std.Http spends on a request on the same VM.

This PR and #10 both add a line to the README's formal verification list, so whichever merges second needs a small rebase. I'll do that rebase.
