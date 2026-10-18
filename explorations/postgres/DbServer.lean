import Std.Http
import Spike.Pg.Conn
import Spike.Pg.Libpq
import Spike.Pg.Pool

/-!
TechEmpower's `/db` on Std.Http: one random `world` row per request, as JSON. A pool of connections,
picked in turn, serves all requests, and each connection pipelines the queries it receives.

Usage: db-server (wire | libpq) PORT [CONNS]
-/

open Std Async Http Net Spike.Pg

def sql := "SELECT id, randomnumber FROM world WHERE id = $1"
def conninfo := "host=127.0.0.1 port=5432 user=benchmarkdbuser password=benchmarkdbpass dbname=hello_world"

abbrev Lookup := UInt32 → Async (UInt32 × UInt32)

def wireLookup (c : Conn) : Lookup := fun id => do
  let rows ← c.query "w" #[Wire.be32 id]
  let some row := rows[0]? | throw (IO.userError "no row")
  let (some a, some b) := (row[0]?.join, row[1]?.join) | throw (IO.userError "null column")
  return (Wire.u32At a 0, Wire.u32At b 0)

def handle (pool : Pool) (req : Request Body.Stream) : ContextAsync (Response Body.Any) := do
  match toString req.line.uri with
  | "/db" =>
    let id := ((← IO.rand 1 10000).toUInt32)
    try
      let (rid, rn) ← pool.query id
      Response.ok |>.json s!"\{\"id\":{rid},\"randomNumber\":{rn}}"
    catch e =>
      Response.serviceUnavailable |>.text (toString e)
  | "/plaintext" => Response.ok |>.text "Hello, World!"
  | _ => Response.notFound |>.text "not found"

def main (args : List String) : IO Unit := do
  let kind := args[0]?.getD "wire"
  let port := (args[1]? >>= String.toNat?).getD 8080
  let conns := (args[2]? >>= String.toNat?).getD 4
  Async.block do
    let open_ : Async Slot :=
      if kind == "libpq" then do
        let c ← LibpqConn.connect conninfo sql
        pure { lookup := c.query, broken := c.broken.get }
      else do
        let c ← connect (.ofParts 127 0 0 1) 5432 "benchmarkdbuser" "benchmarkdbpass" "hello_world" #[("w", sql, #[23])]
        pure { lookup := wireLookup c, broken := c.broken.get }
    let pool ← Pool.new conns open_
    let config : Std.Http.Config := { maxRequests := 100000000 }
    let addr : SocketAddress := SocketAddressV4.mk (.ofParts 0 0 0 0) port.toUInt16
    let server ← Std.Http.Server.serve addr (Server.Handler.ofFn (handle pool)) config
    server.waitShutdown
