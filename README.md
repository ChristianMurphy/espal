# Espal

Espal is a web framework for Lean 4. You declare routes, inputs and results in a few lines. The compiler then proves properties that other frameworks leave to tests. Every route reaches its handler, and every link points at a real route. Queries stay inside the caller's tenant, and pages escape what they render.

The name is short for espalier, a tree trained along a frame as it grows.

## Status

Early development. The first module, `Espal.Route`, provides typed routes and a decimal path codec with a proved round trip. The design is in progress; see the design notes linked from the issue tracker as they land.

## Building

Espal uses [Lake](https://github.com/leanprover/lean4/tree/master/src/lake) and the Lean version pinned in `lean-toolchain`.

```bash
lake build      # library
lake test       # tests
```

## License

Apache 2.0. See [LICENSE](LICENSE).
