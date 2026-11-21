# lean-linq as the query core

Espal builds its query layer on [lean-linq](https://github.com/palladin/lean-linq)'s core, with Espal's own Postgres client. Changes go to lean-linq first. This note records the decision from the lean-linq trial in the [spikes and a baseline](../../ROADMAP.md#spikes-and-a-baseline) milestone, made in October 2026. The [trial's README](https://github.com/ChristianMurphy/espal/blob/explore/lean-linq/explorations/lean-linq/README.md) on the `explore/lean-linq` branch has the setup and every result.

## What Espal takes

- The query AST, with table variables that the interpreter supplies. Espal chose that representation for its own core, in the [database API note](database-api.md).
- The SQL compiler for the four dialects, through `toSqlChecked`.
- The evaluator, which follows SQL's three-valued logic. Differential tests compare each database with it.
- The graded program type behind `Db`, for statement budgets. Espal [imports it](#what-espal-uses-today) and puts its own `@[budget]` attribute on top, in place of `db!` blocks.
- The parser that turns text results into typed values.

Espal's libpq client, in pipeline mode, runs the compiled SQL. The drivers that ship with lean-linq stay off the request path. Its Postgres driver blocks the calling thread, sends one statement per round trip and reads every row before returning. The SQLite, MySQL and SQL Server drivers get a fresh look when those databases arrive after 0.1.

## Why

- The trial passed on both Lean versions Espal uses. All 1,620 golden SQL checks passed, and driver sweeps matched the evaluator on 395 queries each on SQLite, Postgres 16 and MySQL 8. Lean 4.36.0-rc1 needed a one-line change.
- The budgets close most of the gaps that the [statement budget](../../ROADMAP.md#statement-budget) lists. Bounds are upper bounds, `db!` gives `do` notation, and a query for each derived row fails to type-check. A query for each fetched row gets a price in table sizes that no fixed budget covers. So a handler that requires a fixed budget refuses it.
- Columns carry their nullability in their types, and `Query.run_gcard` bounds result sizes over the model.
- Moving the MySQL driver to MariaDB Connector/C took four changed lines and passed its sweep.
- Building the same parts ourselves would go against the [contributing guide](../../CONTRIBUTING.md), which prefers an existing library under a compatible license.

## What changed in lean-linq

Four things kept Espal from depending on lean-linq, and lean-linq took a change for each in November 2026:

- **The module system.** [#8](https://github.com/palladin/lean-linq/pull/8) made every source a module, so Espal's modules can import it. The grouped types keep their private constructors, and `Theorems.lean` alone sees the body of the core function its proofs unfold.
- **Warnings.** [#4](https://github.com/palladin/lean-linq/pull/4) cleared them, and lean-linq's CI now builds with `--wfail`.
- **The lakefile.** [#7](https://github.com/palladin/lean-linq/pull/7) gave each driver its own library. Lake loads lean-linq with no client library installed, and a program links only the drivers it imports.
- **Lean 4.36.** [#3](https://github.com/palladin/lean-linq/pull/3) replaced `String.data` with `String.toList`.

These would help, and Espal can add them on top if upstream prefers not to:

- Escape `%` and `_` when a value becomes a `LIKE` pattern.
- Check bind parameters against each database's limit, and send Postgres batch lookups as one array with `= ANY($1)`.
- Name the loop in the error for a query per row. Today it reads `failed to synthesize instance of type class HasBillF`.
- Make `scanParams` total, since the Postgres and MySQL drivers call it on every query.

## What Espal uses today

`espal-core` depends on lean-linq and imports `LeanLinq.Freer`, the graded program type. A linked program takes that module and `LeanLinq.Core.Grade` from lean-linq, and nothing else. For a few weeks in November 2026 Espal held a copy of those files, since a module couldn't import lean-linq yet.

Espal's `Eff` is that type with a few operations, which read the clock, draw a random number, log a line and send a statement. It fixes the type's specification index to the trivial one, so `Eff` is an ordinary monad and handlers use Lean's own `do` notation. The `@[budget]` attribute then proves a bound on the statements a handler sends, as a theorem about the program. The roadmap's [statement budget](../../ROADMAP.md#statement-budget) section describes it.

## What Espal adds

- Models declared with an attribute, which generate lean-linq schemas and tables.
- Tenant scopes and the proofs behind [tenant isolation](../../ROADMAP.md#tenant-isolation).
- The [injection](../../ROADMAP.md#no-sql-injection) theorem over lean-linq's compiler. We port it first, to learn what proofs cost on this representation.
- A count theorem for Espal's client, which lean-linq's theorems cover only for the evaluator.
- Pipelining for independent queries. The author of lean-linq plans a separate layer for them, so Espal coordinates with that plan before building its own.

## If upstream declines

Espal copies the core with its MIT notice, as the contributing guide allows, and keeps it current by hand. That happens if lean-linq stops following Lean releases, or declines a change the [query layer](../../ROADMAP.md#query-layer-models-and-postgres) needs.

## Risks

- One person maintains lean-linq.
- Nobody has measured what proofs cost on its representation yet, which is why the injection proof comes first.
- Its errors come from instance search and tactics, so Espal's custom messages have to wrap them.
