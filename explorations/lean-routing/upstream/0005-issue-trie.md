`dispatchTable` and `matchTable` try each route in order, so the time to dispatch a request grows with the number of routes. A request that matches nothing pays for every route twice, since the trailing-slash check in `respond?` scans again.

A segment trie, built once in `toHandler` and `Router.toHandler`, would keep dispatch time flat. Each node branches on a literal, a `Nat` capture or a `String` capture. It keeps the lowest route index, so it picks the route `matchTable` picks. The existing `Route.tryDispatch` then runs that route, so results stay the same.

I compared it with the scan and a lighter index in a [prototype](https://github.com/ChristianMurphy/espal/blob/explore/lean-routing/explorations/lean-routing/TrieBench.lean). The index maps each route's first literal to the routes that start with it. One route table gives each route its own first literal, and the other puts every route under `/api`. Times are medians of three runs on Lean 4.35.0, pinned to one CPU, in microseconds.

Request to the last route:

| Routes | Scan | Index | Trie | Scan under `/api` | Index under `/api` | Trie under `/api` |
|---|---|---|---|---|---|---|
| 10 | 0.39 | 0.27 | 0.41 | 0.43 | 0.47 | 0.45 |
| 200 | 3.39 | 0.30 | 0.42 | 4.00 | 4.27 | 0.51 |
| 1,000 | 15.43 | 0.33 | 0.40 | 20.83 | 23.10 | 0.50 |

Request that matches no route:

| Routes | Scan | Index | Trie | Scan under `/api` | Index under `/api` | Trie under `/api` |
|---|---|---|---|---|---|---|
| 10 | 0.19 | 0.07 | 0.08 | 0.27 | 0.28 | 0.13 |
| 200 | 2.59 | 0.07 | 0.08 | 3.72 | 3.97 | 0.11 |
| 1,000 | 12.64 | 0.07 | 0.07 | 19.51 | 20.07 | 0.12 |

The index is about 0.1 µs faster than the trie when routes start with different literals, and it's less code. Under a shared prefix, though, it scans every route. The trie stays at 0.4 to 0.5 µs either way. On the same machine, with Lean 4.36.0-rc1, Std.Http spent 360 µs of CPU on a request. A small app won't notice any of this today, but an app with many routes would once Std.Http gets faster.

The trie adds a data structure to maintain. If that's more than you'd like, the index or the scan with its cost documented would also work.

Would a trie be a good fit? If so, I could open a pull request and see it through review. I'd test it against `matchTable`, and try for a theorem that the two agree.
