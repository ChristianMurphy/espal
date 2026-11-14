/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalPostgres.Libpq
import Init.While
public import Std.Async
public import Std.Sync.Mutex

/-!
# One pipelined connection

A `Connection` sends each statement as soon as a handler asks, without waiting for the results of
earlier ones. One task per connection waits for results and hands each to the handler that sent
its statement, in order.

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

/-- A connection with the statements that still wait for a result. -/
structure Connection where
  /-- The libpq connection. -/
  raw : Raw
  /-- A promise for each statement sent and not yet answered, oldest first. -/
  waiting : Std.Mutex (Std.Queue (IO.Promise (Except IO.Error Answer)))
  /-- Whether the connection was lost or closed. -/
  broken : IO.Ref Bool
  /-- Resolved when the task that reads results has ended. -/
  ended : IO.Promise Unit

/-- Fails every waiting statement with `error`, and marks the connection broken. -/
def Connection.fail (connection : Connection) (error : IO.Error) : BaseIO Unit := do
  connection.broken.set true
  let stranded ←
    connection.waiting.atomically do
        let queue ← get
        set (∅ : Std.Queue (IO.Promise (Except IO.Error Answer)))
        return queue.toArray
  for promise in stranded do
    promise.resolve (.error error)

/-- Hands each result to the oldest waiting statement, until the connection is lost or closed. -/
def Connection.read (connection : Connection) : BaseIO Unit := do
  repeat
    match ← connection.raw.next.toBaseIO with
    | .ok answer =>
      let next ←
        connection.waiting.atomically do
            match (← get).dequeue? with
            | some (promise, rest) =>
              set rest
              return some promise
            | none =>
              return none
      if let some promise := next then
        promise.resolve (.ok (answer.mapError fun (state, message) => ⟨state, message⟩))
    | .error error =>
      connection.fail error
      break
  connection.ended.resolve ()

/-- Connects and starts the task that reads results. -/
def Connection.connect (conninfo : String) (readOnly : Bool) : IO Connection := do
  let connection : Connection :=
    { raw := ← Raw.connect conninfo readOnly
      waiting := ← Std.Mutex.new ∅
      broken := ← IO.mkRef false
      ended := ← IO.Promise.new }
  discard <| BaseIO.asTask (prio := .dedicated) connection.read
  return connection

/-- Whether the connection can still take statements. -/
def Connection.usable (connection : Connection) : BaseIO Bool :=
  return !(← connection.broken.get)

/-- Sends `s` and waits for its answer without holding a thread. -/
def Connection.ask (connection : Connection) (s : Statement) : Async Answer := do
  let promise ← IO.Promise.new
  let sent ←
    connection.waiting.atomically do
        -- The queue's order must be the order on the wire, so both happen under one lock.
        modify (·.enqueue promise)
        (connection.raw.send s.sql s.params).toBaseIO
  if let .error error := sent then
    connection.fail error
  Async.ofPromise (pure promise)

/-- Closes the connection and waits for its reading task to end. Statements that still wait
fail. A program that ended while that task ran would free the connection under it. -/
def Connection.close (connection : Connection) : IO Unit := do
  connection.raw.close
  discard <| IO.wait connection.ended.result?

end Espal.Postgres
