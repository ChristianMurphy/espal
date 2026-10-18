# lean-linq trial

This trial checks [lean-linq](https://github.com/palladin/lean-linq) as the query layer, for the dependency trials in the [spikes and a baseline](../../ROADMAP.md#spikes-and-a-baseline) milestone. It pins commit `463e34a` from 13 October 2026, under the MIT license.

Everything ran on the same shared 4-vCPU cloud VM as the HTTP and Postgres spikes. The databases came from Ubuntu 24.04 packages rather than lean-linq's Docker Compose file. They were Postgres 16.15, MySQL 8.0.46 and the system's SQLite 3.45. SQL Server didn't run.

## Files

- `Trial/Schema.lean` declares a cut-down tenant app schema.
- `Trial/Budget.lean` writes Espal-shaped programs against lean-linq's budgets, with the errors it gives for the ones it rejects.
- `Trial/Sql.lean` checks the SQL it emits against the cases under [no SQL injection](../../ROADMAP.md#no-sql-injection).
- `PgSmoke.lean` runs a budgeted program on Postgres through lean-linq's libpq driver, from this package rather than lean-linq's own.
- `ModuleCheck.lean` imports lean-linq from a file in Lean's module system.
- `patches/lean-4.36.patch` is the change lean-linq needs on Lean 4.36.0-rc1.
- `patches/mariadb-connector-c.patch` points lean-linq's MySQL driver at MariaDB Connector/C.
- `module_probe.py` is the first step of moving lean-linq to the module system.
- `upstream/` holds the changes offered to lean-linq, as patches with descriptions, and the order to send them in.

## Running it

Install `libsqlite3-dev`, `libpq-dev`, `freetds-dev` and `libmysqlclient-dev`, since lean-linq's build needs all four. Then start the test databases from lean-linq's `docker-compose.yml`, or local servers with the same ports and credentials.

```bash
lake build              # the Trial modules check every claim below that ends in a #guard
.lake/build/bin/pg-smoke
lake env lean ModuleCheck.lean
```

## Builds and tests

| Lean | Change to lean-linq | Golden SQL checks | SQLite sweep | Postgres sweep | MySQL sweep |
|---|---|---|---|---|---|
| 4.35.0 | none | 1,620 pass | 395 match | 395 match | 395 match |
| 4.36.0-rc1 | one line | 1,620 pass | 395 match | 395 match | 395 match |

- The golden checks compare the SQL text and parameters of 405 queries in four dialects. A sweep runs those queries through a native driver and compares the rows with lean-linq's evaluator, skipping 10 cases.
- Lean 4.36 removed `String.data`, which one function used. `String.toList` works on both versions.
- The library and its playground built in 149 seconds.

## Budgets against the statement budget

The [statement budget](../../ROADMAP.md#statement-budget) lists what Espal's prototype lacked. The `Db c r α` type in lean-linq covers most of it.

- **Upper bounds.** The grade `r` bounds the operations a program sends from above. `weaken` raises a cheap branch to the cost of an expensive one. `FreerD.runWithG_count_le` proves the bound for any interpreter that certifies each operation, and `DbP.runWithP_count_le` for the evaluator.
- **`do` notation.** The `db!` block accepts `let x ← e`, `let x := e`, `for`, `raise`, `transaction` and a final `return`. It has no `if` clause, so a branch is a term on the right of `let`.
- **A query for each derived row** fails to type-check. The error reads `failed to synthesize instance of type class HasBillF`, followed by `maximum recursion depth has been reached`. Neither mentions the loop.
- **A query for each fetched row** type-checks, priced in table sizes: `Db Exam (submissions.size + 1) _`. `exec` takes a fixed budget and refuses it, with the goal `submissions.size + Grade.nat 1 ≤ Grade.nat 1000`, and `execPg` has the same obligation. `execPgAll` runs it unchecked. Espal can get its rule by accepting only fixed grades at the handler boundary.
- **Bounded fan-out.** `fetchLimit n` returns at most `n` rows, which `Query.run_limit_length_le` proves for the evaluator, and a loop over them costs `n` more.
- **Transactions.** `BEGIN`, `COMMIT` and `ROLLBACK` fall outside the count, and lean-linq's README says so.
- **Pipelining.** Not yet. Every native driver sends one statement per round trip. Its author plans a separate layer for independent queries, where Postgres pipelining would go.
- **Native counts.** The count theorems cover the evaluator. The native drivers rest on the differential sweeps.

The library also bounds result sizes. `Query.run_gcard` proves that a query's rows fit its symbolic bound, which overlaps [row bounds and query cost](../../ROADMAP.md#row-bounds-and-query-cost).

## SQL

- Values always travel as parameters, and a query's text stays the same when the values change. That holds in the tests but has no theorem like Espal's `sqlText_eraseParams`.
- A user's `%` reaches a `LIKE` pattern unescaped.
- Checked compilation accepted 70,000 parameters for Postgres, which allows 65,535, and 3,000 for SQL Server, which allows 2,100. An `IN` list sends one parameter per value.
- The compiler quotes identifiers and doubles any `"` or `]` inside them.
- Columns carry their nullability in their types, and the evaluator follows SQL's three-valued logic. Espal's prototype avoided `NULL` altogether.

## Drivers

- **Postgres.** The library's own driver calls libpq's blocking functions, one statement at a time, and reads every row before returning. Espal chose its own client on libpq in pipeline mode. That client could run lean-linq's output. `toSqlChecked` gives the SQL and parameters, and `Pg.toWire` rewrites placeholders to `$1` form. The library's cell parser then turns text results into typed values. `pg-smoke` ran a two-row fan-out on Postgres and printed `[1, 1]`.
- **MySQL and MariaDB.** Moving from libmysqlclient to MariaDB Connector/C took four changed lines in lean-linq's lakefile and no change to its C code. The C code already handles MariaDB's `my_bool`. With `libmariadb.so.3` linked, the MySQL sweep matched all 395 cases against MySQL 8. MariaDB's server didn't run. With libmysqlclient, the sweep printed the library's warning that it will drop `MYSQL_OPT_RECONNECT`.
- **SQLite and SQL Server** use the system sqlite3 library and FreeTDS.

## As a dependency

- Espal's sources use Lean's module system, and a module can't import lean-linq: `cannot import non-module LeanLinq from module`. Moving lean-linq over isn't mechanical. After `module_probe.py`, making 146 private declarations public and marking six elaborators and macros `meta`, 2 of its 24 modules still failed. `Core/Grouped.lean` uses private constructors inside public definitions, which gave 76 errors. `Theorems.lean` rewrites with `List.filterAuxM`, whose body Lean's core doesn't expose to modules. Modules after those two didn't get checked.
- `lake build --wfail` fails, because lean-linq logs 35 warnings on Lean 4.35.0, in five modules. Most flag deprecated names and unused variables or `simp` arguments.
- The lakefile in lean-linq looks for all four client libraries when Lake loads it, and stops if one is missing. With FreeTDS removed, this package's build stopped at `libsybdb (freetds) not found`.
- lean-linq's link arguments stay inside its own package. An executable that uses its Postgres driver has to link libpq itself, as `pg-smoke` does.

## Code style

Espal's `scripts/Lint.lean`, run over lean-linq's modules, reports 10 problems.

- Eight are in elaborators and macros, which run at compile time: two `partial` functions and calls such as `getElem!` and `Expr.getArg!`.
- `scanParams` in `Driver/Wire.lean` is `partial`. The Postgres and MySQL drivers call it on every query to rewrite placeholders.
- `drain` in the SQL Server driver is `partial`.
- The library has no `sorry`, `unsafe` code or extra axioms.

## Size and activity

- 8,767 lines of Lean in the library, 6,606 in tests and 1,503 of C.
- 83 commits from one author, the latest on 13 October 2026.
