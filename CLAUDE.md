# Notes for AI-assisted work on Espal

Follow the code style in `CONTRIBUTING.md`. In short:

- One concept per module, with proofs beside the code they cover.
- No `sorry`, `partial`, `unsafe`, `panic!` or `!` indexing in library code. Errors are values.
- Structured parsers instead of regular expressions, with a round-trip proof when a printer exists.
- Hot paths get a reference definition, a fast version proved equal, and a benchmark, and they work over bytes rather than `String`.
- Run `lake build --wfail`, `lake test`, `lake env lean --run scripts/Lint.lean`, `lean-fmt format --check` and `lean-fmt check` before committing.

## Writing

- Prose in docs and design notes passes Vale with the AiTells and Voices styles.
- Use concrete verbs. Avoid stock phrases and inflated claims. State design goals as goals.

## Commits

- Author and sign off commits as Christian Murphy <christian.murphy.42@gmail.com> (`git commit -s`).
- Do not add `Co-Authored-By` lines for Claude or session links to commits.
