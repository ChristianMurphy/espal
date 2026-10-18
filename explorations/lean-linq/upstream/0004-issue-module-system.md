Lean's module system has been stable since Lean 4.27.0, and a file that starts with `module` can only import other modules. Projects that adopt it can't import lean-linq yet, since Lean reports `cannot import non-module LeanLinq from module`. Files outside the module system can still import modules, so moving lean-linq over wouldn't change anything for its current users.

Most of the move looks mechanical. A trial conversion on Lean 4.35.0 builds every module up to `Theorems.lean` with these changes:

- a `module` header, public imports and an exposed public section in each file;
- the `backward.privateInPublic` porting option, so private helpers can stay private;
- `meta` on the six elaborators and macros and on the four helpers they call.

`Theorems.lean` is the open part. Its proofs rewrite with `List.filterAuxM`, whose body Lean's core doesn't expose to modules, so they'd need another route. `Db.lean` and the root module build after it and remain unchecked.

Would moving to the module system be a good fit for lean-linq? If so, I could open a draft pull request with the conversion so far and work through `Theorems.lean` with you.
