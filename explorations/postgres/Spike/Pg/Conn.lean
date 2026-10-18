import Std.Async
import Std.Net.Addr
import Spike.Pg.Crypto
import Spike.Pg.Wire

/-!
A pipelined Postgres connection over Std.Async TCP. Sign-in uses SCRAM-SHA-256. Each query sends
`Bind`, `Execute` and `Sync`, so an error fails only its own query, and many queries can be in flight
on one connection. A reader task matches responses to queries in order.
-/

namespace Spike.Pg

open Std Async Net Wire

abbrev Row := Array (Option ByteArray)
abbrev Reply := Except IO.Error (Array Row)

structure Conn where
  client : TCP.Socket.Client
  pending : Std.Mutex (Std.Queue (IO.Promise Reply))
  broken : IO.Ref Bool

/-- Reads until at least one complete message is available, returning messages and leftover bytes. -/
partial def readMsgs (client : TCP.Socket.Client) (buf : ByteArray) : Async (Array Msg × ByteArray) := do
  let (msgs, rest) := split buf
  if !msgs.isEmpty then return (msgs, rest)
  match ← client.recv? 65536 with
  | none => throw (IO.userError "postgres closed the connection")
  | some chunk => readMsgs client (rest ++ chunk)

/-- Runs SCRAM-SHA-256 (RFC 5802, RFC 7677) and waits for `ReadyForQuery`. -/
partial def handshake (client : TCP.Socket.Client) (password : String) : Async Unit := do
  let nonce := Crypto.base64 (← IO.getRandomBytes 18)
  let clientFirstBare := s!"n=,r={nonce}"
  let mut buf := ByteArray.empty
  let mut serverSig : Option ByteArray := none
  let mut authMessage := ""
  repeat
    let (msgs, rest) ← readMsgs client buf
    buf := rest
    for m in msgs do
      match m.tag with
      | 'R' =>
        match u32At m.body 0 with
        | 0 => pure ()
        | 10 => client.send (saslInitial "SCRAM-SHA-256" s!"n,,{clientFirstBare}".toUTF8)
        | 11 =>
          let serverFirst := String.fromUTF8! (m.body.extract 4 m.body.size)
          let attrs := serverFirst.splitOn ","
          let get := fun (p : String) => (attrs.find? (·.startsWith p)).map (·.drop p.length |>.toString)
          let some r := get "r=" | throw (IO.userError "SCRAM: no nonce")
          let some s := get "s=" | throw (IO.userError "SCRAM: no salt")
          let some i := get "i=" | throw (IO.userError "SCRAM: no iteration count")
          let some salt := Crypto.unbase64 s | throw (IO.userError "SCRAM: bad salt")
          unless r.startsWith nonce do throw (IO.userError "SCRAM: server nonce does not extend ours")
          let salted := Crypto.pbkdf2 password.toUTF8 salt i.toNat!
          let clientKey := Crypto.hmac salted "Client Key".toUTF8
          let storedKey := Crypto.sha256 clientKey
          let finalBare := s!"c=biws,r={r}"
          authMessage := s!"{clientFirstBare},{serverFirst},{finalBare}"
          let proof := Crypto.xorBytes clientKey (Crypto.hmac storedKey authMessage.toUTF8)
          serverSig := some (Crypto.hmac (Crypto.hmac salted "Server Key".toUTF8) authMessage.toUTF8)
          client.send (saslResponse s!"{finalBare},p={Crypto.base64 proof}".toUTF8)
        | 12 =>
          let serverFinal := String.fromUTF8! (m.body.extract 4 m.body.size)
          unless serverSig.map (fun sig => "v=" ++ Crypto.base64 sig) == some serverFinal do
            throw (IO.userError "SCRAM: server signature does not match")
        | n => throw (IO.userError s!"unsupported authentication request {n}")
      | 'E' => throw (IO.userError (errorText m.body))
      | 'Z' => return
      | _ => pure ()

/-- Sends `msgs` and waits for `ReadyForQuery`, failing on `ErrorResponse`. -/
partial def roundTrip (client : TCP.Socket.Client) (msgs : ByteArray) : Async Unit := do
  client.send msgs
  let mut buf := ByteArray.empty
  let mut err : Option String := none
  repeat
    let (ms, rest) ← readMsgs client buf
    buf := rest
    for m in ms do
      if m.tag == 'E' then err := some (errorText m.body)
      if m.tag == 'Z' then
        if let some e := err then throw (IO.userError e)
        return

def failAll (c : Conn) (e : IO.Error) : BaseIO Unit := do
  c.broken.set true
  let waiting ← c.pending.atomically do
    let q ← get
    set (∅ : Std.Queue (IO.Promise Reply))
    return q.toArray
  for p in waiting do
    p.resolve (.error e)

/-- Reads responses and resolves pending queries in order. -/
partial def readerLoop (c : Conn) (buf : ByteArray) (rows : Array Row) (err : Option String) : Async Unit := do
  match ← c.client.recv? 65536 with
  | none => failAll c (IO.userError "postgres closed the connection")
  | some chunk =>
    let (msgs, rest) := split (buf ++ chunk)
    let mut rows := rows
    let mut err := err
    for m in msgs do
      match m.tag with
      | 'D' => rows := rows.push (dataRow m.body)
      | 'E' => err := some (errorText m.body)
      | 'Z' =>
        let next ← c.pending.atomically do
          match (← get).dequeue? with
          | some (p, q) => set q; return some p
          | none => return none
        if let some p := next then
          p.resolve (match err with | some e => .error (IO.userError e) | none => .ok rows)
        rows := #[]
        err := none
      | _ => pure ()
    readerLoop c rest rows err

def connect (host : IPv4Addr) (port : UInt16) (user password database : String)
    (prepare : Array (String × String × Array UInt32)) : Async Conn := do
  let client ← TCP.Socket.Client.mk
  client.connect (SocketAddressV4.mk host port)
  client.noDelay
  client.send (startup user database)
  handshake client password
  let msgs := prepare.foldl (fun acc (name, sql, types) => acc ++ parse name sql types) .empty
  roundTrip client (msgs ++ sync)
  let c : Conn := { client, pending := ← Std.Mutex.new ∅, broken := ← IO.mkRef false }
  background do
    try readerLoop c .empty #[] none
    catch e => failAll c e
  return c

/-- Runs a prepared statement with binary parameters, pipelined behind any queries in flight. -/
def Conn.query (c : Conn) (statement : String) (params : Array ByteArray) : Async (Array Row) := do
  if ← c.broken.get then throw (IO.userError "connection is broken")
  let p ← IO.Promise.new
  let sent ← c.pending.atomically do
    modify (·.enqueue p)
    c.client.native.send #[bind statement params ++ execute ++ sync]
  Async.ofPromise (pure sent)
  Async.ofPromise (pure p)

end Spike.Pg
