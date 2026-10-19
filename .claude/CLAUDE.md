# Notes for AI-assisted work on Espal

Follow the code style in `CONTRIBUTING.md`. In short:

- One concept per module, with proofs beside the code they cover.
- No `sorry`, `partial`, `unsafe`, `panic!` or `!` indexing in library code. Errors are values.
- Structured parsers instead of regular expressions, with a round-trip proof when a printer exists.
- Hot paths get a reference definition, a fast version proved equal, and a benchmark, and they work over bytes rather than `String`.
- Run `lake build --wfail`, `lake test`, `lake lint`, `lean-fmt format --check` and `lean-fmt check` before committing. Run `zizmor --persona pedantic .github/workflows` after changing a workflow, and pin actions to commit hashes.

Keep agent instructions in `.claude/`. Don't put them in `CONTRIBUTING.md` or other files written for people.

## Writing

- Scan all text meant for people with Vale, using the AiTells and Voices styles, and with LanguageTool. That covers docs, design notes, commit messages, issues, pull requests and chat posts. Then reread it, since neither catches everything.
- Use concrete verbs, and name the concrete fact, such as the error, the file or what breaks. Words such as "there" or "carry over" that stand in for a fact leave the reader guessing.
- Avoid stock phrases and inflated claims. State design goals as goals.
- Keep sentences under about 25 words. Write plain sentences rather than a colon before the point.
- Check each claim before you write it, and say which checks ran and passed.
- Refer to milestones and properties by name, with a link, rather than by a code such as M1.

## Skills

- `writing-to-other-projects` covers issues, pull requests and posts for projects other than Espal.
- `c-libraries` covers Lean dependencies, C bindings and linking.

## Commits

- Author and sign off commits as the person you're working for (`git commit -s`).
- Do not add `Co-Authored-By` lines for Claude or session links to commits.
