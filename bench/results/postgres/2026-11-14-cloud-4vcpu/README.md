# espal-postgres against the spike, 14 November 2026

These runs compare the `espal-postgres` client with the libpq client from the [Postgres spike](../2026-10-18-cloud-4vcpu/README.md). The spike's client was built for one prepared query. `espal-postgres` runs any statement, so this shows what that costs.

## Setup

The runs used a shared 4-vCPU cloud VM, an Intel Xeon at 2.10 GHz with 15 GB of memory. Postgres 16.15 ran pinned to CPU 2 with its default settings. Each client ran pinned to CPUs 0 and 1. The `world` table held 10,000 rows, and each query looked one row up by primary key.

- **Bare C libpq** is the spike's C program, which marks the ceiling.
- **Spike client** is `pg-bench libpq` from the `explore/postgres` branch, on Lean 4.36.0-rc1. It prepares the query once and reads binary results.
- **espal-postgres** is `lake exe postgres-bench` in `tests/`, on Lean 4.35.0. It sends the SQL text with each query and reads text results, through the pool's read-only sessions with the default time limit.

`run.py` ran five sets of five-second runs. Each set ran every client in every shape, in an order that rotated between sets, since a shared VM drifts. `raw/` holds each set and `raw/summary.txt`.

## Queries per second

Each cell gives the median of five sets, with the range in brackets.

| Client | One query in flight | One connection, 256 in flight | Four connections, 256 in flight |
|---|---|---|---|
| Bare C libpq | 19,495 (18,383 to 19,779) | 42,485 (38,953 to 42,667) | 45,823 (43,177 to 46,672) |
| Spike client | 10,157 (9,734 to 10,610) | 23,463 (22,731 to 24,166) | 50,443 (49,185 to 52,819) |
| espal-postgres | 7,149 (6,995 to 7,516) | 24,797 (23,125 to 25,608) | 44,122 (43,265 to 45,270) |

Within each set, `espal-postgres` reached this share of the spike client's rate.

| Shape | Lowest | Highest |
|---|---|---|
| One query in flight | 69% | 73% |
| One connection, 256 in flight | 99% | 113% |
| Four connections, 256 in flight | 82% | 90% |

## Client CPU per query

| Client | One query in flight | One connection, 256 in flight | Four connections, 256 in flight |
|---|---|---|---|
| Bare C libpq | 20.7 µs | 12.1 µs | 11.7 µs |
| Spike client | 86.0 µs | 59.9 µs | 32.9 µs |
| espal-postgres | 115.9 µs | 60.1 µs | 40.7 µs |

These set the client's cost beside the 360 µs that Std.Http spends on a request in the [HTTP spike](../../http/2026-10-18-cloud-4vcpu/README.md).

## What the numbers say

- **One busy connection.** The two Lean clients match, in rate and in CPU. One connection's reader task limits both.
- **Four connections.** `espal-postgres` stops at Postgres's one core. `postgres-cpu.py` measured CPU 2 while each client ran, and `raw/postgres-cpu.txt` has its output. With `espal-postgres` CPU 2 was 97 to 98 percent busy, at 21 to 24 µs per query. With the spike client it was 78 to 80 percent busy, at about 15 µs per query. Postgres parses and plans the SQL text on every query, which a prepared statement does once.
- **One query in flight.** `espal-postgres` runs about 30 percent behind, and spends 30 µs more client CPU per query. These runs don't say where that goes. The pool takes a lock and a turn per statement, the results arrive as text, and the two programs use different Lean versions.
- **The time limit.** A separate check ran `espal-postgres` with the limit off. Its rate stayed inside the range above, so `statement_timeout` costs nothing these runs can see.

## What follows

Prepared statements would take the parsing off Postgres's core, and that is the gap at four connections. The gap with one query in flight needs a profile first.
