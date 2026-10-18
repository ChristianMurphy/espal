import Lake
open Lake DSL

package «linq-trial»

require «lean-linq» from git "https://github.com/palladin/lean-linq" @ "463e34a331e0912170b3116b76b98b17ca3a67bd"

@[default_target]
lean_lib Trial

@[default_target]
lean_exe «pg-smoke» where
  root := `PgSmoke
  -- lean-linq's own link arguments stay inside its package, so a dependent names libpq itself.
  moreLinkArgs := #["/usr/lib/x86_64-linux-gnu/libpq.so", "-Wl,--allow-shlib-undefined"]
