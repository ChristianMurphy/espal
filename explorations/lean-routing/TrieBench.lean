import Routing
import Std.Data.HashMap

/-!
Two indexes that pick the same route as lean-routing's first-match scan, timed against
`dispatchTable`: a segment trie, and a map from a route's first literal to the routes that start
with it. Each only chooses which routes to try; `Route.tryDispatch` then runs them, so the result
is the one the scan gives.
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

/-- Routes grouped by their first segment when it is a literal; the rest stay in order. -/
structure FirstIndex where
  byLit : Std.HashMap String (Array Nat) := {}
  rest : Array Nat := #[]

def buildIndex (routes : List (Route α)) : FirstIndex :=
  routes.zipIdx.foldl (init := {}) fun ix (r, i) =>
    match r.segs with
    | .lit s _ :: _ => { ix with byLit := ix.byLit.insert s ((ix.byLit.getD s #[]).push i) }
    | _ => { ix with rest := ix.rest.push i }

/-- Tries the routes in `a` and `b`, both ascending, in ascending order of index. -/
def firstOf (routes : Array (Route α)) (method : Std.Http.Method) (path : List String)
    (a b : Array Nat) : Nat → Nat → Nat → Option α
  | 0, _, _ => none
  | fuel + 1, i, j =>
    let next :=
      match a[i]?, b[j]? with
      | some x, some y => if x < y then some (x, i + 1, j) else some (y, i, j + 1)
      | some x, none => some (x, i + 1, j)
      | none, some y => some (y, i, j + 1)
      | none, none => none
    match next with
    | none => none
    | some (r, i', j') =>
      match routes[r]?.bind (·.tryDispatch method path) with
      | some v => some v
      | none => firstOf routes method path a b fuel i' j'

def indexDispatch (routes : Array (Route α)) (ix : FirstIndex) (method : Std.Http.Method)
    (path : List String) : Option α :=
  let a :=
    match path with
    | p :: _ => ix.byLit.getD p #[]
    | [] => #[]
  firstOf routes method path a ix.rest (a.size + ix.rest.size) 0 0

/-- `n` routes `/api/r<i>/:id:Nat` when `shared`, else `/r<i>/:id:Nat`. -/
def mkRoutes (shared : Bool) (n : Nat) : List (Route Nat) :=
  (List.range n).filterMap fun (i : Nat) =>
    let s := s!"r{i}"
    if h : dotSegment s = false then
      if shared then
        some
          { method := .get, segs := [.lit "api", .lit s h, .capture "id" .nat],
            handler := fun (_ : Nat) => i }
      else
        some
          { method := .get, segs := [.lit s h, .capture "id" .nat], handler := fun (_ : Nat) => i }
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
  IO.println
      "| Routes | Shape | Scan, hit | Index, hit | Trie, hit | Scan, miss | Index, miss | Trie, miss |"
  for (shape, shared) in [("own first literal", false), ("shared /api prefix", true)] do
    let pre := if shared then ["api"] else []
    for n in [10, 50, 200, 1000] do
      let list := mkRoutes shared n
      let arr := list.toArray
      let t := build list
      let ix := buildIndex list
      let hit := fun k => pre ++ [s!"r{n - 1}", toString (k % 100000)]
      let miss := fun k => pre ++ ["nothing", toString (k % 100000)]
      -- All three must pick the same route before their times mean anything.
      for k in [0:1000] do
        for path in [hit k, miss k] do
          let want := dispatchTable list .get path
          if want != trieDispatch arr t .get path || want != indexDispatch arr ix .get path then
            IO.eprintln s!"mismatch at {n} routes, {shape}"
            return 1
      let iters := 200000
      let (sh, _) ← time iters fun k => dispatchTable list .get (hit k)
      let (ih, _) ← time iters fun k => indexDispatch arr ix .get (hit k)
      let (th, _) ← time iters fun k => trieDispatch arr t .get (hit k)
      let (sm, _) ← time iters fun k => dispatchTable list .get (miss k)
      let (im, _) ← time iters fun k => indexDispatch arr ix .get (miss k)
      let (tm, _) ← time iters fun k => trieDispatch arr t .get (miss k)
      let f (x : Float) : String :=
        let c := (x * 100).round.toUInt64.toNat
        s!"{c / 100}.{if c % 100 < 10 then "0" else ""}{c % 100}"
      IO.println s!"| {n} | {shape} | {f sh} | {f ih} | {f th} | {f sm} | {f im} | {f tm} |"
  return 0
