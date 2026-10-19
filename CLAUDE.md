# Notes for AI-assisted work on Espal

Follow the code style in `CONTRIBUTING.md`. In short:

- One concept per module, with proofs beside the code they cover.
- No `sorry`, `partial`, `unsafe`, `panic!` or `!` indexing in library code. Errors are values.
- Structured parsers instead of regular expressions, with a round-trip proof when a printer exists.
- Hot paths get a reference definition, a fast version proved equal, and a benchmark, and they work over bytes rather than `String`.
- Run `lake build --wfail`, `lake test`, `lake lint`, `lean-fmt format --check` and `lean-fmt check` before committing. Run `zizmor --persona pedantic .github/workflows` after changing a workflow, and pin actions to commit hashes.

## Writing

- Check prose with Vale, using the AiTells and Voices styles, and with LanguageTool. Then reread it, since neither catches everything.
- Use concrete verbs, and name the concrete fact, such as the error, the file or what breaks. Words such as "there" or "carry over" that stand in for a fact leave the reader guessing.
- Avoid stock phrases and inflated claims. State design goals as goals.
- Keep sentences under about 25 words. Write plain sentences rather than a colon before the point.
- Check each claim before you write it, and say which checks ran and passed.
- Refer to milestones and properties by name, with a link, rather than by a code such as M1.

## Writing to other projects

- Lead with what the project and its users gain.
- It's their project. Present options with their trade-offs, and ask whether a change would be a good fit. Avoid verdicts such as "we ruled out".
- Send one change per pull request or issue, each with its own reason, and the small ones first.
- Offer help in concrete terms, such as opening the pull request and seeing it through review.
- Leave out what the reader doesn't need. Mention a prototype only when it supports an option.
- Where you're new, ask before proposing. Lean's RFC template asks for a Zulip thread first. Keep a first post short, and skip @-mentions.

## Drafting for a person

- Run Vale and LanguageTool on every draft before showing it.
- Give a chat post in a code block, checked against the platform's syntax, and an issue or pull request as a prefilled link. The person you're working for sends it.
- Write in the first person singular, as that person.

## Dependencies and C libraries

- A Lean dependency has to build under `lake build --wfail`, which counts its warnings too. It also has to use Lean's module system, because Espal's modules can import only modules.
- When porting a dependency to the module system, the `backward.privateInPublic` option keeps private helpers private. Elaborators and macros, and the helpers they call, need `meta`.
- Link a C library by its file path. Lean links with its own linker and glibc, and adding the system library directory with `-L` pulls in the system glibc. Some system libraries also need `-Wl,--allow-shlib-undefined`.
- Name a C library in `moreLinkObjs` on the `lean_lib` that uses it. Lake passes those to every program that imports the library, while `moreLinkArgs` reach only the package's own programs.
- Look up system libraries inside a `target`. Top-level code in a lakefile runs whenever Lake loads the package, including as someone else's dependency.
- A dedicated task that blocks in C keeps the process alive after `main` returns, so a program that starts one ends with `IO.Process.exit`.
- When an error message holds metavariable numbers, match part of it with `#guard_msgs (substring := true)`.

## Commits

- Author and sign off commits as the person you're working for (`git commit -s`).
- Do not add `Co-Authored-By` lines for Claude or session links to commits.
