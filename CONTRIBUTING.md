# Contributing to Espal

We write Espal from scratch. Other frameworks shape its design, and we copy or translate none of their code.

- Read other projects to learn from them. Do not copy or port their code.
- When a design draws on another project, name that project in the pull request.
- Sign off each commit (`git commit -s`) to certify that the work is your own, under the [Developer Certificate of Origin](https://developercertificate.org/).

## Before a pull request

```bash
lake build
lake test
```

Start each new module with a copyright header and a module docstring. Give each public definition a docstring. Name theorems by the Mathlib naming rules.

When you contribute, you release your work under the Apache 2.0 license.
