/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Effect

/-!
# The libpq binding

Four C functions in `c/pq.c` drive one libpq connection in pipeline mode. `send` writes a
statement without waiting for its result, and `next` blocks until the next result is complete.
Results come back in the order the statements were sent. `send` can prepare a statement under a
name and run it by that name later, so the server parses and plans its text once.

Lean never checks this code. `lake exe postgres-test` runs it against a real server.

A parameter travels as text beside the SQL, never inside it, and libpq's extended protocol takes
one statement per call. A parameter or SQL text that holds a NUL byte is cut at it, as a C string
is.
-/

public section

namespace Espal.Postgres

/-- The type behind `Raw`, which only the C code can build. -/
opaque RawPointed : NonemptyType

/-- A libpq connection in pipeline mode. -/
def Raw : Type :=
  RawPointed.type

instance : Nonempty Raw :=
  RawPointed.property

/-- A statement that the server refused, with its SQLSTATE code and its message. -/
structure Refusal where
  /-- The five-character SQLSTATE code, such as `25006` for a write in a read-only transaction. -/
  state : String
  /-- The server's primary message. -/
  message : String
  deriving Repr, BEq, DecidableEq

/-- Connects with `conninfo`. A read-only session refuses every statement that writes. The server
cancels a statement that runs longer than `timeoutMs` milliseconds, unless that is zero. -/
@[extern "espal_pq_connect"]
opaque Raw.connect (conninfo : @& String) (readOnly : Bool) (timeoutMs : UInt32) : IO Raw

/-- Sends one statement and returns without its result. With an empty `name` the server parses
`sql` for this one use. With a name it runs the prepared statement of that name, and `prepare`
says to prepare it from `sql` first, in the same batch. -/
@[extern "espal_pq_send"]
opaque Raw.send (raw : @& Raw) (sql name : @& String) (prepare : Bool) (params : @& Array String) :
    IO Unit

/-- Waits for the next statement's answer, in the order the statements were sent. A refusal holds
the SQLSTATE code, the message, and whether no step of the statement had succeeded, which means a
prepare sent with it failed. It fails when the connection is lost or closed. -/
@[extern "espal_pq_next"]
opaque Raw.next (raw : @& Raw) : IO (Except (String × String × Bool) Rows)

/-- Closes the connection to new statements and wakes a task that waits in `next`. -/
@[extern "espal_pq_close"]
opaque Raw.close (raw : @& Raw) : IO Unit

end Espal.Postgres
