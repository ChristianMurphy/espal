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
clock, draws from Lean's random generator, writes log lines to standard error and hands each
statement to a `Database` function, whether it came from `query` or `statement`. No proof covers it. `Eff.eval` in `EspalCore.Effect` is the pure run that the proofs describe.
-/

public section

namespace Espal

open LeanLinq

/-- How the machine runs one statement. -/
abbrev Database :=
  Statement → IO Rows

/-- The database of a server that has none. Every statement fails. -/
def Database.none : Database := fun _ => throw (IO.userError "no database is configured")

/-- The answer of the machine to one operation, with `database` running statements. -/
def Op.perform (database : Database) : {β : Type} → Op β → IO β
  | _, .now => do
    let stamp ← Std.Time.Timestamp.now
    return stamp.toMillisecondsSinceUnixEpoch.val.toNat
  | _, .random lo hi => IO.rand lo hi
  | _, .log line => IO.eprintln line
  | _, .query s => database s
  | _, .statement s => database s

/-- Runs `x` against the machine, with `database` running its statements. -/
def Eff.run {α : Type} (x : Eff α) (database : Database := .none) : IO α :=
  FreerD.foldM (E := Op) (spec := opWp) (m := IO) (Op.perform database) (w := Wp.triv α) x

end Espal
