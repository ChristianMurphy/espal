# Security policy

## Reporting a vulnerability

To report a security hole, use [GitHub's private form](https://github.com/ChristianMurphy/espal/security/advisories/new). Don't post it in a public issue, discussion or pull request.

A report helps most when it includes:

- the affected package and version, or the commit
- steps or a small program that shows the problem
- what an attacker gains

We reply in the advisory, prepare the fix there, and publish the advisory with the release that fixes it. We credit the reporter unless they ask us not to.

## Supported versions

Espal has no release yet, so only the `main` branch gets fixes. From 0.1 on, fixes go to the latest release. Each release supports one Lean version, the one in its `lean-toolchain`.

## Scope

Espal's own code is in scope, including its C bindings and the code it generates. A flaw in a dependency, such as Lean, libpq or another Lake package, belongs with that project. Tell us as well if the way Espal uses the dependency makes the flaw worse.
