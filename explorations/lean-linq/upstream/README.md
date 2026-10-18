# Changes offered to lean-linq

Each change goes to lean-linq on its own, with its own reason. The two pull requests come first, and the two issues wait until the author has responded to them.

1. **Use `String.toList`** (pull request, ready). Lean 4.35.0 deprecates `String.data` and 4.36.0-rc1 removes it, so lean-linq stops building there.
2. **Clear build warnings** (pull request, ready). The library logs 33 more warnings on Lean 4.35.0. A project that builds with `--wfail` can't depend on it while they're there.
3. **Load the package without every client library** (issue, later). The lakefile looks up all four client libraries when Lake loads it and stops if one is missing. So a project that uses one database installs all four. Its link arguments also stay inside its own package, so a dependent's executable has to link libpq itself.
4. **Lean's module system** (issue, later). A file that starts with `module` can't import lean-linq. Moving it over needs its author's decisions on what to expose. Examples are the private constructors in `Core/Grouped.lean` and the proofs in `Theorems.lean` that unfold `List.filterAuxM`.

Each patch applies on commit `463e34a` and has a matching description file. On Lean 4.35.0, `lake test` and the SQLite, Postgres and MySQL driver sweeps passed with each patch. On 4.36.0-rc1 they passed with the first patch alone and with both, and both together build there with no warnings.

To open a pull request from a fork:

```bash
git am upstream/0001-Use-String.toList-in-isReservedParamName.patch
```
