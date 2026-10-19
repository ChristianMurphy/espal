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
lean-fmt format $(git ls-files '*.lean')
lean-fmt check $(git ls-files '*.lean')
```

`--wfail` turns warnings into errors, so a `sorry` or a missing docstring fails the build. `lake lint` runs `scripts/Lint.lean`, which reads the compiled declarations and rejects `unsafe` and `partial` code, calls to `panic!` or to any function whose name ends in `!`, and axioms beyond `propext`, `Classical.choice` and `Quot.sound`.

CI also re-checks every declaration with Lean's kernel checker and audits axioms with lean-action. If you change a workflow, run `zizmor --persona pedantic .github/workflows`; CI runs it too, and actions stay pinned to commit hashes.

Espal follows the layout of [lean-fmt](https://github.com/jcreinhold/lean-fmt). Build the release whose tag matches `lean-toolchain`, then run it as shown. CI rejects files it would change. `lake-manifest.json` keeps the layout Lake writes, so leave it to Lake.

## Code style

### Structure

- Give each module one concept, such as `Espal/Route.lean` or `Espal/Route/Codec.lean`.
- Keep a definition and its theorems in the same file, so a change and its proof break together.
- Mark only the API `public`, and keep helpers private to their module. A few entry modules, such as `Espal`, re-export the API.

### Correctness

- Library code never uses `sorry`. CI also checks the axioms behind the headline theorems with `#print axioms`.
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

- Keep a few concrete examples for readers.
- Add a `#guard_msgs` test for each mistake the API must reject.
- When a message holds metavariable numbers, match part of it with `#guard_msgs (substring := true)`.
- Skip tests that only repeat a theorem.

## Dependencies and C libraries

- A Lean dependency has to build under `lake build --wfail`, which counts its warnings too. It also has to use Lean's module system, because Espal's modules can import only modules.
- When porting a dependency to the module system, the `backward.privateInPublic` option keeps private helpers private. Elaborators and macros, and the helpers they call, need `meta`.
- Link a C library by its file path. Lean links with its own linker and glibc, and adding the system library directory with `-L` pulls in the system glibc. Some system libraries also need `-Wl,--allow-shlib-undefined`.
- Name a C library in `moreLinkObjs` on the `lean_lib` that uses it. Lake passes those to every program that imports the library, while `moreLinkArgs` reach only the package's own programs.
- Look up system libraries inside a `target`. Top-level code in a lakefile runs whenever Lake loads the package, including as someone else's dependency.
- A dedicated task that blocks in C keeps the process alive after `main` returns, so a program that starts one ends with `IO.Process.exit`.

## Writing

Docs, design notes, issues and pull requests follow the same rules.

- Check prose with Vale, using the AiTells and Voices styles, and with LanguageTool. Then reread it, since neither catches everything.
- Use concrete verbs, and name the concrete fact, such as the error, the file or what breaks. Words such as "there" or "carry over" that stand in for a fact leave the reader guessing.
- Avoid stock phrases and inflated claims. State design goals as goals.
- Keep sentences under about 25 words. Write plain sentences rather than a colon before the point.
- Check each claim before you write it, and say which checks ran and passed.
- Refer to milestones and properties by name, with a link, rather than by a code such as M1.

## Working with other projects

- Lead with what the project and its users gain.
- It's their project. Present options with their trade-offs, and ask whether a change would be a good fit. Avoid verdicts such as "we ruled out".
- Send one change per pull request or issue, each with its own reason, and the small ones first.
- Offer help in concrete terms, such as opening the pull request and seeing it through review.
- Leave out what the reader doesn't need. Mention a prototype only when it supports an option.
- Where you're new, ask before proposing. Lean's RFC template asks for a Zulip thread first. Keep a first post short, and skip @-mentions.

When you contribute, you release your work under the Apache 2.0 license.
