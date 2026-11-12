/-
Copyright (c) 2026 Christian Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Christian Murphy
-/
module

public import EspalCore.Graded.Freer

/-!
# Effects as data

A handler asks for the time, a random number or a log line by returning a program. It has no
`IO` access. An interpreter answers each request, so the same program runs against the real world
or against a `World` that a test supplies.

`Eff α` is a program that sends no database statement. It is a monad, so handlers use `do`
notation. `Eff.eval` runs one against a `World`, and `Eff.eval_pure` and `Eff.eval_bind` say how
that run follows the program's steps. A handler's result therefore depends only on the program and
on what the `World` answers.

The program type is lean-linq's `FreerD`, copied into `EspalCore.Graded`. Its type carries an
upper bound on cost. lean-linq charges every operation one unit, and Espal charges only database
statements. So `runCost` takes the cost of each operation, and `runCost_cost_le` shows that a run
stays within the bound in the program's type.

`Eff` has no `LawfulMonad` instance. The two sides of a monad law evaluate to the same result, by
`Eff.eval_bind`, but they are different program values.
-/

@[expose] public section

namespace Espal

open LeanLinq

/-! ## Running a program at a cost for each operation -/

/-- A handler for each operation of `E`, over a state `S` that `obs` observes. Each run meets the
operation's spec and spends the operation's `cost`. -/
def CostHandler (E : Type → Type 1) (spec : EffWp E) (cost : {β : Type} → E β → Nat) (ε S : Type)
    (obs : S → (String → Nat)) : Type 1 :=
  {β : Type} →
    (e : E β) →
    (s : S) → Except ε { p : β × S // ∀ k, (spec e).sp p.1 (obs s) k (obs p.2) (k + cost e) }

/-- Runs `x` from state `s` with `h`. The result holds the value, the final state and the cost
spent, with a proof that they meet the program's spec. -/
def runCost {E : Type → Type 1} {spec : EffWp E} {cost : {β : Type} → E β → Nat} {ε S : Type}
    {obs : S → (String → Nat)} (h : CostHandler E spec cost ε S obs) :
    {α : Type} →
      {w : Wp α} →
      FreerD E spec α w →
        (s : S) → Except ε { p : α × S × Nat // ∀ k₀, w.sp p.1 (obs s) k₀ (obs p.2.1) (k₀ + p.2.2) }
  | _, _, .pure a, s => .ok ⟨(a, s, 0), fun _ _ hp => hp⟩
  | _, _, .bindE e f, s => do
    let ⟨(b, s₁), he⟩ ← h e s
    let ⟨(a₂, s₂, n), hf⟩ ← runCost h (f b) s₁
    .ok
        ⟨(a₂, s₂, cost e + n), fun k₀ => by
          have hcomp := hf (k₀ + cost e)
          rw [Nat.add_assoc] at hcomp
          exact fun post hw => hcomp post (he k₀ _ hw)⟩
  | _, _, .weaken hle x, s => do
    let ⟨p, hp⟩ ← runCost h x s
    .ok ⟨p, fun k₀ post hw => hp k₀ post (hle post _ _ hw)⟩

/-- A program whose type carries the bound `r` spends at most `r`, under any handler that meets
each operation's spec at its cost. -/
theorem runCost_cost_le {E : Type → Type 1} {spec : EffWp E} {cost : {β : Type} → E β → Nat}
    {ε S : Type} {obs : S → (String → Nat)} {h : CostHandler E spec cost ε S obs} {r : Grade}
    {α : Type} {x : FreerD E spec α (Wp.bill r)} {s : S}
    {res : { p : α × S × Nat // ∀ k₀, (Wp.bill r).sp p.1 (obs s) k₀ (obs p.2.1) (k₀ + p.2.2) }}
    (_hrun : runCost h x s = .ok res) : res.val.2.2 ≤ r.eval (obs s) := by
  have hsp := res.property 0
  have := hsp (fun _ _ k => k ≤ r.eval (obs s)) fun a σ' k' hk => by omega
  omega

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

/-- What a handler may ask for. The index is the type of the answer. -/
inductive Op : Type → Type 1 where
  /-- The time, in milliseconds since the Unix epoch. -/
  | now : Op Nat
  /-- A random number, asked for between `lo` and `hi`. -/
  | random (lo hi : Nat) : Op Nat
  /-- Writes one line to the log. -/
  | log (line : String) : Op Unit

/-- What each operation promises. None of them sends a statement, so none spends anything. The
spec of `random` says nothing about its bounds. -/
def opWp : EffWp Op
  | _, .now => fun post σ k => ∀ n, post n σ k
  | _, .random _ _ => fun post σ k => ∀ n, post n σ k
  | _, .log _ => fun post σ k => post () σ k

/-- Each of them fits a bound of zero. -/
theorem opWp_free {β : Type} (e : Op β) : (opWp e).le (Wp.bill 0) := by
  cases e <;> intro post σ k h <;>
    first
    | (intro n; exact h n σ k (by simp))
    | exact h () σ k (by simp)

/-- A program that may read the clock, draw random numbers and log, and that sends no database
statement. -/
def Eff (α : Type) : Type 1 :=
  FreerD Op opWp α (Wp.bill 0)

/-- The program that asks for `e` and returns its answer. -/
def Eff.lift {β : Type} (e : Op β) : Eff β :=
  FreerD.weaken (opWp_free e) (FreerD.liftE e)

instance : Monad Eff where
  pure a := FreerD.weaken (Wp.bill_pure a 0) (.pure a)
  bind x k :=
    FreerD.weaken (Wp.bill_bind_of_le (Wp.le_refl _) (fun _ => Wp.le_refl _) (Grade.stable_nat 0))
      (FreerD.bindS x k)

/-- The time, in milliseconds since the Unix epoch. -/
def now : Eff Nat :=
  .lift .now

/-- A random number, asked for between `lo` and `hi`. -/
def random (lo hi : Nat) : Eff Nat :=
  .lift (.random lo hi)

/-- Writes `line` to the log. -/
def log (line : String) : Eff Unit :=
  .lift (.log line)

/-! ## Running against a supplied world -/

/-- What the outside answers during one request. -/
structure World where
  /-- The time every `now` reads. -/
  clock : Nat
  /-- The numbers `random` draws, in order. Once they run out, a draw gives its lower bound. -/
  dice : List Nat := []
  /-- The lines logged so far, oldest first. -/
  logs : List String := []
  deriving Repr, BEq, DecidableEq

/-- The answer of `world` to one operation, and the world after it. -/
def Op.answer : {β : Type} → Op β → World → β × World
  | _, .now, world => (world.clock, world)
  | _, .random lo _, world => (world.dice.headD lo, { world with dice := world.dice.tail })
  | _, .log line, world => ((), { world with logs := world.logs ++ [line] })

/-- The result of `x` against `world`, and the world after it. -/
def Eff.eval {α : Type} (x : Eff α) (world : World) : α × World :=
  match FreerD.foldSt (ε := Empty) (fun e s => .ok (Op.answer e s)) x world with
  | .ok result => result

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

/-- A sequence runs its first part, then the rest on that result and that world. -/
theorem Eff.eval_bind {α β : Type} (x : Eff α) (f : α → Eff β) (world : World) :
    (x >>= f).eval world = (f (x.eval world).1).eval (x.eval world).2 := by
  show Eff.eval (FreerD.weaken _ (FreerD.bindS x f)) world = _
  unfold Eff.eval
  simp only [FreerD.foldSt]
  have hb := foldSt_bindS (spec := opWp) (ε := Empty) (fun e s => .ok (Op.answer e s)) x f world
  rw [hb]
  cases FreerD.foldSt (ε := Empty) (fun e s => .ok (Op.answer e s)) x world with
  | error e => exact e.elim
  | ok r => rfl

/-- Mapping a function over a program applies it to the result and leaves the world alone. -/
@[simp]
theorem Eff.eval_map {α β : Type} (f : α → β) (x : Eff α) (world : World) :
    (f <$> x).eval world = (f (x.eval world).1, (x.eval world).2) := by
  show (x >>= fun a => pure (f a)).eval world = _
  rw [Eff.eval_bind]
  rfl

end Espal
