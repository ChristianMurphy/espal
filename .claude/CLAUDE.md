# Notes for AI-assisted work on Espal

Follow the code style in `CONTRIBUTING.md`. In short:

- One concept per module, with proofs beside the code they cover.
- No `sorry`, `partial`, `unsafe`, `panic!` or `!` indexing in library code. Errors are values.
- Structured parsers instead of regular expressions, with a round-trip proof when a printer exists.
- Hot paths get a reference definition, a fast version proved equal, and a benchmark, and they work over bytes rather than `String`.
- Run `lake build --wfail`, `lake test`, `lake lint`, `lean-fmt format --check` and `lean-fmt check` before committing. Run lean-fmt on files under `tests/` through `lake env` in `tests/`, since they compile against that package. Run `zizmor --persona pedantic .github/workflows` after changing a workflow, and pin actions to commit hashes.

Keep agent instructions in `.claude/`. Don't put them in `CONTRIBUTING.md` or other files written for people.

Reason about Espal's design from its goals in `README.md` and `ROADMAP.md`. Another project's conventions decide how to approach that project, and they don't decide what Espal needs.

## Proofs

- Try to prove a claim before you make it a premise. Time-box the attempt, and if it fails, record the obstacle beside the premise.
- Write a fuzzed property once, as a Bool predicate, and define the premise as `∀ x, p x = true`. The fuzz test then checks the premise's own definition.
- State a theorem about the function the code calls. If the code and the theorem each spell out the same step, move that step into one function and name it in the theorem.
- Give each premise only the condition its own reason needs. Test the guard's edge cases to find the weakest condition that holds.
- Check each docstring claim against the definition, such as which limits a function checks.
- Show that each fuzzed property can fail. Break its guard on purpose and confirm that the test finds a counterexample.
- When a proof needs a general lemma that a library lacks, write it in the form that library would take, and offer it upstream.
- Leave a `simp` that closes its goal unsqueezed, so it adapts when the simp set changes. Squeeze a `simp` that leaves a goal open into `simp only [...]`, or restructure the step with `simpa` or `suffices`.
- Use `decide +kernel` for finite checks. Keep `native_decide`, `decide +native` and `bv_decide` out of any proof Espal cites, since they trust the compiler and add an axiom.
- Bind every variable in a statement explicitly, so a misspelled name fails instead of becoming a new variable. Espal and its tests build with `autoImplicit` off, which enforces this, and other projects may not.
- Register a fast path with `@[csimp]` and a proof that it equals the reference. Lean never checks `@[implemented_by]` code against the definition it replaces.
- Pin the statement and the axioms of each headline theorem in `tests/EspalTests/Statements.lean`, with `#guard_msgs` on `#check` and `#print axioms`. A changed statement or a new axiom then fails the build.

## Proofs written by an agent

- Agree on a theorem's statement with the person before proving it. To make a proof go through, don't change a statement, a premise, a definition the statement uses, or an axiom. Stop and ask instead.
- Never finish a proof with `sorry`, an `axiom`, a `local notation` or `local infix` that changes what the statement says, `@[implemented_by]` or `@[extern]`.
- Before committing, compare the final statement with the agreed one, and check that `#print axioms` lists only `propext`, `Classical.choice` and `Quot.sound`.
- Shorten a working proof before committing it. Drop unused steps and hypotheses, and replace a long chain of rewrites with a lemma or a closing tactic.
- List new and changed statements in the commit message or pull request, so a reviewer reads them first.

## Writing

- Scan all text meant for people with Vale, using the AiTells and Voices styles, and with LanguageTool. That covers docs, design notes, commit messages, issues, pull requests and chat posts. Then reread it, since neither catches everything.
- Neither tool catches a figure of speech such as "pays for it twice". Say what happens instead, and run a humanize pass if your setup has one.
- Vale reads a sentence that ends in a version number, such as 4.36.0, as running into the next one. Rephrase to clear that length error.
- Use concrete verbs, and name the concrete fact, such as the error, the file or what breaks. Words such as "there" or "carry over" that stand in for a fact leave the reader guessing.
- Avoid stock phrases and inflated claims. State design goals as goals.
- Keep sentences under about 25 words. Write plain sentences rather than a colon before the point.
- State the claim directly. Skip contrasts that set it against something weaker, such as "X, not only Y" or "X rather than just Y".
- Check each claim before you write it, and say which checks ran and passed.
- Offer only what you've checked or tried. Don't promise work you haven't attempted, such as a proof.
- Keep it short. Give the reader what they need to decide, and put the rest behind a link, such as a results page.
- When comparing options, say how each one works and when it wins before giving numbers. A table alone leaves the reader to work out the trade-off.
- Refer to milestones and properties by name, with a link, rather than by a code such as M1.

## Working with the person

- When they ask to discuss something, answer in chat with the options and trade-offs before changing any file.
- When a word in a request could mean two things, say which reading you took.
- The Espal repository is public. Keep an unfixed security finding, in Espal or any other project, out of its files, branches, commit messages, issues and comments. Report it in chat and through the affected project's private channel.

## Skills

- `writing-to-other-projects` covers issues, pull requests and posts for projects other than Espal.
- `c-libraries` covers Lean dependencies, C bindings and linking.
- `benchmarks` covers running benchmarks and reporting their results.
- `fuzzing` covers property tests, fuzz tests and differential tests beside proofs.

## Commits

- Make each change on a new branch, and open a pull request into the branch it targets, such as `main` or an `explore/` branch. Never push to the target branch directly.
- Author and sign off commits as the person you're working for (`git commit -s`).
- Do not add `Co-Authored-By` lines for Claude or session links to commits.
- Do not sign issues, pull requests or comments with a "Generated by Claude Code" footer or any other attribution.
- The GitHub tools in cloud sessions append that footer when they create a comment or issue. Edit the post right after creating it to remove the footer, then read it back.
