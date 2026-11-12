/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Effect
import Std.Time

/-!
# Running effects for real

`Eff.run` answers each operation of a program from the machine it runs on. It reads the system
clock, draws from Lean's random generator and writes log lines to standard error. No proof covers
it. `Eff.eval` in `EspalCore.Effect` is the pure run that the proofs describe.
-/

public section

namespace Espal

open LeanLinq

/-- The answer of the machine to one operation. -/
def Op.perform : {β : Type} → Op β → IO β
  | _, .now => do
    let stamp ← Std.Time.Timestamp.now
    return stamp.toMillisecondsSinceUnixEpoch.val.toNat
  | _, .random lo hi => IO.rand lo hi
  | _, .log line => IO.eprintln line

/-- Runs `x` against the machine. -/
def Eff.run {α : Type} (x : Eff α) : IO α :=
  FreerD.foldM (E := Op) (spec := opWp) (m := IO) Op.perform (w := Wp.bill 0) x

end Espal
