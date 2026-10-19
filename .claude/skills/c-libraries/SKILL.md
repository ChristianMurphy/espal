---
name: c-libraries
description: Rules for Lean dependencies, C bindings and linking system libraries with Lake. Use when adding a dependency, writing an FFI binding, or debugging a link error.
---

# Dependencies and C libraries

## Lean dependencies

- A dependency has to build under `lake build --wfail`, which counts its warnings too.
- It also has to use Lean's module system, because Espal's modules can import only modules.
- When porting one to the module system, the `backward.privateInPublic` option keeps private helpers private. Elaborators and macros, and the helpers they call, need `meta`.

## Linking

- Link a C library by its file path. Lean links with its own linker and glibc, and adding the system library directory with `-L` pulls in the system glibc.
- Some system libraries also need `-Wl,--allow-shlib-undefined`, because they use newer glibc symbols than Lean's.
- Name a C library in `moreLinkObjs` on the `lean_lib` that uses it. Lake passes those to every program that imports the library, while `moreLinkArgs` reach only the package's own programs.
- Look up system libraries inside a `target`. Top-level code in a lakefile runs whenever Lake loads the package, including as someone else's dependency.

## Run time

- A dedicated task that blocks in C keeps the process alive after `main` returns, so a program that starts one ends with `IO.Process.exit`.

## Tests

- When an error message holds metavariable numbers, match part of it with `#guard_msgs (substring := true)`.
