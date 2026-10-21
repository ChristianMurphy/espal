/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/

/-!
# Espal test driver

Runs `lake test` in the `tests/` package. The tests live in a package of their own, which keeps
their dependencies, such as Plausible, out of the packages that require Espal.
-/

def main : IO UInt32 := do
  -- The executable is at `<root>/.lake/build/bin/tests`.
  let some root := (← IO.appPath).parent.bind (·.parent) |>.bind (·.parent) |>.bind (·.parent)
    | throw (IO.userError "tests: cannot locate the package root")
  let child ← IO.Process.spawn { cmd := "lake", args := #["test"], cwd := root / "tests" }
  child.wait
