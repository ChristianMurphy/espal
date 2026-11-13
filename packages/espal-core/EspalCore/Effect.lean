/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Graded.Freer

/-!
# Effects as data

A handler asks for the time, a random number, a log line or a database statement by returning a
program. It has no `IO` access. An interpreter answers each request, so the same program runs
against the real world or against a `World` that a test supplies.

`Eff α` is such a program. It is a monad, so handlers use `do` notation. `Eff.eval` runs one
against a `World`, and the `Eff.eval_` theorems say how that run follows the program's steps. A
handler's result therefore depends only on the program and on what the `World` answers.

`Costs x n` says that `x` sends at most `n` statements on every path. The `budget` tactic proves
it by following the program's structure, and `Costs.sent_le` shows that a run against any `World`
stays within a proved bound.

The program type is lean-linq's `FreerD`, copied into `EspalCore.Graded`. lean-linq carries a cost
bound in the program's type. Espal leaves that index empty and proves `Costs` beside the handler,
so `Eff` is an ordinary monad.

`Eff` has no `LawfulMonad` instance. The two sides of a monad law evaluate to the same result, by
`Eff.eval_bind`, but they are different program values.
-/

@[expose] public section

namespace Espal

open LeanLinq

/-! ## Folding a sequence -/

/-- Running `x` and then `k` on its result gives what running their sequence gives. -/
theorem foldSt_bindS {E : Type → Type 1} {spec : EffWp E} {ε S : Type}
    (h : {β : Type} → E β → S → Except ε (β × S)) {α β : Type} {w₂ : α → Wp β} :
    {w : Wp α} →
      (x : FreerD E spec α w) →
      (k : (a : α) → FreerD E spec β (w₂ a)) →
      (s : S) →
      FreerD.foldSt h (FreerD.bindS x k) s =
        (FreerD.foldSt h x s).bind fun r => FreerD.foldSt h (k r.1) r.2
  | _, .pure _, _, _ => rfl
  | _, .bindE e f, k, s => by
    simp only [FreerD.bindS, FreerD.foldSt]
    cases h e s with
    | error err => rfl
    | ok r => exact foldSt_bindS h (f r.1) k r.2
  | _, .weaken _ x, k, s => by
    simp only [FreerD.bindS, FreerD.foldSt]
    exact foldSt_bindS h x k s

/-! ## The operations a handler may ask for -/

/-- One database statement, as SQL text and its bind parameters. -/
structure Statement where
  /-- The SQL text, with a placeholder for each parameter. -/
  sql : String
  /-- The value of each parameter, in order. -/
  params : Array String := #[]
  deriving Repr, BEq, DecidableEq, Inhabited

/-- The rows a statement returns. Each cell is text, or `none` for a null. -/
abbrev Rows :=
  Array (Array (Option String))

/-- What a handler may ask for. The index is the type of the answer. -/
inductive Op : Type → Type 1 where
  /-- The time, in milliseconds since the Unix epoch. -/
  | now : Op Nat
  /-- A random number, asked for between `lo` and `hi`. -/
  | random (lo hi : Nat) : Op Nat
  /-- Writes one line to the log. -/
  | log (line : String) : Op Unit
  /-- Sends one statement that only reads to the database. -/
  | query (s : Statement) : Op Rows
  /-- Sends one statement that may write to the database. -/
  | statement (s : Statement) : Op Rows

/-- What an operation costs. A statement costs one, whether it reads or writes, and the others
cost nothing. -/
def Op.cost : {β : Type} → Op β → Nat
  | _, .query _ => 1
  | _, .statement _ => 1
  | _, _ => 0

/-- Whether an operation leaves the database as it was. Only `statement` may change it. -/
def Op.reads : {β : Type} → Op β → Bool
  | _, .statement _ => false
  | _, _ => true

/-- The spec of every operation is empty, since `Costs` holds the bound. -/
def opWp : EffWp Op := fun _ => Wp.triv _

/-- A program that may read the clock, draw random numbers, log and send statements. -/
def Eff (α : Type) : Type 1 :=
  FreerD Op opWp α (Wp.triv α)

/-- The program that asks for `e` and returns its answer. -/
def Eff.lift {β : Type} (e : Op β) : Eff β :=
  FreerD.weaken (fun _ _ _ h => h.elim) (FreerD.liftE e)

instance : Monad Eff where
  pure a := FreerD.weaken (fun _ _ _ h => h.elim) (.pure a)
  bind x k := FreerD.bindS x k

/-- The time, in milliseconds since the Unix epoch. -/
def now : Eff Nat :=
  .lift .now

/-- A random number, asked for between `lo` and `hi`. -/
def random (lo hi : Nat) : Eff Nat :=
  .lift (.random lo hi)

/-- Writes `line` to the log. -/
def log (line : String) : Eff Unit :=
  .lift (.log line)

/-- Sends `s` to the database and returns its rows. `s` must only read. A handler behind a `GET`
row may send statements this way and no other. -/
def query (s : Statement) : Eff Rows :=
  .lift (.query s)

