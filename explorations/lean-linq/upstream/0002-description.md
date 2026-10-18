On Lean 4.35.0, lean-linq logs 33 warnings besides the `String.data` deprecation. `lake build --wfail` counts warnings in dependencies too, so a project that builds with it fails once it adds lean-linq. Lean also drops deprecated names in later releases, as it did with `String.data` in 4.36.

This change:

- replaces the deprecated `if_pos` and `if_neg` with `ite_eq_left` and `ite_eq_right`, as Lean suggests;
- drops the `simp` arguments the linter reports as unused;
- replaces two unused variables with `_` and renames `h` in `valueNull` and `setNull` to `_h`;
- turns off the unused-variables linter for the mutual block in `Core/Expr.lean` and for `DbOp`. Their `inst` binders look unused, but patterns match them by name, such as `.insert (inst := _) i`, so renaming them would break those patterns.

If you'd rather keep the linter on for those two declarations, I can drop that part.

On 4.35.0, `lake test` and the SQLite, Postgres and MySQL driver sweeps pass with this change. On 4.36.0-rc1, together with the `String.toList` fix, the build has no warnings and the same tests pass.
