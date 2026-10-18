Lean 4.35.0 deprecates `String.data`, and 4.36.0-rc1 removes it. On 4.36.0-rc1, `LeanLinq/Core/Expr.lean` fails to compile because the environment no longer contains `String.data`. This switches its one use, in `isReservedParamName`, to `String.toList`, which works on both versions.

On 4.35.0 and 4.36.0-rc1, `lake test` and the SQLite, Postgres and MySQL driver sweeps pass with this change.
