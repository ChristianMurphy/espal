import Lake

open System Lake DSL

package «espal-postgres» where
  version := v!"0.0.1"
  description := "Espal's Postgres client, on libpq in pipeline mode"
  license := "Apache-2.0"

require «espal-core» from ".." / "espal-core"

/-- What `pg_config` prints for one of its options, asked when a target builds. -/
def pgConfig (option : String) : JobM String := do
  let out ← captureProc { cmd := "pg_config", args := #[option] }
  return out.trimAscii.toString

input_file pq.c where
  path := "c" / "pq.c"
  text := true

target pq.o pkg : FilePath := do
  let source ← pq.c.fetch
  let leanInclude ← getLeanIncludeDir
  source.bindM fun file => do
      let pgInclude ← pgConfig "--includedir"
      buildO (pkg.buildDir / "c" / "pq.o") (pure file)
          #["-I", leanInclude.toString, "-I", pgInclude] #["-fPIC", "-O2", "-Wall", "-Werror"] "cc"
          getLeanTrace

target libespalpq pkg : FilePath := do
  buildStaticLib (pkg.staticLibDir / nameToStaticLib "espalpq") #[← pq.o.fetch]

/-- The shared libpq by its path, since a library directory would bring in the system glibc. -/
target libpq : FilePath :=
  Job.async do
    let dir ← pgConfig "--libdir"
    return (dir : FilePath) / "libpq.so"

@[default_target] lean_lib EspalPostgres where
  leanOptions := #[⟨`autoImplicit, false⟩, ⟨`linter.missingDocs, true⟩]
  moreLinkObjs := #[libespalpq, libpq]
