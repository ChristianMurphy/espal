# `api` compile-time results, 26 October 2026

`lake exe compile-bench` produced these numbers. It generates a module with an `api` table of N routes, compiles it three times with `lake env lean`, and reports the median. Every route has the form `GET "/api/items/r{i}/:id"`, so the table check compares every pair of routes through three segments. The module with 0 routes only imports `EspalRoute`.

## Setup

The first runs used a shared 4-vCPU cloud VM with an Intel Xeon at 2.10 GHz and 15 GB of memory. They used Lean 4.35.0 and the `api` command at commit 5c1a6f9. `raw.txt` has three sets of runs.

CI run 95 then ran the benchmark once on GitHub's `ubuntu-latest` runner, at commit 8411e3c with the same `api` command. `raw-github.txt` has its output.

## Results

| Routes | VM median (s) | VM range (s) | Runner median (s) | Runner range (s) | CI budget (s) |
|---|---|---|---|---|---|
| 0 | 0.85 | 0.79 to 1.25 | 0.66 | 0.66 to 0.75 | 2 |
| 10 | 1.52 | 1.25 to 1.79 | 1.04 | 1.02 to 1.06 | 2.5 |
| 50 | 4.23 | 3.78 to 4.56 | 2.81 | 2.75 to 2.82 | 6 |
| 200 | 22.57 | 21.11 to 24.50 | 13.92 | 13.81 to 14.07 | 30 |

Each VM median is the middle of the three set medians, and each VM range covers all nine runs. The runner's numbers come from one set of three runs. Each budget is about twice the runner's median, so CI fails when compile time roughly doubles.

## Where the time goes

Lean's profiler splits the 200-route module like this:

- 12.9 s of kernel checking. The table check takes 7.2 s of it, and it grows with the square of the route count. Most of the rest checks the 200 per-route theorems. Each check unfolds `routes[idx]`, so it costs more the later the route.
- 5.4 s in Lean's interpreter, which runs the command's elaborator.
- 4.2 s of tactic execution, of which `simp` takes 0.2 s.
