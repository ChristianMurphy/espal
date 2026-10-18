import Spike.Pg.Libpq
open Spike.Pg
def main : IO Unit := do
  let c ← LibpqConn.connect "host=127.0.0.1 port=5432 user=benchmarkdbuser password=benchmarkdbpass dbname=hello_world" "SELECT id, randomnumber FROM world WHERE id = $1"
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
