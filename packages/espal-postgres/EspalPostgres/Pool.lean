/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.EffectRun
public import EspalCore.Secret
public import EspalPostgres.Connection

/-!
# The connection pool

A `Pool` holds two sets of connections. A `query` goes to a read-only session, where Postgres
refuses a statement that writes with SQLSTATE `25006`. A `statement` goes to an ordinary session.
So the claim that a `GET` handler only reads holds for the SQL text too, enforced by the server.

Each statement takes the next connection in turn. A connection that was lost is replaced by the
next handler that reaches its slot, and handlers that reach the slot meanwhile wait for the new
connection. The statements that were on the lost connection fail, and the pool doesn't send them
again, since a write may already have run.

Postgres cancels a statement that runs past the pool's time limit. The limit is the server's, so
it doesn't cover a network that stops answering. libpq's keepalive settings in the connection
string cover that.

Each statement commits on its own. A `query` and a `statement` in one request use different
sessions, which a transaction can't span, so transactions need another design.
-/

public section

namespace Espal.Postgres

open Std.Async

/-- One place in the pool, which holds a connection once a handler has needed it. -/
abbrev Slot :=
  Std.Mutex (Option Connection)

/-- Connections to one Postgres server, for reads and for writes. -/
structure Pool where
  /-- How to connect, as a libpq connection string. It may hold a password. -/
  conninfo : Secret String
  /-- The read-only sessions that `query` uses. -/
  readers : Array Slot
  /-- The sessions that `statement` uses. -/
  writers : Array Slot
  /-- Counts statements, to take connections in turn. -/
  turn : IO.Ref Nat
  /-- The most milliseconds one statement may run before Postgres cancels it. Zero sets no limit. -/
  timeoutMs : UInt32

/-- The connection in `slot`, replaced first if it was lost. Other handlers wait meanwhile. -/
def Pool.connection (pool : Pool) (slot : Slot) (readOnly : Bool) : IO Connection := do
  let found ←
    slot.atomically do
        if let some connection := (← get) then
          if ← connection.usable then
            return Except.ok connection
        match ← (Connection.connect pool.conninfo.reveal readOnly pool.timeoutMs).toBaseIO with
        | .ok connection =>
          set (some connection)
          return .ok connection
        | .error error =>
          return .error error
  IO.ofExcept found

/-- Runs `s` on the next connection of `slots`. A refusal by the server is an error that holds its
SQLSTATE code. -/
def Pool.run (pool : Pool) (slots : Array Slot) (readOnly : Bool) (s : Statement) : Async Rows := do
  let turn ← pool.turn.modifyGet fun n => (n, n + 1)
  let some slot := slots[turn % slots.size]?
    | throw (IO.userError "the pool has no connections")
  let connection ← pool.connection slot readOnly
  match ← connection.ask s with
  | .ok rows =>
    return rows
  | .error refusal =>
    throw (IO.userError s!"Postgres refused a statement ({refusal.state}): {refusal.message}")

/-- Connects `size` read-only sessions and `size` ordinary ones. It fails when the server can't be
reached, so a wrong connection string stops the program at startup. Postgres cancels a statement
that runs longer than `timeoutMs` milliseconds, with SQLSTATE `57014`, and the session stays
usable. The default is the five seconds a request gets. -/
def Pool.connect (conninfo : Secret String) (size : Nat := 4) (timeoutMs : UInt32 := 5000) :
    IO Pool := do
  let fill (readOnly : Bool) : IO (Array Slot) :=
    (Array.range (max size 1)).mapM fun _ => do
      Std.Mutex.new (some (← Connection.connect conninfo.reveal readOnly timeoutMs))
  return { conninfo, readers := ← fill true, writers := ← fill false, turn := ← IO.mkRef 0,
           timeoutMs }

/-- The `Database` that sends `query` to the read-only sessions and `statement` to the others. -/
def Pool.database (pool : Pool) : Database :=
  { query := pool.run pool.readers true
    statement := pool.run pool.writers false }

/-- Closes every connection and waits for their tasks to end. A program calls it before it ends,
since each connection has a task that would otherwise keep the process alive. -/
def Pool.close (pool : Pool) : IO Unit := do
  for slot in pool.readers ++ pool.writers do
    let held ←
      slot.atomically do
          let held ← get
          set (none : Option Connection)
          return held
    if let some connection := held then
      connection.close

end Espal.Postgres
