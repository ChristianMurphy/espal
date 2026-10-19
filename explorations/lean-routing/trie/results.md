# Route trie benchmark

`TrieBench.lean` times two ways for lean-routing to find a request's route. `matchTable`, the scan, tries each route in order. The trie that `toHandler` and `Router` build once over the table collects the routes that could match, then tries only those. It runs against commit `dab7840` on the fork's `route-trie` branch, on Lean 4.35.0.

Before timing a table, it checks that both give the same answers for 30,000 lookups. Each lookup asks which route matches and whether one would with a trailing slash added. They cover `GET`, `POST` and `PUT`, trailing slashes and failed captures. A table holds each pattern, `/r<i>/:id:Nat` or `/api/r<i>/:id:Nat`, twice, for `POST` and then `GET`. So a table of 2,000 routes holds 1,000 patterns.

The first two pairs of columns time a request for the first and the last route. The last pair times a path that matches nothing, which `Router` then checks again with a trailing slash added. The scan goes through the table twice for that, and the trie walks once.

Each time is the mean over 200,000 `GET` lookups, pinned to CPU 2 of a 4-CPU VM. The tables give the median of three runs in microseconds, with the range in brackets. `runs.txt` holds the raw output. For scale, Std.Http spends about 360 µs of CPU on a request on this VM, as the [router overhead](../serve/router-overhead.json) measurement found.

| Routes | Table | First route, scan | First route, trie | Last route, scan | Last route, trie | No match, scan | No match, trie |
|---|---|---|---|---|---|---|---|
| 20 | own first literal | 0.26 (0.24–0.40) | 0.57 (0.54–0.91) | 0.74 (0.59–0.92) | 0.70 (0.68–0.77) | 0.72 (0.61–0.78) | 0.19 (0.18–0.19) |
| 200 | own first literal | 0.24 (0.23–0.28) | 0.55 (0.53–0.64) | 3.42 (3.21–5.01) | 0.62 (0.61–0.89) | 5.23 (4.98–6.89) | 0.17 (0.17–0.24) |
| 2,000 | own first literal | 0.37 (0.23–0.43) | 0.85 (0.54–0.88) | 33.64 (32.97–38.16) | 0.79 (0.60–0.79) | 57.87 (54.35–58.81) | 0.18 (0.18–0.20) |
| 20 | shared /api prefix | 0.26 (0.25–0.28) | 0.72 (0.63–0.77) | 0.60 (0.57–0.65) | 0.73 (0.66–1.13) | 0.81 (0.75–1.22) | 0.30 (0.27–0.38) |
| 200 | shared /api prefix | 0.25 (0.24–0.28) | 0.62 (0.57–0.65) | 4.18 (3.83–4.31) | 0.71 (0.69–0.83) | 6.33 (5.56–8.59) | 0.29 (0.25–0.33) |
| 2,000 | shared /api prefix | 0.28 (0.28–0.36) | 0.68 (0.59–1.00) | 36.17 (34.86–39.99) | 0.78 (0.68–1.25) | 65.14 (63.15–74.47) | 0.25 (0.25–0.27) |

| Routes | Building the index, µs |
|---|---|
| 20 | 2.3 (2.2–2.6) |
| 200 | 32.6 (30.3–35.0) |
| 2,000 | 362.1 (321.1–390.5) |
