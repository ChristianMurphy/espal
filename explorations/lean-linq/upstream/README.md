# Changes offered to lean-linq

Each change goes to lean-linq on its own, with its own reason.

1. **Use `String.toList`** (pull request, opened). Lean 4.35.0 deprecates `String.data`, and 4.36.0-rc1 removes it, so lean-linq fails to compile on 4.36.0-rc1.
2. **Clear build warnings** (pull request, opened). The library logs 33 more warnings on Lean 4.35.0. A project that builds with `--wfail` fails once it adds lean-linq.
3. **Load the package without every client library** (issue, opened from `0003-issue-client-libraries.md`). The lakefile looks up all four client libraries when Lake loads it and stops if one is missing. So a project that uses one database installs all four. Its link arguments also stay inside its own package, so a dependent's executable has to link libpq itself. `experiment-driver-libraries.patch` gives each driver its own library that carries its client library through `moreLinkObjs`, which fixes both on Linux for libpq.
4. **Lean's module system** (issue, `0004-issue-module-system.md`). A file that starts with `module` can't import lean-linq. `experiment-module-system.patch` builds every module up to `Theorems.lean`, whose proofs unfold `List.filterAuxM`, a core function modules can't see into.

Each patch applies on commit `463e34a` and has a matching description file. On Lean 4.35.0, `lake test` and the SQLite, Postgres and MySQL driver sweeps passed with each patch. On 4.36.0-rc1 they passed with the first patch alone and with both, and both together build there with no warnings.

To open a pull request from a fork:

```bash
git am upstream/0001-Use-String.toList-in-isReservedParamName.patch
```
