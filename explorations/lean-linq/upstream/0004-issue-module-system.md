Lean's module system has been stable since Lean 4.27.0, and a file that starts with `module` can only import other modules. Projects that adopt it can't import lean-linq yet, since Lean reports `cannot import non-module LeanLinq from module`. Files outside the module system can still import modules, so moving lean-linq over wouldn't change anything for its current users.

I converted a copy on Lean 4.35.0 to see how much work it is. Everything up to `Theorems.lean` builds. That took a `module` header and public imports in each file, the `backward.privateInPublic` porting option, and `meta` on the elaborators and the helpers they call.

`Theorems.lean` is harder. Its proofs rewrite with `List.filterAuxM`, and Lean's core doesn't expose that function's body to modules, so those proofs need another approach. `Db.lean` and the root module come after it, so I haven't checked them yet.

Would moving to the module system be a good fit for lean-linq? If so, I could open a draft pull request with the conversion so far and work through `Theorems.lean` with you.
