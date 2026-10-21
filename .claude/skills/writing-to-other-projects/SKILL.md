---
name: writing-to-other-projects
description: Draft issues, pull requests and forum posts for projects other than Espal, such as Lean or a dependency. Use when proposing a change upstream or asking another project a question.
---

# Writing to other projects

## Content

- Lead with what the project and its users gain.
- It's their project. Present options with their trade-offs, and ask whether a change would be a good fit. Avoid verdicts such as "we ruled out".
- You can lead with the option you'd pick. Say in a line when each other option would suit them better.
- Send one change per pull request or issue, each with its own reason, and the small ones first.
- Offer help in concrete terms, such as opening the pull request and seeing it through review.
- Leave out what the reader doesn't need to decide. Keep to the problem, the proposal and the alternatives, with one small table at most, and link the full results. Mention a prototype only when it supports an option.
- A short example or a link to the docs often explains more than another paragraph.
- Split a pull request longer than a few paragraphs into short sections, such as how it works, guarantees, performance and notes. Keep each bullet to one or two sentences.
- Where you're new, ask before proposing. Keep a first post short, and skip @-mentions.

## Before drafting

- Read the project's contributing guide and any AI policy, and follow the order of steps it asks for. Lean core wants an issue before any pull request. For Lean core, open that issue directly rather than a Zulip thread first.
- If a project asks contributors to disclose AI help, quote its policy to the person and ask how to handle it, every time. Lean core asks for a note in each pull request, and Mathlib asks you to explain which tools you used and how.
- The leanprover-community projects, such as Mathlib and Batteries, and the Lean Zulip don't allow comments written with an LLM, and they delete them. For those, give the person the points to make, and let them write the text.

## Handing it over

- The person you're working for sends it. Write in the first person singular, as that person.
- Give a chat post in a code block, checked against the platform's syntax. A Zulip topic holds 60 characters.
- Give an issue or pull request as a link with the title and body filled in.
