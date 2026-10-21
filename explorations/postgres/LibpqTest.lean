import Spike.Pg.Libpq
open Spike.Pg

def conninfo : String :=
  "host=127.0.0.1 port=5432 user=benchmarkdbuser password=benchmarkdbpass dbname=hello_world"

/-- Replies that `espal_pq_next` must refuse, because a column is not one binary `int4`. -/
def malformed : List String :=
  ["SELECT id, NULL::int FROM world WHERE id = $1",
   "SELECT id::bigint, randomnumber FROM world WHERE id = $1",
   "SELECT id::text, randomnumber FROM world WHERE id = $1"]

def main : IO UInt32 := do
  let c ← LibpqConn.connect conninfo "SELECT id, randomnumber FROM world WHERE id = $1"
  IO.eprintln "connected"
  let p ← IO.Promise.new
  c.pending.atomically do
    modify (·.enqueue p)
    c.pq.send 42
  IO.eprintln "sent"
  let r ← IO.wait p.result?
  IO.eprintln s!"plain IO: {match r with | some (.ok v) => toString (v >>> 32) | some (.error e) => toString e | none => "dropped"}"
  let v ← Std.Async.Async.block (c.query 43)
  IO.eprintln s!"async: {v}"
  let mut accepted := 0
  for sql in malformed do
    let bad ← LibpqConn.connect conninfo sql
    match ← (Std.Async.Async.block (bad.query 42)).toBaseIO with
    | .ok v =>
      IO.eprintln s!"accepted {v}: {sql}"
      accepted := accepted + 1
    | .error e => IO.eprintln s!"refused ({e}): {sql}"
  -- The reader tasks keep the process alive, so exit here.
  IO.Process.exit (if accepted == 0 then 0 else 1)
