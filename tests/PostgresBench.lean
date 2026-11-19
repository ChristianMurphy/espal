module

import Espal

/-!
Measures queries per second through `espal-postgres`, with `workers` lookups in flight over a pool
of `conns` read-only sessions. Each lookup is TechEmpower's single-row query on the `world` table.

Usage: `lake exe postgres-bench CONNS WORKERS SECONDS [TIMEOUT_MS]`, with the connection string
in `ESPAL_BENCH_DATABASE`. The time limit per statement defaults to the pool's 5000 ms, and zero
sets none.
-/

open Espal Espal.Postgres Std.Async

/-- Looks up one `world` row and returns the id it holds. -/
def lookup (database : Database) (id : Nat) : Async Nat := do
  let rows ← database.query ⟨"SELECT id, randomnumber FROM world WHERE id = $1", #[toString id]⟩
  match (rows[0]?).bind (·[0]?) with
  | some (some text) =>
    return text.toNat?.getD 0
  | _ =>
    throw (IO.userError s!"no row for {id}")

/-- Looks rows up one after another until `deadline`, and returns how many it read. -/
partial def worker (database : Database) (seed : UInt32) (deadline count : Nat) : Async Nat := do
  if (← IO.monoMsNow) ≥ deadline then
    return count
  let x := seed ^^^ (seed <<< 13)
  let x := x ^^^ (x >>> 17)
  let x := x ^^^ (x <<< 5)
  let id := x.toNat % 10000 + 1
  let found ← lookup database id
  if found != id then
    throw (IO.userError s!"wrong row {found} for {id}")
  worker database x deadline (count + 1)

public def main (args : List String) : IO UInt32 := do
  let conns := (args[0]?.bind String.toNat?).getD 1
  let workers := (args[1]?.bind String.toNat?).getD 1
  let seconds := (args[2]?.bind String.toNat?).getD 5
  let some conninfo ←
    IO.getEnv
        "ESPAL_BENCH_DATABASE" | throw (IO.userError "set ESPAL_BENCH_DATABASE to a libpq connection string")
  let timeoutMs := (args[3]?.bind String.toNat?).getD 5000
  let pool ← Pool.connect (.wrap conninfo) (size := conns) (timeoutMs := timeoutMs.toUInt32)
  let database := pool.database
  let outcome ←
    (Async.block do
          discard <| lookup database 42
          let deadline := (← IO.monoMsNow) + seconds * 1000
          let started ← IO.monoNanosNow
          let counts ←
            Async.concurrentlyAll
                ((List.range workers).toArray.map fun i =>
                  worker database (i.toUInt32 * 2654435761 + 1) deadline 0)
          let elapsed := ((← IO.monoNanosNow) - started).toFloat / 1e9
          let total := counts.foldl (· + ·) 0
          IO.println
              s!"espal-postgres conns={conns} workers={workers}: {total} queries in {elapsed}s = {(total.toFloat / elapsed).round} q/s").toBaseIO
  pool.close
  match outcome with
  | .ok () =>
    return 0
  | .error error =>
    IO.eprintln s!"postgres-bench failed: {error}"
    return 1
