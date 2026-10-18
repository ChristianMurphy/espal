Espal, a web framework I'm building, uses Lean's module system, and Lean refuses to import lean-linq from a file that starts with `module`. The error is `cannot import non-module LeanLinq from module`.

I tried a scripted conversion. It added a `module` header, public imports and an exposed public section to each file, made private helpers public, and marked the elaborators `meta`. It stopped at two files. `Core/Grouped.lean` uses private constructors inside public definitions, and the proofs in `Theorems.lean` rewrite with `List.filterAuxM`, whose body Lean doesn't expose to modules. Both need decisions about what lean-linq exposes.

Is moving to the module system something you'd want for lean-linq? If so, I could open a draft pull request with the conversion so far, as a place to talk through those two files.
