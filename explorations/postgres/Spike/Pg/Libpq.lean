import Std.Async

/-!
libpq in pipeline mode through a small C binding (`c/pq.c`). A dedicated task per connection waits for
results and resolves queries in order.
-/

namespace Spike.Pg

opaque PqPointed : NonemptyType
def Pq : Type := PqPointed.type
instance : Nonempty Pq := PqPointed.property

@[extern "espal_pq_connect"] opaque Pq.connect (conninfo sql : @& String) : IO Pq
@[extern "espal_pq_send"] opaque Pq.send (c : @& Pq) (id : UInt32) : IO Unit
@[extern "espal_pq_next"] opaque Pq.next (c : @& Pq) : IO UInt64

structure LibpqConn where
  pq : Pq
  pending : Std.Mutex (Std.Queue (IO.Promise (Except IO.Error UInt64)))
  broken : IO.Ref Bool

partial def LibpqConn.readerLoop (c : LibpqConn) : IO Unit := do
  let r ← c.pq.next.toBaseIO
  let next ← c.pending.atomically do
    match (← get).dequeue? with
    | some (p, q) => set q; return some p
    | none => return none
  if let some p := next then p.resolve r
  match r with
  | .ok _ => c.readerLoop
  | .error e =>
    c.broken.set true
    let rest ← c.pending.atomically do
      let q ← get
      set (∅ : Std.Queue (IO.Promise (Except IO.Error UInt64)))
      return q.toArray
    for p in rest do p.resolve (.error e)

def LibpqConn.connect (conninfo sql : String) : IO LibpqConn := do
  let c : LibpqConn := { pq := ← Pq.connect conninfo sql, pending := ← Std.Mutex.new ∅, broken := ← IO.mkRef false }
  discard <| IO.asTask (prio := .dedicated) c.readerLoop
  return c

/-- Looks up one `world` row, returning `(id, randomnumber)`. -/
def LibpqConn.query (c : LibpqConn) (id : UInt32) : Std.Async.Async (UInt32 × UInt32) := do
  if ← c.broken.get then throw (IO.userError "connection is broken")
  let p ← IO.Promise.new
  c.pending.atomically do
    modify (·.enqueue p)
    c.pq.send id
  let v ← Std.Async.Async.ofPromise (pure p)
  return ((v >>> 32).toUInt32, v.toUInt32)

end Spike.Pg
