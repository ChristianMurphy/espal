Lean's [module system](https://lean-lang.org/doc/reference/latest/The-Module-System/) has been stable since 4.27.0. A file that uses it can't import lean-linq today:

```lean
module

import LeanLinq  -- error: cannot import non-`module` LeanLinq from `module`
```

Files outside the module system can still import modules, so converting lean-linq wouldn't affect its current users.

I converted a copy on Lean 4.35.0, and everything up to `Theorems.lean` builds. `Theorems.lean` rewrites with `List.filterAuxM`, a core function whose body modules can't see.

Would the module system be a good fit for lean-linq? If so, I could open a draft pull request and work through `Theorems.lean` with you.
