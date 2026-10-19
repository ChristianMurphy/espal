import Routing
import Std.Data.HashMap

/-!
A segment trie that picks the same route as lean-routing's first-match scan, timed against
`dispatchTable`. The trie only chooses a route index; `Route.tryDispatch` then runs that one route,
so the result is the one the scan gives.
-/

open Routing

structure Node where
  first : Option Nat := none
  lits : Std.HashMap String Nat := {}
  nat : Option Nat := none
  str : Option Nat := none

structure Trie where
  nodes : Array Node := #[{}]

def Trie.child (t : Trie) (at_ : Nat) (seg : PathSeg) : Trie × Nat :=
  let node := t.nodes[at_]?.getD {}
  let existing :=
    match seg with
    | .lit s _ => node.lits[s]?
    | .capture _ .nat => node.nat
    | .capture _ .string => node.str
  match existing with
  | some c => (t, c)
  | none =>
    let c := t.nodes.size
    let node :=
      match seg with
      | .lit s _ => { node with lits := node.lits.insert s c }
      | .capture _ .nat => { node with nat := some c }
      | .capture _ .string => { node with str := some c }
    ({ nodes := (t.nodes.setIfInBounds at_ node).push {} }, c)

def Trie.insert (t : Trie) (segs : List PathSeg) (index : Nat) : Trie :=
  let (t, last) := segs.foldl (fun (t, at_) seg => t.child at_ seg) (t, 0)
  let node := t.nodes[last]?.getD {}
  let first :=
    match node.first with
    | some i => some (min i index)
    | none => some index
  { nodes := t.nodes.setIfInBounds last { node with first } }

def minOpt : Option Nat → Option Nat → Option Nat
  | some a, some b => some (min a b)
  | a, none => a
  | none, b => b

/-- The lowest index of a route matching `path` from node `at_`, under `dispatch`'s rules. -/
def Trie.find (t : Trie) (at_ : Nat) : List String → Option Nat
  | [] => (t.nodes[at_]?.getD {}).first
  | p :: ps =>
    let node := t.nodes[at_]?.getD {}
    let viaLit := node.lits[p]? |>.bind (t.find · ps)
    let viaNat := if p.toNat?.isSome then node.nat.bind (t.find · ps) else none
    let viaStr := if unlinkable p then none else node.str.bind (t.find · ps)
    let below := minOpt viaLit (minOpt viaNat viaStr)
    if ps.isEmpty && p == "" then minOpt node.first below else below
termination_by path => path.length
decreasing_by all_goals simp_wf <;> omega

def build (routes : List (Route α)) : Trie :=
  (routes.zipIdx).foldl (fun t (r, i) => t.insert r.segs i) {}

def trieDispatch (routes : Array (Route α)) (t : Trie) (method : Std.Http.Method)
    (path : List String) : Option α :=
  (t.find 0 path).bind fun i => routes[i]?.bind (·.tryDispatch method path)

def mkRoutes (n : Nat) : List (Route Nat) :=
  (List.range n).filterMap fun i =>
    let s := s!"r{i}"
    if h : dotSegment s = false then
      some
        { method := .get, segs := [.lit s h, .capture "id" .nat],
          handler := fun (id : Nat) => id + i }
    else none

def time (iters : Nat) (f : Nat → Option Nat) : IO (Float × Nat) := do
  let start ← IO.monoNanosNow
  let mut acc := 0
  for k in [0:iters] do
    if let some v := f k then
      acc := acc + v
  let stop ← IO.monoNanosNow
  return ((stop - start).toFloat / iters.toFloat / 1000.0, acc)

def main : IO UInt32 := do
  for n in [10, 50, 200, 1000] do
    let list := mkRoutes n
    let arr := list.toArray
    let t := build list
    let hit := fun k => [s!"r{n - 1}", toString (k % 100000)]
    let miss := fun k => ["nothing", toString (k % 100000)]
    -- Both must pick the same route before their times mean anything.
    for k in [0:1000] do
      if
          dispatchTable list .get (hit k) != trieDispatch arr t .get (hit k) ||
            dispatchTable list .get (miss k) != trieDispatch arr t .get (miss k) then
        IO.eprintln s!"mismatch at {n} routes";
        return 1
    let iters := 200000
    let (scanHit, a) ← time iters fun k => dispatchTable list .get (hit k)
    let (trieHit, b) ← time iters fun k => trieDispatch arr t .get (hit k)
    let (scanMiss, _) ← time iters fun k => dispatchTable list .get (miss k)
    let (trieMiss, _) ← time iters fun k => trieDispatch arr t .get (miss k)
    IO.println
        s!"{n} routes: hit scan {scanHit} µs, trie {trieHit} µs; miss scan {scanMiss} µs, trie {trieMiss} µs (checks {a == b})"
  return 0
