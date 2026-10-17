# Espal

Espal is a web framework for Lean 4. You declare routes, inputs and results in a few lines, and the compiler checks how the app will behave under load.

- **Performance budgets.** Each endpoint declares how many database round trips and how much work it may spend. Code that could exceed its budget fails to compile, so an N+1 query loop never ships.
- **Stateless by construction.** Handlers cannot keep state between requests. Any node can serve any request, and the app scales out by adding nodes.

The name is short for espalier, a tree trained along a frame as it grows.

## Status

Early development. The features above are design goals, and a prototype has shown that query budgets work. The first module, `Espal.Route`, provides typed routes and a decimal path codec with a proved round trip. The design is in progress; see the design notes linked from the issue tracker as they land. [ROADMAP.md](ROADMAP.md) lays out the plan for 0.1, the guarantees we aim to claim, and how each one can fail.

## Building

Espal uses [Lake](https://github.com/leanprover/lean4/tree/master/src/lake) and the Lean version pinned in `lean-toolchain`.

```bash
lake build      # library
lake test       # tests
```

## License

Apache 2.0. See [LICENSE](LICENSE).
