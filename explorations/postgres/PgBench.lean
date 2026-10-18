import Spike.Pg.Conn
import Spike.Pg.Libpq

/-!
Measures queries per second for the Lean wire client or the libpq binding, with `workers` queries in
flight spread over `conns` connections, each running the TechEmpower single-row lookup.

Usage: pg-bench (wire | libpq) CONNS WORKERS SECONDS
-/

open Std Async Spike.Pg

def sql := "SELECT id, randomnumber FROM world WHERE id = $1"
def conninfo := "host=127.0.0.1 port=5432 user=benchmarkdbuser password=benchmarkdbpass dbname=hello_world"

def decodeRow (r : Row) : Option (UInt32 × UInt32) := do
  let a ← r[0]?.join
  let b ← r[1]?.join
  return (Wire.u32At a 0, Wire.u32At b 0)

/-- One lookup through either client. -/
abbrev Lookup := UInt32 → Async (UInt32 × UInt32)

def wireLookup (c : Conn) : Lookup := fun id => do
  let rows ← c.query "w" #[Wire.be32 id]
  match rows[0]? >>= decodeRow with
  | some r => return r
  | none => throw (IO.userError "no row")

partial def worker (lookup : Lookup) (seed : UInt32) (deadline : Nat) (count : Nat) : Async Nat := do
  if (← IO.monoMsNow) ≥ deadline then return count
  let x := seed ^^^ (seed <<< 13); let x := x ^^^ (x >>> 17); let x := x ^^^ (x <<< 5)
  let id := x % 10000 + 1
  let (rid, _) ← lookup id
  if rid != id then throw (IO.userError s!"wrong row {rid} for {id}")
  worker lookup x deadline (count + 1)

def main (args : List String) : IO Unit := do
  let kind := args[0]?.getD "wire"
  let conns := (args[1]? >>= String.toNat?).getD 1
  let workers := (args[2]? >>= String.toNat?).getD 1
  let seconds := (args[3]? >>= String.toNat?).getD 5
  Async.block do
    let lookups : Array Lookup ← (List.range conns).toArray.mapM fun _ => do
      if kind == "libpq" then
        let c ← LibpqConn.connect conninfo sql
        pure (c.query : Lookup)
      else
        let c ← connect (.ofParts 127 0 0 1) 5432 "benchmarkdbuser" "benchmarkdbpass" "hello_world" #[("w", sql, #[23])]
        pure (wireLookup c)
    let some first := lookups[0]? | throw (IO.userError "no connections")
    IO.println s!"row for 42: {← first 42}"
    let deadline := (← IO.monoMsNow) + seconds * 1000
    let t0 ← IO.monoNanosNow
    let counts ← Async.concurrentlyAll ((List.range workers).toArray.map fun i =>
      worker (lookups[i % conns]?.getD first) (i.toUInt32 * 2654435761 + 1) deadline 0)
    let t1 ← IO.monoNanosNow
    let total := counts.foldl (· + ·) 0
    let secs := (t1 - t0).toFloat / 1e9
    IO.println s!"{kind} conns={conns} workers={workers}: {total} queries in {secs}s = {(total.toFloat / secs).round} q/s"
  -- libpq reader tasks stay blocked in poll and would keep the process alive.
  (← IO.getStdout).flush
  IO.Process.exit 0
