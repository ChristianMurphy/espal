# Database API prototype

Scratch code for the [database API design note](../../docs/design/database-api.md) on the main branch. It compares a query builder, models with relations, and embedded query syntax over one typed SQL tree. It doesn't follow the rules in `CONTRIBUTING.md`, and nothing in the library depends on it.

| File | Contents |
|---|---|
| `Dbapi/Core.lean` | Typed expressions, select statements, the reference evaluator, the in-memory database, and SQL rendering for Postgres, SQLite, MySQL and SQL Server |
| `Dbapi/Builder.lean` | The `Model` class, the builder for one to three tables, and the `DbM` statement budget |
| `Dbapi/Models.lean` | The `model` and `relations` commands |
| `Dbapi/Embedded.lean` | The `query … from … select` syntax |
| `Dbapi/Schema.lean` | The example schema and seed rows |
| `Dbapi/Demo.lean` | The same queries in each style, with results and SQL |
| `Rejected.lean` | Mistakes each style must reject, with the errors they produce |
| `Dbapi/Bench*.lean` | 50 builder queries, 50 embedded queries and 20 models, for compile timing |
| `Export.lean`, `difftest.py` | The differential test against SQLite and Postgres |

## Running it

```bash
lake build                                # builds the demo and the timing files
lake env lean Dbapi/Demo.lean             # prints results and SQL
lake env lean Rejected.lean               # prints the expected errors
lake env lean Export.lean                 # writes difftest.json
python3 difftest.py difftest.json <dir>   # <dir> holds a Postgres socket on port 5499
```

`difftest.py` expects two databases, `espal_c` with the C collation and `espal_icu` with ICU `en-US`, and runs the same rows through Python's SQLite module.
