import Routing

/-!
Times `RouteIndex.matchTable`, the trie, against `matchTable`, the scan, after checking that both
pick the same route. Prints one row per table, in microseconds, for the first route, the last
route and a path that matches nothing; then the time to build the index.
-/

open Routing

/-- `n` patterns `/api/r<i>/:id:Nat` when `shared`, else `/r<i>/:id:Nat`, each as a `POST` then a `GET`. -/
def mkRoutes (shared : Bool) (n : Nat) : List (Route Nat) :=
  (List.range n).flatMap fun (i : Nat) =>
    let s := s!"r{i}"
    if h : dotSegment s = false then
      if shared then
        [{ method := .post, segs := [.lit "api", .lit s h, .capture "id" .nat],
           handler := fun (_ : Nat) => i + 1000000 },
         { method := .get, segs := [.lit "api", .lit s h, .capture "id" .nat],
           handler := fun (_ : Nat) => i }]
      else
        [{ method := .post, segs := [.lit s h, .capture "id" .nat],
           handler := fun (_ : Nat) => i + 1000000 },
         { method := .get, segs := [.lit s h, .capture "id" .nat], handler := fun (_ : Nat) => i }]
    else []

def time (iters : Nat) (f : Nat → Option α) : IO Float := do
  let start ← IO.monoNanosNow
  let mut hits := 0
  for k in [0:iters] do
    if (f k).isSome then hits := hits + 1
  let stop ← IO.monoNanosNow
  if hits == 12345678 then IO.println "unlikely"
  return (stop - start).toFloat / iters.toFloat / 1000.0

def fmt (x : Float) : String :=
  let c := (x * 100).round.toUInt64.toNat
  s!"{c / 100}.{if c % 100 < 10 then "0" else ""}{c % 100}"

def main : IO UInt32 := do
  for (shape, shared) in [("own first literal", false), ("shared /api prefix", true)] do
    let pre := if shared then ["api"] else []
    for n in [10, 100, 1000] do
      let list := mkRoutes shared n
      let index := RouteIndex.of list
      let first := fun k => pre ++ ["r0", toString (k % 100000)]
      let last := fun k => pre ++ [s!"r{n - 1}", toString (k % 100000)]
      let miss := fun k => pre ++ ["nothing", toString (k % 100000)]
      for k in [0:2000] do
        for path in [first k, last k, miss k, pre ++ [s!"r{k % n}", "x"], pre ++ [s!"r{k % n}", "1", ""]] do
          for m in [Std.Http.Method.get, .post, .put] do
            if (matchTable list m path).map (·.2) != (index.matchTable m path).map (·.2) then
              IO.eprintln s!"mismatch at {n} routes, {shape}, {path}"
              return 1
      let iters := 200000
      let mut row := s!"{2 * n}|{shape}"
      for path in [first, last, miss] do
        let sc ← time iters fun k => matchTable list .get (path k)
        let tr ← time iters fun k => index.matchTable .get (path k)
        row := row ++ s!"|{fmt sc}|{fmt tr}"
      IO.println row
  for n in [10, 100, 1000] do
    let lists := [mkRoutes false n, (mkRoutes false n).reverse]
    let start ← IO.monoNanosNow
    let mut acc := 0
    for k in [0:200] do
      acc := acc + (RouteIndex.of (lists[k % 2]?.getD [])).routes.size
    let stop ← IO.monoNanosNow
    IO.println s!"build|{2 * n}|{fmt ((stop - start).toFloat / 200.0 / 1000.0)}|{acc % 2}"
  return 0
