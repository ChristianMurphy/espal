import Std.Async
import Std.Net.Addr

/-!
A bare Std.Async loop: it counts request terminators and answers each one with fixed bytes. It
parses nothing, so it marks the ceiling for any HTTP server on this runtime.
-/

open Std Async Net

def response : ByteArray :=
  ("HTTP/1.1 200 OK\r\nServer: bare\r\nDate: Sun, 18 Oct 2026 00:00:00 GMT\r\n" ++
   "Content-Type: text/plain\r\nContent-Length: 13\r\n\r\nHello, World!").toUTF8

/-- Counts `\r\n\r\n` terminators in `chunk`, carrying the partial match `state` across chunks. -/
def countRequests (chunk : ByteArray) (state : Nat) : Nat × Nat := Id.run do
  let mut st := state
  let mut n := 0
  for b in chunk do
    st := match st, b with
      | 0, 13 | 2, 13 => st + 1
      | 1, 10 => 2
      | 3, 10 => 4
      | _, 13 => 1
      | _, _ => 0
    if st == 4 then
      n := n + 1
      st := 0
  return (n, st)

partial def serveClient (client : TCP.Socket.Client) (state : Nat) : Async Unit := do
  match ← client.recv? 65536 with
  | none => pure ()
  | some chunk =>
    let (n, st) := countRequests chunk state
    if n > 0 then
      client.sendAll (Array.replicate n response)
    serveClient client st

def main (args : List String) : IO Unit := do
  let port := (args.head? >>= String.toNat?).getD 8080
  Async.block do
    let server ← TCP.Socket.Server.mk
    server.bind (SocketAddressV4.mk (.ofParts 0 0 0 0) port.toUInt16)
    server.listen 1024
    server.noDelay
    while true do
      let client ← server.accept
      background (serveClient client 0)
