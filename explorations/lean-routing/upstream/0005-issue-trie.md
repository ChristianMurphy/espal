`dispatchTable` and `matchTable` try each route in order, so the time to dispatch a request grows with the number of routes. A request that matches nothing pays for every route twice, since the trailing-slash check in `respond?` scans again.

Dispatching to the last route took this long on Lean 4.35.0, pinned to one CPU:

| Routes | Matching request | No match |
|---|---|---|
| 10 | 0.4 µs | 0.2 µs |
| 200 | 3.2 µs | 2.5 µs |
| 1,000 | 15.4 µs | 13.2 µs |

On the same machine, with Lean 4.36.0-rc1, Std.Http spent 360 µs of CPU on a request. The scan is small next to that. It would matter more for an app with many routes once Std.Http gets faster.

A few ways to go:

1. **A segment trie, built once in `toHandler` and `Router.toHandler`.** Each node branches on a literal, a `Nat` capture or a `String` capture. It keeps the lowest route index, so it picks the route `matchTable` picks. The existing `Route.tryDispatch` then runs that route, so results stay the same. In a [prototype](https://github.com/ChristianMurphy/espal/blob/explore/lean-routing/explorations/lean-routing/TrieBench.lean), lookup took about 0.5 µs from 10 to 1,000 routes, and 0.1 µs for no match. The cost is a data structure to maintain.
2. **An index on the first segment.** Routes that start with a literal go in a map keyed by it. The rest stay in a list, and lookup merges the two by route index. It's less code. It helps most when routes start with different literals, and routes that share a first segment still scan.
3. **Keep the scan and document the cost.** Nothing changes, and apps with many routes know what to expect.

Would one of these be a good fit? If so, I could open a pull request for it and see it through review. I'd test it against `matchTable`, and try for a theorem that the two agree.
