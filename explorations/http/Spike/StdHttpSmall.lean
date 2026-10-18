import Std.Http

/-!
The Std.Http server again, with JSON written by a small encoder in place of `Lean.Data.Json`.
It shows how much of the binary that import accounts for.
-/

open Std Async Http Net

/-- Encodes a string as a JSON string literal. -/
def jsonString (s : String) : String := Id.run do
  let mut out := "\""
  for c in s.toList do
    out := match c with
      | '"' => out ++ "\\\""
      | '\\' => out ++ "\\\\"
      | '\n' => out ++ "\\n"
      | '\r' => out ++ "\\r"
      | '\t' => out ++ "\\t"
      | c =>
        if c.toNat < 0x20 then
          let hex := (Nat.toDigits 16 c.toNat).asString
          out ++ "\\u" ++ "".pushn '0' (4 - hex.length) ++ hex
        else out.push c
  return out.push '"'

def handle (req : Request Body.Stream) : ContextAsync (Response Body.Any) :=
  match toString req.line.uri with
  | "/plaintext" => Response.ok |>.text "Hello, World!"
  | "/json" => Response.ok |>.json ("{\"message\":" ++ jsonString "Hello, World!" ++ "}")
  | _ => Response.notFound |>.text "not found"

def main (args : List String) : IO Unit := do
  let port := (args.head? >>= String.toNat?).getD 8080
  let config : Std.Http.Config := { maxRequests := 100000000 }
  Async.block do
    let addr : SocketAddress := SocketAddressV4.mk (.ofParts 0 0 0 0) port.toUInt16
    let server ← Std.Http.Server.serve addr (Server.Handler.ofFn handle) config
    server.waitShutdown
