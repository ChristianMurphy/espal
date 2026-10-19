import Routing

/-! Time to dispatch to the last of `n` routes, each `/r<i>/:id:Nat`. -/

open Routing

def mkRoutes (n : Nat) : List (Route Nat) :=
  (List.range n).filterMap fun i =>
    let s := s!"r{i}"
    if h : dotSegment s = false then
      some
        { method := .get, segs := [.lit s h, .capture "id" .nat],
          handler := fun (id : Nat) => id + i }
    else none

def main : IO Unit := do
  for n in [10, 50, 200] do
    let routes := mkRoutes n
    let iters := 200000
    let start ← IO.monoNanosNow
    let mut acc := 0
    for k in [0:iters] do
      if let some v := dispatchTable routes .get [s!"r{n - 1}", toString (k % 100000)] then
        acc := acc + v
    let stop ← IO.monoNanosNow
    let micros := (stop - start).toFloat / iters.toFloat / 1000.0
    IO.println s!"{n} routes: {micros} µs per dispatch (checksum {acc})"
