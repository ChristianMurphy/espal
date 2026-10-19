# Notes for AI-assisted work on Espal

Follow [CONTRIBUTING.md](CONTRIBUTING.md), including its sections on writing, other projects, and C libraries. In short:

- One concept per module, with proofs beside the code they cover.
- No `sorry`, `partial`, `unsafe`, `panic!` or `!` indexing in library code. Errors are values.
- Structured parsers instead of regular expressions, with a round-trip proof when a printer exists.
- Hot paths get a reference definition, a fast version proved equal, and a benchmark, and they work over bytes rather than `String`.
- Run `lake build --wfail`, `lake test`, `lake lint`, `lean-fmt format --check` and `lean-fmt check` before committing. Run `zizmor --persona pedantic .github/workflows` after changing a workflow, and pin actions to commit hashes.

## Writing for someone else to send

- Run Vale and LanguageTool on every draft before showing it.
- Give a chat post in a code block, checked against the platform's syntax, and an issue or pull request as a prefilled link. The person you're working for sends it.
- Write in the first person singular, as that person.

## Commits

- Author and sign off commits as the person you're working for (`git commit -s`).
- Do not add `Co-Authored-By` lines for Claude or session links to commits.
