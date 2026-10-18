import Std.Async

/-!
A fixed set of connections used in turn. A broken connection is replaced on its next use: one request
reconnects, and others that land on that slot fail fast until it finishes.
-/

namespace Spike.Pg

open Std Async

structure Slot where
  lookup : UInt32 → Async (UInt32 × UInt32)
  broken : BaseIO Bool

structure Pool where
  slots : Array (IO.Ref Slot)
  reconnecting : Array (IO.Ref Bool)
  connect : Async Slot
  next : IO.Ref Nat

def Pool.new (size : Nat) (connect : Async Slot) : Async Pool := do
  let slots ← (List.range size).toArray.mapM fun _ => do IO.mkRef (← connect)
  let reconnecting ← (List.range size).toArray.mapM fun _ => IO.mkRef false
  return { slots, reconnecting, connect, next := ← IO.mkRef 0 }

def Pool.query (p : Pool) (id : UInt32) : Async (UInt32 × UInt32) := do
  let i ← p.next.modifyGet fun n => (n % p.slots.size, n + 1)
  let (some ref, some busy) := (p.slots[i]?, p.reconnecting[i]?) | throw (IO.userError "empty pool")
  let slot ← ref.get
  unless ← slot.broken do return ← slot.lookup id
  let mine ← busy.modifyGet fun b => (!b, true)
  unless mine do throw (IO.userError "reconnecting")
  try
    let fresh ← p.connect
    ref.set fresh
    fresh.lookup id
  finally
    busy.set false

end Spike.Pg
