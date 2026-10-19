`dispatchTable` and `matchTable` try each route in order, so the time to dispatch a request grows with the number of routes. A request that matches nothing pays for every route twice, since the trailing-slash check in `respond?` scans again.

A segment trie, built once in `toHandler` and `Router.toHandler`, would keep dispatch time flat. Each node branches on a literal, a `Nat` capture or a `String` capture. It keeps the lowest route index, so it picks the route `matchTable` picks. The existing `Route.tryDispatch` then runs that route, so results stay the same.

I compared it with the scan and a lighter index in a [prototype](https://github.com/ChristianMurphy/espal/blob/explore/lean-routing/explorations/lean-routing/TrieBench.lean). The index maps each route's first literal to the routes that start with it. One route table gives each route its own first literal, and the other puts every route under `/api`. Times are medians of three runs on Lean 4.35.0, pinned to one CPU, in microseconds.

Request to the last route:

| Routes | Scan | Index | Trie | Scan under `/api` | Index under `/api` | Trie under `/api` |
|---|---|---|---|---|---|---|
| 10 | 0.37 | 0.24 | 0.42 | 0.43 | 0.47 | 0.51 |
| 200 | 3.12 | 0.28 | 0.50 | 3.76 | 4.00 | 0.54 |
| 1,000 | 16.28 | 0.27 | 0.45 | 20.09 | 21.86 | 0.52 |

Request that matches no route:

| Routes | Scan | Index | Trie | Scan under `/api` | Index under `/api` | Trie under `/api` |
|---|---|---|---|---|---|---|
| 10 | 0.19 | 0.06 | 0.11 | 0.24 | 0.27 | 0.19 |
| 200 | 2.72 | 0.07 | 0.11 | 3.91 | 4.01 | 0.19 |
| 1,000 | 13.16 | 0.07 | 0.13 | 19.69 | 21.16 | 0.20 |

The index is fastest when routes start with different literals, but under a shared prefix it scans every route. The trie stays near 0.5 µs either way. On the same machine, with Lean 4.36.0-rc1, Std.Http spent 360 µs of CPU on a request. A small app won't notice any of this today, but an app with many routes would once Std.Http gets faster.

The trie adds a data structure to maintain. If that's more than you'd like, the index is less code, or the scan could stay with its cost documented.

Would a trie be a good fit? If so, I could open a pull request and see it through review. I'd test it against `matchTable`, and try for a theorem that the two agree.
