module

import EspalCore
meta import EspalCore

/-!
Tests for effects as data. A handler built from `now`, `random` and `log` runs against a supplied
`World` with no `IO`, and against the machine with `Eff.run`.
-/

open Espal LeanLinq

namespace EffectTests

def greet (name : String) : Eff String := do
  let t ← now
  log s!"greeting {name} at {t}"
  if t % 2 == 0 then
    let roll ← random 1 6
    return s!"Hello, {name}! Roll {roll}."
  return s!"Hello, {name}! It is {t}."

/-! The same program gives each world its own answer, and the log records what it wrote. -/

#guard
  (greet "Ada").eval { clock := 7 } ==
    ("Hello, Ada! It is 7.", { clock := 7, logs := ["greeting Ada at 7"] })

#guard
  (greet "Ada").eval { clock := 8, dice := [5, 2] } ==
    ("Hello, Ada! Roll 5.", { clock := 8, dice := [2], logs := ["greeting Ada at 8"] })

/-! A draw with no number left gives its lower bound. -/

#guard ((greet "Ada").eval { clock := 8 }).1 == "Hello, Ada! Roll 1."

/-! `ExceptT` adds errors, and a failing handler runs none of the steps after the failure. -/

def greetNamed (name : String) : ExceptT String Eff String := do
  if name.isEmpty then
    throw "no name"
  let t ← now
  log "greeted"
  return s!"{name} {t}"

/-- A run's result, error and world, in a form `#guard` can compare. -/
def shown (run : Except String String × World) : Option String × Option String × World :=
  match run with
  | (.ok value, world) => (some value, none, world)
  | (.error message, world) => (none, some message, world)

#guard
  shown ((greetNamed "Bo").run.eval { clock := 3 }) ==
    (some "Bo 3", none, { clock := 3, logs := ["greeted"] })

#guard shown ((greetNamed "").run.eval { clock := 3 }) == (none, some "no name", { clock := 3 })

/-! `Eff.eval_bind` lets a proof follow a program step by step. -/

def twoLines : Eff Unit := do
  log "a"
  log "b"

example (world : World) : (twoLines.eval world).2.logs = world.logs ++ ["a", "b"] := by
  simp [twoLines, Eff.eval_bind]

/-! The machine answers the same program through `Eff.run`. -/

#eval
  show IO Unit from do
    let (t, roll) ←
      (do
            let t ← now
            let roll ← random 3 3
            return (t, roll) : Eff (Nat × Nat)).run
    unless t > 1700000000000 && roll == 3 do
      throw (IO.userError s!"the machine answered {t} and {roll}")

end EffectTests
