import Lake

open Lake DSL

package «cedar-trial»

-- cedar-lean pins Batteries v4.34.0, which doesn't match Espal's toolchain.
require batteries from git "https://github.com/leanprover-community/batteries" @ "v4.35.0"

require Cedar from git
  "https://github.com/cedar-policy/cedar-spec" @ "7893e685a91a6a391d609fd9940a1c13dcdf2472" / "cedar-lean"

@[default_target] lean_lib Trial

lean_exe «authz-bench» where root := `AuthzBench

lean_exe «spec-size» where root := `SpecSize
