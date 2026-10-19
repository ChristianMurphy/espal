# Notes for AI-assisted work on Espal

Follow the code style in `CONTRIBUTING.md`. In short:

- One concept per module, with proofs beside the code they cover.
- No `sorry`, `partial`, `unsafe`, `panic!` or `!` indexing in library code. Errors are values.
- Structured parsers instead of regular expressions, with a round-trip proof when a printer exists.
- Hot paths get a reference definition, a fast version proved equal, and a benchmark, and they work over bytes rather than `String`.
- Run `lake build --wfail`, `lake test`, `lake lint`, `lean-fmt format --check` and `lean-fmt check` before committing. Run `zizmor --persona pedantic .github/workflows` after changing a workflow, and pin actions to commit hashes.

## Writing

- Prose in docs and design notes passes Vale with the AiTells and Voices styles, and LanguageTool. Vale misses some tells, so reread for them as well.
- Use concrete verbs. Avoid stock phrases and inflated claims. State design goals as goals.
- Name the concrete fact, such as the error, the file or what breaks. Vague stand-ins such as "there", "here", "carry over" or "take changes" read as machine-written.
- Keep sentences under about 25 words, and write plain sentences rather than colon reveals.
- Check each claim before writing it, and say which checks ran and passed.
- Refer to milestones and properties by name, with a link, rather than by a code such as M1 or P8.

## Writing to other projects

- Lead with what the project and its users gain, not with Espal.
- It's their project. Present options with their trade-offs and ask questions. Avoid verdicts such as "we tried" or "ruled out", and ask whether a change would be a good fit rather than what they want.
- Send one change per pull request or issue, each with its own reason, and the small ones first.
- Offer help in concrete terms, such as opening the pull request and seeing it through review.
- Leave out what the reader doesn't need, such as test results in an issue or links to our notes. Mention a prototype only when it supports an option.
- As a newcomer, ask before proposing. Lean's RFC template wants a Zulip thread first. Keep first posts short and skip @-mentions.
- Write as "I", the person filing.
- Give chat posts in a code block, checked against the platform's syntax, and issues and pull requests as prefilled links.

## Lean

Read `docs/lean-notes.md` before Lake, FFI, toolchain or module-system work. Add to it when something surprises you.

## Commits

- Author and sign off commits as Christian Murphy <christian.murphy.42@gmail.com> (`git commit -s`).
- Do not add `Co-Authored-By` lines for Claude or session links to commits.
