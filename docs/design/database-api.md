# Database API exploration

This note compares three ways for apps to talk to a database. They are a query builder, models with relations, and query syntax embedded in Lean, which comes in two flavors. To compare them on evidence, we built a small prototype of each on the `explore/database-api` branch. It comes to about 1,040 lines of Lean, not counting demos and tests. The prototype is scratch code and doesn't follow the style rules in `CONTRIBUTING.md`.

## Summary

- The builder, the models and the keyword syntax build the same typed syntax tree, so one set of proofs covers all three. The builder and the keyword syntax produce identical SQL for the same query, and a compile-time check confirms it.
- The `do`-notation flavor needed a different tree, in which the interpreter supplies the type of table variables. That tree gives a real monad, so optional filters are plain `if` statements, and Lean rejects a table variable used outside its query. It also gives the most precise error positions. Compile time per query is about the same for every style.
- The SQL from each style ran on SQLite 3.45 and Postgres 16 and returned the same rows as the Lean evaluator, with one exception. Under an ICU English collation, Postgres sorts text differently from the evaluator.
- A renderer bug in the prototype produced a join that SQLite accepts and Postgres rejects. A test suite that ran only on SQLite would have shipped it.
- The statement budget works but is awkward to write. Lean's `do` notation needs a monad, and a budgeted program isn't one, so code chains `.bind` calls. The exact count also rejects an early return.
- Error messages are where the styles differ most. Misspelled columns get clear messages. Type mismatches and the N+1 rejection name internal type classes. Errors inside embedded syntax point at the start of the query instead of the bad clause.
- [lean-linq](https://github.com/palladin/lean-linq) (MIT) already offers a typed builder, comprehension syntax, budgets with `do` notation, and drivers for Postgres, SQLite, MySQL and SQL Server. [chrisflav/db](https://github.com/chrisflav/db) (Apache 2.0) offers models declared as plain structures, a query language in `do` notation, and migrations.

## One schema, three styles

An app declares the schema once. The `model` command generates a row type, typed column references, `find`, `all`, `insert`, and one function per relation.

```lean
model Student "students" where
  id : Int
  schoolId : Int
  name : String
  age : Int
  belongsTo school : School via schoolId

relations Student where
  hasMany submissions : Submission via studentId
```

### Builder

```lean
def topScores (a : Int) :=
  (selectFrom Submission)
    |>.join Student (fun s st => s.studentId ==. st.id)
    |>.filter (fun s _ => s.assessmentId ==. a &&. s.score >. 50)
    |>.orderBy (fun s _ => s.score) .desc
    |>.limit 10
    |>.select (fun s st => (s.id, st.name, s.score))
```

### Keyword syntax

```lean
open Dbapi.QuerySyntax in
def topScores (a : Int) := query
  from s in Submission
  join st in Student on s.studentId == st.id
  where s.assessmentId == a && s.score > 50
  order by s.score desc
  limit 10
  select (s.id, st.name, s.score)
```

### `do` notation

```lean
open Dbapi.Do in
def topScores (a : Int) := query% do
  let s ← from Submission
  let st ← from Student
  guard (s.studentId == st.id)
  guard (s.assessmentId == a && s.score > 50)
  orderBy s.score desc
  limit 10
  select (s.id, st.name, s.score)
```

The builder and the keyword syntax produce this SQL, shown here for Postgres and SQL Server:

```sql
SELECT t0.id, t1.name, t0.score FROM submissions t0 JOIN students t1 ON (t0.student_id = t1.id) WHERE ((t0.assessment_id = $1) AND ($2 < t0.score)) ORDER BY t0.score DESC LIMIT 10
SELECT TOP (10) t0.id, t1.name, t0.score FROM submissions t0 JOIN students t1 ON (t0.student_id = t1.id) WHERE ((t0.assessment_id = @p1) AND (@p2 < t0.score)) ORDER BY t0.score DESC
```

### Models and relations with a budget

```lean
/-- Two statements however many students the school has. -/
def schoolReport (school : Int) : DbM 2 (List (Student × List Submission)) :=
  (DbM.all ((selectFrom Student).filter (fun s => s.schoolId ==. school) |>.select fun s => s)).bind
    Student.withSubmissions
```

Running it against the in-memory database records the two statements it sends:

```sql
SELECT t0.id, t0.school_id, t0.name, t0.age FROM students t0 WHERE (t0.school_id = $1)
SELECT t0.id, t0.student_id, t0.assessment_id, t0.score FROM submissions t0 WHERE (t0.student_id IN ($1, $2))
```

Writing the same report with a query per student fails to compile.

## Builder

The builder took 262 lines on top of a 310-line core, and each query adds about 9 ms of compile time. All compile times in this note are medians of five runs. Each is the extra time a file of 200 queries or 20 models takes over its imports alone.

Lean's `==` returns `Bool` and `<` returns a proposition, so neither can build SQL. The builder uses `==.`, `>.` and `&&.` instead, which read worse than SQL and worse than the embedded syntax.

A lambda needs one binder per table, so the prototype has a separate query type for one, two and three tables. Each clause method exists three times, and a fourth table needs another copy. lean-linq avoids the copies by naming columns with strings (`c["Age"]`) that instance search checks.

A misspelled column gets a clear message:

```
Invalid field `agee`: The environment does not contain `Demo.Student.Of.agee`
```

Comparing an integer column with a text column gets a message that names an internal class:

```
failed to synthesize instance of type class
  IntoExpr (Ctx2 Submission.Of Student.Of) SqlTy.int (Expr (Ctx2 Submission.Of Student.Of) SqlTy.text)
```

## Models and relations

The `model` and `relations` commands took 116 lines. Each six-column model adds about 145 ms of compile time, so 100 models would add about 15 seconds to a clean build.

A batch preload such as `Student.withSubmissions` loads every student's submissions in one statement, and the budget type counts it as one.

The prototype found these problems:

- **Declaration order.** A relation's target must already exist. A school that has many students, where each student belongs to a school, needs the separate `relations` block.
- **Keywords as column names.** A column named `at` fails with "unexpected token 'at'", because `at` is a Lean keyword. Models need a field name that can differ from the column name.
- **Column types.** The prototype supports `Int`, `String` and `Bool` and rejects the rest ("column type must be Int, String or Bool"). Real apps need nullable columns, decimals, timestamps, UUIDs, JSON and enumerations. Each type needs a mapping per database and a meaning in the evaluator.
- **Batch size.** The preload sends one parameter per key. SQL Server allows 2,100 parameters per statement, SQLite 32,766 and Postgres 65,535, so a large preload fails at runtime. Postgres can take one array parameter with `= ANY($1)`; the other databases need their own forms.
- **Budget ergonomics.** Without `do` notation, code chains `.bind`. A query per student fails with `failed to synthesize instance of type class Monad (DbM 1)`, which is correct but doesn't mention N+1. An early return fails because the two branches send different numbers of statements:

```
Type mismatch
  DbM.pure none
has type
  DbM 0 (Option ?m.12)
but is expected to have type
  DbM 1 (Option School)
```

chrisflav/db shows another way to declare models: an attribute on an ordinary structure (`@[model] structure Author where …`), which needs no custom command. lean-linq's `db!` syntax restores `do` notation for budgeted programs, and it prices a loop by the size of the rows it iterates.

## Keyword syntax

The keyword syntax took 69 lines because it expands to builder calls and adds no meaning of its own. Each query adds about 10 ms of compile time.

Inside clauses, `==`, `&&`, `>` and `∈` work as written, so queries read close to SQL.

The keywords `query`, `join`, `on`, `order`, `limit`, `select` and `desc` exist only in files that open `Dbapi.QuerySyntax`. Elsewhere, `def select := 1` still compiles.

The prototype found these problems:

- **Soft keywords leak into terms.** The first version treated `desc` as a soft keyword, and `order by s.score desc` parsed `desc` as an argument to `s.score`. Every clause keyword has to be a full keyword inside the scope.
- **Error positions.** A type mismatch in `on s.score == st.name` and a misspelled column in `where s.agee > 12` both point at the `query` keyword, not at the bad clause. Fixing that means carrying source positions through the macro.
- **Grammar grows with SQL.** Aggregates, `GROUP BY`, subqueries and outer joins each need new grammar as well as builder support.
- **Shared tree, shared limits.** Because it expands to the builder, it inherits the limit of three tables.

## `do` notation

The `do` flavor took 238 lines, most of them for its own tree, evaluator and renderer. Each query adds about 12 ms of compile time. chrisflav/db uses the same flavor for its `query%` syntax.

A query here is a program in a monad, written once for every type of table variable. The interpreter chooses that type: rows when it evaluates the query, alias numbers when it writes SQL. That choice of representation has three effects:

- **Optional filters are plain Lean.** A search with optional criteria needs no special API, and each call builds a different statement:

```lean
def search (school : Option Int) (minAge : Option Int) := query% do
  let s ← from Student
  if let some sc := school then guard (s.schoolId == sc)
  if let some m := minAge then guard (s.age >= m)
  orderBy s.name
  select (s.name, s.age)
```

```sql
SELECT t0.name, t0.age FROM students t0 ORDER BY t0.name
SELECT t0.name, t0.age FROM students t0 WHERE (t0.school_id = $1) AND ($2 <= t0.age) ORDER BY t0.name
```

- **Table variables can't escape.** A table variable from outside the query fails to type-check, because the query must work for every type of variable. A monad that numbered tables by position would accept the stray variable and bind it to whichever table had that number.
- **No limit on tables.** Each `from` adds a table, with no separate query type for each count.

Errors point closer to the mistake than in the keyword flavor. A misspelled column points at `s.agee` itself, and a type mismatch points at its `guard` line.

The costs:

- **A second tree.** This tree sits beside the one the other styles share, so we would have to restate the injection and tenant proofs for it. Using this representation for every style instead would remove the duplication, but we haven't ported the builder and models to it.
- **Joins become filters.** The join condition is an ordinary `guard`, so the SQL reads `CROSS JOIN … WHERE` instead of `JOIN … ON`. The results match on both databases, but outer joins would need their own operation.
- **Two meanings for `==`.** Inside `guard` and `orderBy`, `==` and `>` build SQL. In the surrounding `if`, they compare Lean values. The macro rewrites only those arguments, but a reader has to know where the boundary is.
- **Same internal names in errors.** A type mismatch reports `failed to synthesize instance of type class IntoP var✝ SqlTy.int (PExpr var✝ SqlTy.text)`, and the stray variable reports a similar message.

## Findings for every style

### Differential test

The prototype generated `CREATE TABLE` statements from the models, loaded the same rows into SQLite and Postgres, and ran 13 queries through each.

| Query | SQLite 3.45 | Postgres 16, C collation | Postgres 16, ICU en-US |
|---|---|---|---|
| One table, builder, keyword and `do` | match | match | match |
| Two tables, builder, keyword and `do` | match | match | match |
| Three tables, keyword and `do` | match | match | match |
| Order by name | match | match | **differs** |
| Search without filters, ordered by name (`do`) | match | match | **differs** |
| Search with both filters (`do`) | match | match | match |
| Exact text match | match | match | match |
| `IN` list | match | match | match |

The evaluator orders names by code point (`Alan`, `Zoe`, `adam`, `Émile`); the ICU collation orders them by language rules (`adam`, `Alan`, `Émile`, `Zoe`). The default collations of MySQL, MariaDB and SQL Server are case-insensitive, so an exact match on `ada` would also find `Ada` there. We didn't test those three databases.

### A bug only Postgres caught

The first renderer produced `FROM submissions t0 JOIN students t1 JOIN schools t2 ON … AND …`. SQLite accepts that statement and returns rows. Postgres rejects it with "syntax error at end of input". The evaluator never parses SQL, so it can't catch renderer bugs; only the real databases can.

### Other databases

| Database | Client library | License and notes |
|---|---|---|
| Postgres | libpq | PostgreSQL License (permissive) |
| SQLite | libsqlite3, or [leansqlite](https://github.com/leanprover/leansqlite) | Public domain. The Lean FRO maintains leansqlite under Apache 2.0, and it bundles SQLite. |
| MySQL | libmysqlclient | GPLv2 with the Universal FOSS Exception. Open-source apps may link it; closed-source apps that link it fall under the GPL. |
| MySQL, MariaDB | MariaDB Connector/C | LGPL 2.1, and works with MySQL and MariaDB servers. Has a non-blocking API. We haven't confirmed that it supports MySQL 8's default authentication. |
| SQL Server | FreeTDS | LGPL |
| SQL Server | Microsoft ODBC Driver 18 | Proprietary, with redistribution limits |
| SQL Server | Our own client | Microsoft publishes the TDS protocol specification and covers it with its Open Specification Promise. |

Each database also departs from the evaluator in its own ways:

- MySQL, MariaDB and SQL Server compare text without regard to case by default.
- SQLite switches integer arithmetic to floating point on overflow.
- MySQL outside strict mode, and SQL Server with `ANSI_WARNINGS OFF`, truncate or clip bad values instead of failing.
- Only Postgres and SQL Server have row-level security, so the second layer of tenant isolation exists only there.
- MySQL has no `RETURNING`. MariaDB has it for some statements. SQL Server uses `OUTPUT`, and refuses it on tables with triggers unless the output goes into a table.
- SQL Server's `sp_executesql` accepts a whole batch, so one parameterized text can hold several statements.

These differences call for a portable core plus dialect features that the type checker gates. A query that uses `RETURNING` shouldn't compile for MySQL, and the differential tests have to run against every supported database.

## Prior art in Lean

- **lean-linq** (MIT, active). It has a typed builder and `query!` syntax that produce identical SQL, nullability in column types, left joins, and separate trees for grouped queries. Its `db!` budgets use `do` notation and price loops by table size. It ships native drivers for all four engines and runs 405 test cases on each. Its MySQL driver links libmysqlclient, which carries the GPL terms above.
- **chrisflav/db** (Apache 2.0, active). `@[model]` on plain structures, `query%` in `do` notation, `autoUpdate` migrations, SQLite through leansqlite, Postgres through libpq.
- **leansqlite** (Apache 2.0, Lean FRO). A maintained SQLite binding.
- **lean-postgres** (Apache 2.0). Postgres syntax and type rules embedded in Lean.

Espal now prefers to depend on existing libraries. So the [spikes milestone](../../ROADMAP.md#spikes-and-a-baseline) tried lean-linq as the query layer, and Espal [builds on its core](lean-linq.md). lean-linq already solves several problems the prototype hit. It has `do` notation for budgets, it tracks which columns can be null, and it tests its SQL on real databases.

## Decisions so far

- Build models and the builder first, and add embedded syntax after them.
- Declare models with an attribute on an ordinary structure, as chrisflav/db does, instead of a custom command.
- Use query syntax in `do` notation, on a core whose table variables the interpreter supplies.
- Build the query layer on lean-linq's core, sending changes upstream first, as the [lean-linq note](lean-linq.md) records.
- Reach MySQL and MariaDB through MariaDB Connector/C and SQL Server through FreeTDS. Both are LGPL, and Espal links them as shared libraries.

## Recommendation

1. Build the core on the representation from the `do` prototype, where the interpreter supplies the type of table variables. That core comes from [lean-linq](lean-linq.md). Port the builder and models to it. That removes the three-table limit and the second tree, and it keeps table variables inside their query. Port the injection proof first, to find out early what the proofs cost on this representation.
2. Make `do` notation the embedded syntax, for its error positions and its plain `if` for optional filters. Keep the keyword flavor as a possible later layer on the same core.
3. Give statement budgets `do` notation and upper bounds before 0.1. The prototype showed that chained `.bind` and exact counts both get in the way.
4. Write custom error messages for type mismatches, stray table variables and N+1 loops, with a `#guard_msgs` test for each.
5. Test each renderer against its real database in CI, since the evaluator can't catch rendering bugs.
6. Add databases in this order: Postgres, SQLite, MySQL and MariaDB, then SQL Server.
