import Lake
open System Lake DSL

package «pg-spike»

lean_lib Spike

input_file pq.c where
  path := "c" / "pq.c"
  text := true

target pq.o pkg : FilePath := do
  let srcJob ← pq.c.fetch
  let oFile := pkg.buildDir / "c" / "pq.o"
  let weakArgs := #["-I", (← getLeanIncludeDir).toString, "-I", "/usr/include/postgresql"]
  buildO oFile srcJob weakArgs #["-fPIC", "-O2"] "cc" getLeanTrace

target libpqspike pkg : FilePath := do
  let o ← pq.o.fetch
  buildStaticLib (pkg.staticLibDir / nameToStaticLib "pqspike") #[o]

@[default_target]
lean_exe «crypto-test» where
  root := `CryptoTest

@[default_target]
lean_exe «pg-bench» where
  root := `PgBench
  moreLinkObjs := #[libpqspike]
  -- Only libpq: the system library directory would bring in a newer glibc than Lean links against.
  moreLinkArgs := #["-L.lake/syslib", "-lpq"]

lean_exe «libpq-test» where
  root := `LibpqTest
  moreLinkObjs := #[libpqspike]
  moreLinkArgs := #["-L.lake/syslib", "-lpq"]

@[default_target]
lean_exe «db-server» where
  root := `DbServer
  moreLinkObjs := #[libpqspike]
  moreLinkArgs := #["-L.lake/syslib", "-lpq"]
