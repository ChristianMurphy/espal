import Lake
open Lake DSL

package «trie-bench»

require routing from git
  "https://github.com/ChristianMurphy/lean-routing"@"757b7eb5a5314e45f8851f993acabc1d18146906"

@[default_target] lean_exe «trie-bench» where root := `TrieBench
