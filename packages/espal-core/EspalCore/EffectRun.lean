/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Effect
public import Std.Async
import Std.Time

/-!
# Running effects for real

`Eff.run` answers each operation of a program from the machine it runs on. It reads the system
clock, draws from Lean's random generator, writes log lines to standard error and hands each
statement to a `Database`. A `Database` has one function for `query` and one for `statement`, so a
client can send reads where the database refuses a write. No proof covers `Eff.run`. `Eff.eval`
in `EspalCore.Effect` is the pure run that the proofs describe.

The run is an `Async` program, so a statement that waits for the database doesn't hold a thread.
-/

public section

namespace Espal

open LeanLinq Std.Async

/-- How the machine runs statements. -/
structure Database where
  /-- Runs a statement that only reads. A client may send it where the database refuses writes. -/
  query : Statement → Async Rows
  /-- Runs a statement that may write. -/
  statement : Statement → Async Rows

/-- The database of a server that has none. Every statement fails. -/
def Database.none : Database :=
  { query := fun _ => throw (IO.userError "no database is configured")
    statement := fun _ => throw (IO.userError "no database is configured") }

/-- The answer of the machine to one operation, with `database` running statements. -/
def Op.perform (database : Database) : {β : Type} → Op β → Async β
  | _, .now => do
    let stamp ← Std.Time.Timestamp.now
    return stamp.toMillisecondsSinceUnixEpoch.val.toNat
  | _, .random lo hi => IO.rand lo hi
  | _, .log line => IO.eprintln line
  | _, .query s => database.query s
  | _, .statement s => database.statement s

/-- Runs `x` against the machine, with `database` running its statements. -/
def Eff.run {α : Type} (x : Eff α) (database : Database := .none) : Async α :=
  FreerD.foldM (E := Op) (spec := opWp) (m := Async) (Op.perform database) (w := Wp.triv α) x

end Espal
