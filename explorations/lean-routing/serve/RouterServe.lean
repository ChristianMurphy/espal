import Routing

/-!
One Std.Http server with four handlers, picked by the first argument, to measure what lean-routing
adds to a request. `bare` matches the URI as a string, as the HTTP spike's server does.
-/

open Std Async Http Net Server Routing

def plaintext : Result := fun _ => Response.ok |>.text "Hello, World!"

def bare (req : Request Body.Stream) : ContextAsync (Response Body.Any) :=
  match toString req.line.uri with
  | "/plaintext" => plaintext req
  | _ => Response.notFound |>.text "not found"

/-- `n` routes of the form `/r<i>/:id:Nat`, which `/plaintext` fails on its first segment. -/
def filler (n : Nat) : List (Route Result) :=
  (List.range n).filterMap fun i =>
    let s := s!"r{i}"
    if h : dotSegment s = false then
      some (.get [.lit s h, .capture "id" .nat] fun (_ : Nat) => plaintext)
    else none

def table (n : Nat) : List (Route Result) :=
  filler n ++ [.get [.lit "plaintext"] plaintext]

/-- A middleware that passes each request and response through untouched. -/
def passThrough (inner : StatelessHandler) : StatelessHandler :=
  { inner with
    onRequest := fun req => do
      return (← inner.onRequest req) }

def router (n : Nat) : Router :=
  { middlewares := [passThrough, passThrough], routes := (table n).map .route }

def handlerFor : String → Option StatelessHandler
  | "bare" => some (Handler.ofFn bare)
  | "table-2" => some (toHandler (table 1))
  | "table-200" => some (toHandler (table 199))
  | "router-200" => some (router 199).toHandler
  | _ => none

def main (args : List String) : IO UInt32 := do
  let some handler := args.head? >>= handlerFor
    |
    IO.eprintln "usage: router-serve bare|table-2|table-200|router-200 PORT";
    return 1
  let port := (args[1]? >>= String.toNat?).getD 8080
  let config : Std.Http.Config := { maxRequests := 100000000 }
  Async.block do
      let addr : SocketAddress := SocketAddressV4.mk (.ofParts 0 0 0 0) port.toUInt16
      let server ← Std.Http.Server.serve addr handler config
      server.waitShutdown
  return 0
