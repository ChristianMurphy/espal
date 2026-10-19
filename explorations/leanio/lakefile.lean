import Lake

open Lake DSL

package «leanio-trial»

-- setup.sh clones LeanIO here, patched to build on Lean 4.35 and later.
require leanio from "leanio"

@[default_target] lean_lib Trial

@[default_target] lean_exe «multipart-split» where root := `MultipartSplit
