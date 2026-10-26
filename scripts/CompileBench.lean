/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/

/-!
# Compile-time benchmark for the `api` command

Generates modules that declare an `api` table of 10, 50 and 200 routes, compiles each three times
with `lake env lean`, and fails when the median time exceeds the budget for that size. Every route
is a `GET` under the same two literals, so the table check compares every pair of routes through
three segments. A module that only imports `EspalRoute` gives the fixed cost of a compile.

Run with `lake exe compile-bench` after `lake build`.
-/

/-- Each table size, with the budget in milliseconds for its median compile time. Size 0 is the
module that only imports `EspalRoute`. -/
def budgets : List (Nat × Nat) :=
  [(0, 5000), (10, 5000), (50, 10000), (200, 50000)]

/-- How many times each module is compiled. -/
def runs : Nat :=
  3

/-- A module with an `api` table of `n` routes, or only the import when `n` is 0. -/
def source (n : Nat) : String :=
  let header := "module\n\nimport EspalRoute\n\nopen Espal\n"
  if n == 0 then header
  else
    let handlers :=
      (List.range n).map fun i => s!"def h{i} (_ : Public) (id : Nat) : String := toString id\n"
    let rows := (List.range n).map fun i => s!"  GET \"/api/items/r{i}/:id\" => h{i}\n"
    header ++ "\n" ++ String.join handlers ++ "\napi Bench where\n" ++ String.join rows

/-- The wall-clock time in milliseconds to compile `file`. -/
def compileMs (root file : System.FilePath) : IO Nat := do
  let start ← IO.monoMsNow
  let out ←
    IO.Process.output { cmd := "lake", args := #["env", "lean", file.toString], cwd := root }
  let stop ← IO.monoMsNow
  unless out.exitCode == 0 do
    throw (IO.userError s!"{file} failed to compile:\n{out.stdout}{out.stderr}")
  return stop - start

/-- `ms` in seconds with two decimals. -/
def seconds (ms : Nat) : String :=
  let hundredths := (ms + 5) / 10
  let frac := toString (hundredths % 100)
  s!"{hundredths / 100}.{if frac.length < 2 then "0" ++ frac else frac}"

def main : IO UInt32 := do
  -- The executable is at `<root>/.lake/build/bin/compile-bench`.
  let some root := (← IO.appPath).parent.bind (·.parent) |>.bind (·.parent) |>.bind (·.parent)
    | throw (IO.userError "compile-bench: cannot locate the package root")
  let dir := root / ".lake" / "compile-bench"
  IO.FS.createDirAll dir
  let mut lines := #["| Routes | Median (s) | Range (s) | Budget (s) |", "|---|---|---|---|"]
  let mut over := #[]
  for (n, budget) in budgets do
    let file := dir / s!"Api{n}.lean"
    IO.FS.writeFile file (source n)
    let mut times := #[]
    for _ in [0:runs] do
      times := times.push (← compileMs root file)
    let sorted := times.toList.mergeSort (· ≤ ·)
    let median := sorted[sorted.length / 2]?.getD 0
    let low := sorted.head?.getD 0
    let high := sorted.getLast?.getD 0
    let line := s!"| {n} | {seconds median} | {seconds low}–{seconds high} | {seconds budget} |"
    IO.println line
    lines := lines.push line
    if median > budget then
      let what := if n == 0 then "the module with no table" else s!"the table of {n} routes"
      over := over.push s!"{what} took {seconds median} s, over its {seconds budget} s budget"
  if let some summary := (← IO.getEnv "GITHUB_STEP_SUMMARY") then
    let h ← IO.FS.Handle.mk summary .append
    h.putStrLn ("## `api` compile time\n\n" ++ "\n".intercalate lines.toList)
  for msg in over do
    IO.eprintln s!"compile-bench: {msg}"
  return if over.isEmpty then 0 else 1
