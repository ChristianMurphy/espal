/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalPostgres.Libpq
import Init.While
public import Std.Async
public import Std.Data.HashMap
public import Std.Sync.Mutex

/-!
# One pipelined connection

A `Connection` sends each statement as soon as a handler asks, without waiting for the results of
earlier ones. One task per connection waits for results and hands each to the handler that sent
its statement, in order.

A connection prepares each SQL text on its first use and runs the prepared statement after
that, up to `maxPrepared` texts. A statement sent while its text's prepare is still in flight
runs by the same name, since the server takes them in order.

When the connection is lost, every statement still waiting fails, and so does every later one. The
pool then replaces the connection. A statement that the server refuses fails alone, and the
connection stays usable.
-/

public section

namespace Espal.Postgres

open Std.Async

/-- What a waiting handler gets: rows, or the server's refusal. -/
abbrev Answer :=
  Except Refusal Rows

/-- A statement sent and not yet answered. -/
structure Pending where
  /-- Where the answer goes. -/
  promise : IO.Promise (Except IO.Error Answer)
  /-- The statement's SQL text. -/
  sql : String
  /-- The prepared statement it ran by, or the empty string. -/
  name : String
  /-- Whether the statement was sent with a prepare of its text. -/
  prepares : Bool

/-- What a connection tracks under its lock. -/
structure Wire where
  /-- The statements still waiting for an answer, oldest first. -/
  waiting : Std.Queue Pending := ∅
  /-- The name of the prepared statement for each SQL text this session has prepared. -/
  names : Std.HashMap String String := ∅
  /-- The number the next prepared statement's name takes. -/
  next : Nat := 0

/-- A connection with the statements that still wait for a result. -/
structure Connection where
  /-- The libpq connection. -/
  raw : Raw
  /-- The waiting statements and the prepared ones. -/
  wire : Std.Mutex Wire
  /-- Whether the connection was lost or closed. -/
  broken : IO.Ref Bool
  /-- Resolved when the task that reads results has ended. -/
  ended : IO.Promise Unit
  /-- The most SQL texts the session prepares. Texts past it are parsed on every use. -/
  maxPrepared : Nat

/-- Fails every waiting statement with `error`, and marks the connection broken. -/
def Connection.fail (connection : Connection) (error : IO.Error) : BaseIO Unit := do
  connection.broken.set true
  let stranded ←
    connection.wire.atomically do
        let wire ← get
        set { wire with waiting := ∅ }
        return wire.waiting.toArray
  for pending in stranded do
    pending.promise.resolve (.error error)

/-- Whether a refusal means the session no longer has a usable prepared statement for the text.
`first` says that a prepare sent with the statement failed. `26000` says the name is unknown,
and `0A000` that a table changed under a cached plan. -/
def stale (prepares first : Bool) (state : String) : Bool :=
  (prepares && first) || state == "26000" || state == "0A000"

/-- Hands each answer to the oldest waiting statement, until the connection is lost or closed. A
refusal that leaves a text without a usable prepared statement forgets the text, so its next use
prepares it again under a new name. -/
def Connection.read (connection : Connection) : BaseIO Unit := do
  repeat
    match ← connection.raw.next.toBaseIO with
    | .ok answer =>
      let next ←
        connection.wire.atomically do
            let wire ← get
            match wire.waiting.dequeue? with
            | some (pending, rest) =>
              let names :=
                match answer with
                | .error (state, _, first) =>
                  -- A later use may have prepared the text again, and that name stays.
                  if stale pending.prepares first state && wire.names[pending.sql]? == some pending.name
                  then wire.names.erase pending.sql
                  else wire.names
                | .ok _ => wire.names
              set { wire with waiting := rest, names }
              return some pending
            | none =>
              return none
      if let some pending := next then
        pending.promise.resolve (.ok (answer.mapError fun (state, message, _) => ⟨state, message⟩))
    | .error error =>
      connection.fail error
      break
  connection.ended.resolve ()

/-- Connects and starts the task that reads results. -/
def Connection.connect (conninfo : String) (readOnly : Bool) (timeoutMs : UInt32)
    (maxPrepared : Nat := 256) : IO Connection := do
  let connection : Connection :=
    { raw := ← Raw.connect conninfo readOnly timeoutMs
      wire := ← Std.Mutex.new {}
      broken := ← IO.mkRef false
      ended := ← IO.Promise.new
      maxPrepared }
  discard <| BaseIO.asTask (prio := .dedicated) connection.read
  return connection

/-- Whether the connection can still take statements. -/
def Connection.usable (connection : Connection) : BaseIO Bool :=
  return !(← connection.broken.get)

/-- Sends `s` and waits for its answer without holding a thread. The first use of a SQL text
prepares it, and later uses run the prepared statement, so the server parses and plans the text
once for the session. -/
def Connection.ask (connection : Connection) (s : Statement) : Async Answer := do
  let promise ← IO.Promise.new
  let sent ←
    connection.wire.atomically do
        -- The queue's order must be the order on the wire, so both happen under one lock.
        let wire ← get
        let (name, prepares, wire) :=
          match wire.names[s.sql]? with
          | some name => (name, false, wire)
          | none =>
            if wire.names.size < connection.maxPrepared then
              let name := s!"espal{wire.next}"
              (name, true, { wire with names := wire.names.insert s.sql name, next := wire.next + 1 })
            else ("", false, wire)
        set { wire with waiting := wire.waiting.enqueue ⟨promise, s.sql, name, prepares⟩ }
        (connection.raw.send s.sql name prepares s.params).toBaseIO
  if let .error error := sent then
    connection.fail error
  Async.ofPromise (pure promise)

/-- Closes the connection and waits for its reading task to end. Statements that still wait
fail. A program that ended while that task ran would free the connection under it. -/
def Connection.close (connection : Connection) : IO Unit := do
  connection.raw.close
  discard <| IO.wait connection.ended.result?

end Espal.Postgres
