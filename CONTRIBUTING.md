# Contributing to Espal

Until the 0.1 release, Espal doesn't take outside pull requests. Issues and discussion are welcome, and outside pull requests open after the first release.

Send security bugs through the private form in [SECURITY.md](SECURITY.md), not a public issue.

Espal builds on other projects where they help, and replaces them where they hold it back.

- Prefer depending on an existing library with a license compatible with Apache 2.0 to writing the same thing again.
- You may adapt code from a project under a permissive license. Keep its copyright and license notice with the code, and name the project and its license in the pull request.
- Keep GPL and LGPL code out of the repository. Espal may link LGPL libraries as shared libraries.
- When a design draws on another project, name that project in the pull request.
- Sign off each commit (`git commit -s`) to certify where the work comes from, under the [Developer Certificate of Origin](https://developercertificate.org/).

## Before a pull request

```bash
lake build --wfail
lake test
lake lint
lean-fmt format $(git ls-files '*.lean' ':!:tests/')
lean-fmt check $(git ls-files '*.lean' ':!:tests/')
cd tests
lake env lean-fmt format $(git ls-files '*.lean')
lake env lean-fmt check $(git ls-files '*.lean')
```

`--wfail` turns warnings into errors, so a `sorry` or a missing docstring fails the build. `lake lint` runs `scripts/Lint.lean`, which reads the compiled declarations and rejects `unsafe` and `partial` code, calls to `panic!` or to any function whose name ends in `!`, and axioms beyond `propext`, `Classical.choice` and `Quot.sound`. It also rejects `@[implemented_by]` and `@[extern]`, since Lean never checks that code, unless `uncheckedAllowed` in `scripts/LintRules.lean` lists the declaration.

CI also re-checks every declaration with Lean's kernel checker and audits axioms with lean-action. If you change a workflow, run `zizmor --persona pedantic .github/workflows`; CI runs it too, and actions stay pinned to commit hashes.

Espal follows the layout of [lean-fmt](https://github.com/jcreinhold/lean-fmt). Build the release whose tag matches `lean-toolchain`, then run it as shown. CI rejects files it would change. `lake-manifest.json` keeps the layout Lake writes, so leave it to Lake.

## Code style

### Structure

- Give each module one concept, such as `Espal/Route.lean` or `Espal/Route/Codec.lean`.
- Keep a definition and its theorems in the same file, so a change and its proof break together.
- Mark only the API `public`, and keep helpers private to their module. A few entry modules, such as `Espal`, re-export the API.

### Correctness

- Library code never uses `sorry`. `lake lint` and lean-action's axiom audit check every declaration in Espal's modules. Each fails on any axiom beyond `propext`, `Classical.choice` and `Quot.sound`, which rules out `sorry` and `native_decide`. Both start from the `Espal` module, so import each new module from it.
- Library code avoids `partial def`, `unsafe`, `panic!` and `!` indexing. Prove totality, or encode the failure in the type.
- Return errors as values, with `Except` or a typed error union. Do not throw IO exceptions across the framework boundary.

### Parsing

- Write structured parsers over characters or bytes. Do not use regular expressions where a structured parser can do the job.
- When a format also has a printer, prove that parsing a printed value returns the same value.

### Performance

- For a hot path, write a simple reference definition for proofs and a fast implementation for running. Prove the two agree, for example with `@[csimp]`.
- Parse and render hot paths over bytes or slices. Do not build intermediate `String` or `List` values there.
- Give each hot path a benchmark. CI fails on a large regression.

### Naming and comments

- Follow the Mathlib naming rules. Types use `UpperCamelCase` and functions use `lowerCamelCase`. Theorems use `snake_case` named after their statement, such as `parseNatSeg_natSeg`.
- Start each module with a copyright header and a module docstring.
- Give each public definition and theorem a docstring that states what it guarantees.
- Add an inline comment only for a fact the code cannot show. Do not restate the code.

### Tests

- Put tests in the `tests/` package. It is a Lake package of its own, which keeps test-only dependencies such as Plausible out of the packages that require Espal. `lake test` at the root runs it.
- When a proof takes a claim on trust, such as a property of `Std.Http`, give that claim a property test. Break the test once on purpose to show it can fail.
- Keep a few concrete examples for readers.
- Add a `#guard_msgs` test for each mistake the API must reject.
- Skip tests that only repeat a theorem.

When you contribute, you release your work under the Apache 2.0 license.
