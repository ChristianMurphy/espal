`dispatchTable` and `matchTable` try each route in order, so the time to dispatch a request grows with the number of routes. A request that matches nothing pays for every route twice, since the trailing-slash check in `respond?` scans again.

A segment trie, built once in `toHandler` and `Router.toHandler`, would fix that. For `/users/42/posts`, it follows `users`, then a capture, then `posts`, so its work grows with the length of the path, whatever the number of routes. Each node branches on a literal, a `Nat` capture or a `String` capture, and keeps the lowest route index. So it picks the route `matchTable` picks, and the existing `Route.tryDispatch` then runs that route. Results stay the same.

A lighter option is an index on the first segment. It maps `users` to the routes that start with it, and dispatch tries those in order. That takes one lookup where the trie takes one per segment, so it's a little faster when routes start with different literals. When many routes share a first segment, though, the lookup returns all of them, and dispatch scans them as it does today. That happens to every route under `/api`, or under a mount.

I compared the three in a [prototype](https://github.com/ChristianMurphy/espal/blob/explore/lean-routing/explorations/lean-routing/TrieBench.lean) on Lean 4.35.0, pinned to one CPU. One route table gives each route its own first literal, and the other puts every route under `/api`. Times are medians of three runs, in microseconds.

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

The trie stays at 0.4 to 0.5 µs whatever the route table looks like. The index is about 0.1 µs faster where it works, and it's about 35 lines of code against the trie's 60. Under `/api`, though, it's as slow as the scan.

None of this matters much yet. On the same machine, with Lean 4.36.0-rc1, Std.Http spent 360 µs of CPU on a request. An app with many routes would notice once Std.Http gets faster.

Would a trie be a good fit? If you'd rather keep the code small, the index would also help, with the shared-prefix case documented. Either way, I could open a pull request and see it through review. I'd test it against `matchTable`, and try for a theorem that the two agree.
