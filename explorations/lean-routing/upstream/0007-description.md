Closes #8.

`toHandler` and `Router.toHandler` now find a request's route with a segment trie built once over the table. A lookup tries only the routes shaped like the request, so its time doesn't grow with the rest of the table. Theorems tie the trie to `matchTable` and bound its memory.

### How it works

- One walk of the trie collects the routes that could match the path, or the path with a trailing slash added.
- Both kinds of capture share one edge, so the trie only narrows the table. `Route.tryMatch` still decides, run on the candidates in table order.
- Edges live in `Std.HashMap`s keyed by node number, since Lean rejects an inductive type nested through `HashMap`.
- The trie lives in `Routing.Internal`. `respond?`, `wantsSlash` and `slashRedirect?` keep their signatures and still scan a list.

### Guarantees

- `RouteIndex.first_of` and `RouteIndex.wantsSlash_of` prove that the trie gives the answers `matchTable` gives, for every table, method and path. They use only Lean's standard axioms.
- `RouteIndex.memory_of` bounds the trie by one node per pattern segment, plus the root. Each node but the root has one edge into it, and each route's index appears once.
- The proofs in `test/RoutingTests/Trie.lean` are 447 lines, for 92 lines in `Routing/Trie.lean`.
- The `Server` and `Router` tests, which send real requests, pass unchanged.

### Performance

Median µs over three runs, from this [benchmark](https://github.com/ChristianMurphy/espal/blob/explore/lean-routing/explorations/lean-routing/trie/results.md). Each pattern has a `GET` and a `POST` route, and the no-match columns include the trailing-slash check.

| Routes | First route, scan | First route, trie | Last route, scan | Last route, trie | No match, scan | No match, trie |
|---|---|---|---|---|---|---|
| 20 | 0.26 | 0.57 | 0.74 | 0.70 | 0.72 | 0.19 |
| 200 | 0.24 | 0.55 | 3.42 | 0.62 | 5.23 | 0.17 |
| 2,000 | 0.37 | 0.85 | 33.64 | 0.79 | 57.87 | 0.18 |

The trie costs about 0.3 µs more for a route near the top of a small table. Building it takes 0.36 ms for 2,000 routes, once per handler. For scale, Std.Http spends about 360 µs of CPU on a request on the same VM.

### Notes

- A request that a sub-router serves walks that router's trie twice, once for the parent's check and once to serve it.
- This PR and #10 both add a line to the README's formal verification list. I'll rebase whichever merges second.
