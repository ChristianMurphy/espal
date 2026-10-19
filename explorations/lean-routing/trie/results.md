# Route trie benchmark

`TrieBench.lean` times two ways for lean-routing to find a request's route. `matchTable`, the scan, tries each route in order. `RouteIndex.matchTable`, the trie, follows the path through a trie built once over the table, then tries only the routes it finds. It runs against commit `757b7eb` on the fork's `route-trie` branch, on Lean 4.35.0.

Before timing a table, it checks that both pick the same route for 30,000 lookups. Those cover `GET`, `POST` and `PUT`, trailing slashes and failed captures. A table holds each pattern, `/r<i>/:id:Nat` or `/api/r<i>/:id:Nat`, twice, for `POST` and then `GET`. So a table of 2,000 routes holds 1,000 patterns.

Each time is the mean over 200,000 `GET` lookups, pinned to CPU 2 of a 4-CPU VM. The tables give the median of three runs in microseconds, with the range in brackets. `runs.txt` holds the raw output. For scale, Std.Http spends about 360 µs of CPU on a request on this VM, as the [router overhead](../serve/router-overhead.json) measurement found.

| Routes | Table | First route, scan | First route, trie | Last route, scan | Last route, trie | No match, scan | No match, trie |
|---|---|---|---|---|---|---|---|
| 20 | own first literal | 0.26 (0.26–0.32) | 0.50 (0.49–0.67) | 0.56 (0.51–0.61) | 0.56 (0.51–0.59) | 0.37 (0.29–0.39) | 0.12 (0.11–0.14) |
| 200 | own first literal | 0.26 (0.25–0.40) | 0.50 (0.45–0.56) | 3.12 (2.79–3.69) | 0.48 (0.47–0.67) | 2.72 (2.38–2.80) | 0.11 (0.11–0.12) |
| 2,000 | own first literal | 0.24 (0.23–0.24) | 0.47 (0.45–0.69) | 26.92 (26.91–30.84) | 0.55 (0.54–0.61) | 24.69 (23.04–25.31) | 0.11 (0.10–0.12) |
| 20 | shared /api prefix | 0.26 (0.24–0.27) | 0.55 (0.54–0.81) | 0.70 (0.56–0.78) | 0.55 (0.54–0.62) | 0.34 (0.34–0.53) | 0.17 (0.16–0.17) |
| 200 | shared /api prefix | 0.25 (0.23–0.28) | 0.50 (0.48–0.62) | 3.56 (3.24–3.73) | 0.73 (0.55–0.89) | 2.99 (2.83–3.12) | 0.17 (0.16–0.17) |
| 2,000 | shared /api prefix | 0.27 (0.25–0.43) | 0.54 (0.53–0.64) | 33.19 (32.22–34.75) | 0.64 (0.61–0.68) | 32.52 (31.74–32.56) | 0.17 (0.17–0.18) |

| Routes | Building the index, µs |
|---|---|
| 20 | 2.4 (2.2–2.5) |
| 200 | 30.9 (30.5–35.2) |
| 2,000 | 361.8 (312.8–473.9) |
