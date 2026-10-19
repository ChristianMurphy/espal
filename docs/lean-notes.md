# Lean notes

These notes come from the HTTP and Postgres spikes and the lean-linq trial. They hold for Lean 4.35.0 and 4.36.0-rc1.

## Toolchain and linking

- Lean links executables with its own `ld.lld` and an older glibc. Adding the system library directory, such as `-L/usr/lib/x86_64-linux-gnu`, pulls in the system glibc and breaks the link. Link a system library by its file path, or from a directory that holds only that library.
- Lean links with `--no-allow-shlib-undefined`. Some system libraries, such as SQLite on Ubuntu 24.04, use newer glibc symbols and need `-Wl,--allow-shlib-undefined`. On the same system, libpq didn't.
- A task started with `prio := .dedicated` that blocks in C keeps the process alive after `main` returns, so such programs call `IO.Process.exit`.

## Lake

- `lake build --wfail` also fails on warnings in modules from dependencies.
- An executable gets the `moreLinkObjs` and `moreLinkLibs` of every library it imports, including libraries in other packages, and the `extern_lib` targets of every package. It gets `moreLinkArgs` only from its own package and library.
- `moreLinkLibs` turns each library into `-L<dir> -l<name>`, so a system directory there brings back the glibc problem. `moreLinkObjs` passes a plain path.
- Lake evaluates a lakefile when it loads the package, including any `elab` terms in its settings, and it does so for dependencies too. A library lookup in such a term runs on every load and can stop it.
- `target` declarations must come after `package`.
- `lake -R` reconfigures. Without it, Lake reuses the elaborated lakefile.

## Module system

- The module system has been stable since Lean 4.27.0. A `module` file can import only modules, and other files can import modules.
- When porting, `backward.privateInPublic` lets private declarations appear inside public, exposed definitions. Elaborators, macros and the helpers they call need `meta`.
- In a module, `rw` and `simp` can't unfold a core definition whose body isn't exposed, such as `List.filterAuxM`.

## Changes between versions

- Lean 4.35.0 deprecates `String.data`, and 4.36.0-rc1 removes it. Use `String.toList`.
- Lean 4.35.0 deprecates `if_pos` and `if_neg` in favor of `ite_eq_left` and `ite_eq_right`.

## Writing Lean

- `#guard_msgs (substring := true)` matches part of a message, which keeps a test stable when the message contains metavariable numbers.
- Patterns can match a constructor binder by name, as in `.fromT (inst := i) ..`. The unused-variables linter flags such binders anyway, and renaming them breaks those patterns.

## Std.Async and Std.Http

- Std.Async can wait on sockets that Lean opened, but not on one from C. The libuv loop, `lean::global_ev`, is private, and the toolchain ships no libuv headers.
- Std.Http on 4.36.0-rc1 spends most of each request on thread handoffs ([lean4#13469](https://github.com/leanprover/lean4/issues/13469)), so Espal runs one process per core.

## The Lean community

- The lean4 RFC template asks for a Zulip discussion before the RFC. The triage team labels each RFC P-high, P-medium or P-low, or closes it. Runtime work isn't open to outside pull requests.
- The Lean Zulip needs a login, even for its API. The public archive at leanprover-community.github.io stopped updating in February 2026.
- The GitHub user algebraic-dev filed [lean4#13638](https://github.com/leanprover/lean4/issues/13638), the libuv file system RFC, and was the assignee on [lean4#14776](https://github.com/leanprover/lean4/issues/14776), a libuv locking bug.
