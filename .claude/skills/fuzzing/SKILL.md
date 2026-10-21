---
name: fuzzing
description: Add property tests, fuzz tests and differential tests to Espal or its dependencies, beside the proofs they support. Use when a proof takes a premise about other code, when a parser reads network input, or when code runs where the kernel can't see it.
---

# Fuzzing

## Where tests belong

- Put a test at each premise a proof names, such as a property of `Std.Http`, a database or a C library. Code a theorem already covers needs no fuzzing.
- Code behind `@[implemented_by]`, `@[extern]`, `unsafe` or FFI needs a differential test against its reference definition, since the kernel never checks it.
- A parser of network input needs a malformed-input test even when it has a round-trip proof. That proof covers only bytes the printer can produce.
- Test the limits a model leaves out, such as nesting depth, buffer sizes and request sizes.
- When a premise gets a proof, delete its property and keep a few `#guard` examples.

## Writing properties

- Run properties with `#eval Plausible.Testable.check`. The `plausible` tactic leaves a `sorry` warning, which fails `--wfail`.
- Set `randomSeed` in CI, since Plausible never prints the seed it used. A scheduled job can rerun with a logged random seed and a larger `numInst`.
- Write a precondition into the Bool predicate as a disjunction, as lean-routing's `readsBack` does. With `quiet := true`, a run that gave up on its precondition passes without a word.
- Bias generators towards edge values. Plausible draws numbers only up to 100 and has no `ByteArray` generator. Add values such as 255, 2^63, empty and maximal sizes, and the format's special characters, such as `%`, `.` and `/` in a path.
- Turn each counterexample into a `#guard` regression test.
- `#eval` runs properties in the interpreter. To test compiled code, run the property from a `lean_exe`, or compare with `test_extern`.

## Layout

- Keep Plausible out of Espal's root lakefile, because Lake has no dev-dependency scope. Put it in a `tests/` Lake package that requires Espal by path. A root `@[test_driver]` script runs `lake test` there, as lean-routing's `test/` package does.
- Fuzz C code under AddressSanitizer with `LEAN_ABORT_ON_PANIC=1`, so a panic stops the run. The clang that ships with Lean lacks the libFuzzer and ASan runtimes.
