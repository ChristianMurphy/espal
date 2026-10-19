Dispatch tries each route in order, so every request pays for the whole route table. A request that finds no route pays for it twice. With 1,000 routes that's about 15 µs a request, or 21 µs when they all sit under a shared prefix like `/api`.

A segment trie, built once in `toHandler` and `Router.toHandler`, would keep dispatch near 0.5 µs at any size, and 404s near 0.1 µs. It would pick the route `matchTable` picks and hand it to `Route.tryDispatch`, so the API and every result stay the same.

If a trie is more than you'd like to maintain:

- **An index on the first segment.** It's about half the code and a little faster when routes start with different literals. Routes that share a first segment, such as everything under `/api` or a mount, still get scanned.
- **Keep the scan** and document the cost, which is small next to what Std.Http spends on a request today.

From a [prototype](https://github.com/ChristianMurphy/espal/blob/explore/lean-routing/explorations/lean-routing/TrieBench.lean) with 1,000 routes:

| Route table | Scan | Index | Trie |
|---|---|---|---|
| Different first segments | 15.4 µs | 0.3 µs | 0.4 µs |
| All under `/api` | 20.8 µs | 23.1 µs | 0.5 µs |

Would a trie be a good fit? If so, I could open a pull request, tested against `matchTable`, and see it through review.
