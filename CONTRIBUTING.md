# Contributing to Espal

We write Espal from scratch. Other frameworks shape its design, and we copy or translate none of their code.

- Read other projects to learn from them. Do not copy or port their code.
- When a design draws on another project, name that project in the pull request.
- Sign off each commit (`git commit -s`) to certify that the work is your own, under the [Developer Certificate of Origin](https://developercertificate.org/).

## Before a pull request

```bash
lake build
lake test
lean-fmt format $(git ls-files '*.lean')
```

Espal follows the layout of [lean-fmt](https://github.com/jcreinhold/lean-fmt). Build the release whose tag matches `lean-toolchain`, then run it as shown. CI rejects files it would change. `lake-manifest.json` keeps the layout Lake writes, so leave it to Lake.

Start each new module with a copyright header and a module docstring. Give each public definition a docstring. Name theorems by the Mathlib naming rules.

When you contribute, you release your work under the Apache 2.0 license.
