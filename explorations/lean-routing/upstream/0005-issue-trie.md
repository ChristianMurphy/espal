Dispatch compares a request with each route in turn until one matches, so the cost grows with the route table. A request that matches no route goes through every route twice. The second pass is `respond?` checking whether a trailing slash would match, for a redirect. With 1,000 routes, a request for the last one takes about 15 µs, or 21 µs when every route starts with `/api`.

A segment [trie](https://en.wikipedia.org/wiki/Trie) built once in `toHandler` and `Router.toHandler` would bring that to about 0.5 µs at any size, and about 0.1 µs for a 404. It finds the same route `matchTable` finds and runs it with `Route.tryDispatch`, so the API and the results stay the same. Go's httprouter [explains a routing tree](https://github.com/julienschmidt/httprouter#how-does-it-work) built on the same idea.

If a trie is more code than you want to maintain, two smaller changes would also help. An index on the first segment is about half the code, and slightly faster than the trie when routes start with different literals. Routes that share a first segment still get compared one by one. So it doesn't help when every route starts with `/api`, or in an app built from mounts.

Keeping the scan and documenting its cost would also work. That cost is small next to the time Std.Http spends on a request today.

From a [prototype](https://github.com/ChristianMurphy/espal/blob/explore/lean-routing/explorations/lean-routing/TrieBench.lean) with 1,000 routes:

| Route table | Scan | Index | Trie |
|---|---|---|---|
| Different first segments | 15.4 µs | 0.3 µs | 0.4 µs |
| All under `/api` | 20.8 µs | 23.1 µs | 0.5 µs |

Would a trie be a good fit? If so, I could open a pull request with tests against `matchTable` and see it through review.
