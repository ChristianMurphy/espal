# Prepared statements in espal-postgres, 23 November 2026

These runs compare `espal-postgres` before and after it prepares each SQL text once per session. The [earlier runs](../2026-11-14-cloud-4vcpu/README.md) found that Postgres parsed and planned the text on every query, and that this limited four connections.

## Setup

The runs used a shared 4-vCPU cloud VM, an Intel Xeon at 2.10 GHz with 15 GB of memory. Postgres 16.15 ran pinned to CPU 2 with its default settings. Each client ran pinned to CPUs 0 and 1. The `world` table held 10,000 rows, and each query looked one row up by primary key.

Both clients are `lake exe postgres-bench` in `tests/`, on Lean 4.35.0, through the pool's read-only sessions with the default time limit.

- **Unprepared** is the build from `main` before this change. It sends the SQL text with each query.
- **Prepared** is the build with this change. Each session prepares the text on first use and runs it by name after that.

`run.py` ran five sets of five-second runs. Each set ran both builds in every shape, in an order that alternated between sets, since a shared VM drifts. It also read how busy CPU 2 was during each run, which is Postgres's CPU time. `raw/` holds each set and `raw/summary.txt`.

## Queries per second

Each cell gives the median of five sets, with the range in brackets.

| Client | One query in flight | One connection, 256 in flight | Four connections, 256 in flight |
|---|---|---|---|
| Unprepared | 6,896 (6,111 to 7,109) | 23,078 (21,866 to 23,588) | 35,127 (32,299 to 36,844) |
| Prepared | 8,262 (7,852 to 8,540) | 20,358 (19,965 to 21,802) | 53,030 (51,984 to 54,058) |

Within each set, the prepared build reached this share of the unprepared build's rate.

| Shape | Lowest | Highest |
|---|---|---|
| One query in flight | 114% | 133% |
| One connection, 256 in flight | 88% | 92% |
| Four connections, 256 in flight | 147% | 161% |

## CPU per query

Each cell gives the median client CPU, then the median Postgres CPU.

| Client | One query in flight | One connection, 256 in flight | Four connections, 256 in flight |
|---|---|---|---|
| Unprepared | 117.3 µs, 68.8 µs | 63.6 µs, 32.5 µs | 47.9 µs, 27.8 µs |
| Prepared | 117.7 µs, 36.7 µs | 70.3 µs, 21.6 µs | 35.7 µs, 17.2 µs |

These set the client's cost beside the 360 µs that Std.Http spends on a request in the [HTTP spike](../../http/2026-10-18-cloud-4vcpu/README.md).

## What the numbers say

- **Four connections.** Postgres spends 17.2 µs of CPU on a prepared query, down from 27.8 µs. Its one core was 98 to 99 percent busy before and is 89 to 92 percent busy now, so the rate rises by about half. The spike's client reached 50,443 queries per second in this shape in the earlier runs.
- **One query in flight.** Each query waits on Postgres, so the shorter server time raises the rate by 14 to 33 percent. Client CPU per query stays the same.
- **One connection with 256 in flight.** The prepared build is 8 to 12 percent slower, and spends about 7 µs more client CPU per query. One connection's reader task limits this shape, and Postgres was 43 to 50 percent busy. A separate check ran the new build with preparing switched off beside the other two, and `raw/preparing-off.txt` has its rates. That build reached 88 to 100 percent of the unprepared build's rate, and the prepared build 91 to 99 percent. The check doesn't separate the session's bookkeeping from the prepared path, so these runs don't say where the time goes.

## What follows

A pool has four sessions of each kind by default, which is the shape that gains. The loss on one busy connection needs a profile, as does the gap with one query in flight from the earlier runs.
