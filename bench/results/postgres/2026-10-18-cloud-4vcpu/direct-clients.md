# Direct client runs

Each run lasted 5 seconds with the client pinned to CPUs 0 and 1 and Postgres on CPU 2. `perf stat -e task-clock` measured the client's CPU time. The Lean clients spread their in-flight queries evenly over their connections.

| Client | Command | Queries per second | Client CPU per query |
|---|---|---|---|
| Bare C libpq | `bare-libpq 1 1 5` | 15,627 | 25.6 µs |
| Bare C libpq | `bare-libpq 1 64 5` | 38,143 | 13.9 µs |
| Bare C libpq | `bare-libpq 4 64 5` | 43,712 | 13.3 µs |
| Lean libpq client | `pg-bench libpq 1 1 5` | 7,871 | 102.2 µs |
| Lean libpq client | `pg-bench libpq 1 256 5` | 20,259 | 68.1 µs |
| Lean libpq client | `pg-bench libpq 4 256 5` | 48,062 | 33.8 µs |
| Lean wire client | `pg-bench wire 1 1 5` | 4,449 | 273.6 µs |
| Lean wire client | `pg-bench wire 1 256 5` | 20,336 | 67.7 µs |
| Lean wire client | `pg-bench wire 4 256 5` | 23,955 | 61.2 µs |

For the bare client the arguments are connections, queries in flight per connection, and seconds. For `pg-bench` they are the client, connections, total queries in flight, and seconds.