/-- Sends `s` to the database and returns its rows. `s` may write. -/
def statement (s : Statement) : Eff Rows :=
  .lift (.statement s)

/-! ## Running against a supplied world -/

/-- What the outside answers during one request. -/
structure World where
  /-- The time every `now` reads. -/
  clock : Nat
  /-- The numbers `random` draws, in order. Once they run out, a draw gives its lower bound. -/
  dice : List Nat := []
  /-- The lines logged so far, oldest first. -/
  logs : List String := []
  /-- The rows the next statements get, in order. Once they run out, a statement gets none. -/
  rows : List Rows := []
  /-- The statements sent so far, oldest first. -/
  sent : List Statement := []
  /-- The statements sent so far that may write, oldest first. -/
  written : List Statement := []
  deriving Repr, BEq, DecidableEq

/-- The answer of `world` to one operation, and the world after it. -/
def Op.answer : {β : Type} → Op β → World → β × World
  | _, .now, world => (world.clock, world)
  | _, .random lo _, world => (world.dice.headD lo, { world with dice := world.dice.tail })
  | _, .log line, world => ((), { world with logs := world.logs ++ [line] })
  | _, .query s, world =>
    (world.rows.headD #[],
      { world with
        rows := world.rows.tail, sent := world.sent ++ [s] })
  | _, .statement s, world =>
    (world.rows.headD #[],
      { world with
        rows := world.rows.tail, sent := world.sent ++ [s], written := world.written ++ [s] })

/-- The result of a program with any index against `world`, and the world after it. -/
def run {α : Type} {w : Wp α} (x : FreerD Op opWp α w) (world : World) : α × World :=
  match FreerD.foldSt (ε := Empty) (fun e s => .ok (Op.answer e s)) x world with
  | .ok result => result

/-- A sequence runs its first part, then the rest on that result and that world. -/
theorem run_bindS {α β : Type} {w : Wp α} {w₂ : α → Wp β} (x : FreerD Op opWp α w)
    (k : (a : α) → FreerD Op opWp β (w₂ a)) (world : World) :
    run (FreerD.bindS x k) world = run (k (run x world).1) (run x world).2 := by
  unfold run
  rw [foldSt_bindS]
  cases FreerD.foldSt (ε := Empty) (fun e s => .ok (Op.answer e s)) x world with
  | error e => exact e.elim
  | ok r => rfl

/-- The result of `x` against `world`, and the world after it. -/
def Eff.eval {α : Type} (x : Eff α) (world : World) : α × World :=
  run x world

/-- The result of `x` against `world`, without the world after it. Tests read a reply this way. -/
def Eff.value {α : Type} (x : Eff α) (world : World := { clock := 0 }) : α :=
  (x.eval world).1

/-- A program that only returns a value leaves the world as it was. -/
@[simp]
theorem Eff.eval_pure {α : Type} (a : α) (world : World) :
    (pure a : Eff α).eval world = (a, world) :=
  rfl

/-- `now` reads the world's clock. -/
@[simp]
theorem Eff.eval_now (world : World) : now.eval world = (world.clock, world) :=
  rfl

/-- `random` takes the next number, or its lower bound once none is left. -/
@[simp]
theorem Eff.eval_random (lo hi : Nat) (world : World) :
    (random lo hi).eval world = (world.dice.headD lo, { world with dice := world.dice.tail }) :=
  rfl

/-- `log` adds its line after the lines already logged. -/
@[simp]
theorem Eff.eval_log (line : String) (world : World) :
    (log line).eval world = ((), { world with logs := world.logs ++ [line] }) :=
  rfl

/-- `query` takes the next rows, or none once none are left, and records what it sent. -/
@[simp]
theorem Eff.eval_query (s : Statement) (world : World) :
    (query s).eval world =
      (world.rows.headD #[],
        { world with
          rows := world.rows.tail, sent := world.sent ++ [s] }) :=
  rfl

/-- `statement` does what `query` does, and also records its statement as one that may write. -/
@[simp]
theorem Eff.eval_statement (s : Statement) (world : World) :
    (statement s).eval world =
      (world.rows.headD #[],
        { world with
          rows := world.rows.tail, sent := world.sent ++ [s], written := world.written ++ [s] }) :=
  rfl

/-- A sequence runs its first part, then the rest on that result and that world. -/
theorem Eff.eval_bind {α β : Type} (x : Eff α) (f : α → Eff β) (world : World) :
    (x >>= f).eval world = (f (x.eval world).1).eval (x.eval world).2 :=
  run_bindS x f world

/-- Mapping a function over a program applies it to the result and leaves the world alone. -/
@[simp]
theorem Eff.eval_map {α β : Type} (f : α → β) (x : Eff α) (world : World) :
    (f <$> x).eval world = (f (x.eval world).1, (x.eval world).2) := by
  show (x >>= fun a => pure (f a)).eval world = _
  rw [Eff.eval_bind]
  rfl

end Espal
