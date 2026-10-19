import Lake
open Lake DSL

package «trie-bench»

require routing from git
  "https://github.com/ChristianMurphy/lean-routing"@"dab78409afbd5d3876067715a2f608305abd62ab"

@[default_target] lean_exe «trie-bench» where root := `TrieBench
