import Std.Http
import Lean.Data.Json

/-!
`/plaintext` and `/json` on Std.Http, following the TechEmpower rules: the JSON body is
serialized on every request, and responses carry `Server` and `Date` headers.
-/

open Std Async Http Net

def handle (req : Request Body.Stream) : ContextAsync (Response Body.Any) :=
  match toString req.line.uri with
  | "/plaintext" => Response.ok |>.text "Hello, World!"
  | "/json" => Response.ok |>.json (Lean.Json.mkObj [("message", "Hello, World!")]).compress
  | _ => Response.notFound |>.text "not found"

def main (args : List String) : IO Unit := do
  let port := (args.head? >>= String.toNat?).getD 8080
  -- The default closes a keep-alive connection after 100 requests.
  let config : Std.Http.Config := { maxRequests := 100000000 }
  Async.block do
    let addr : SocketAddress := SocketAddressV4.mk (.ofParts 0 0 0 0) port.toUInt16
    let server ← Std.Http.Server.serve addr (Server.Handler.ofFn handle) config
    server.waitShutdown
