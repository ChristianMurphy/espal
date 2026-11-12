module

import EspalJson
meta import EspalJson
import EspalRoute
meta import EspalRoute

/-!
Tests for handlers that return programs. A handler in an `api` table reads the clock, draws random
numbers and logs, and `Api.reply?` runs the table against a supplied `World` with no server. The
link theorem of such a row equates programs.
-/

open Espal Routing Json

namespace ApiEffectsTests

structure Stamp where
  at_ : Int32
  roll : Int32
  deriving Json

inductive RollError where
  | conflict
  deriving Problem

def stamp (_ : Public) (sides : Nat) : Handler Text := do
  let t ← now
  let roll ← random 1 sides
  log s!"rolled {roll} of {sides}"
  return s!"{t} {roll}"

def lucky (_ : Public) (want : Nat) : Fails RollError Text := do
  let roll ← random 1 6
  if roll != want then
    log "unlucky"
    throw .conflict
  return "lucky"

def plain (_ : Public) : Text :=
  "plain"

api Game where
  GET "/stamp" => stamp
  GET "/lucky/:want" => lucky
  GET "/plain" => plain

/-- The status and text of `GET path` with `query`, against `world`. -/
def get (path : List String) (query : Query) (world : World) : Option (UInt16 × String) := do
  let reply ← Game.reply? .get path query none ByteArray.empty world
  return (reply.status, ← String.fromUTF8? reply.body)

/-! The same request gets each world's own answer. -/

#guard get ["stamp"] [("sides", "6")] { clock := 5, dice := [4] } == some (200, "5 4")

#guard get ["stamp"] [("sides", "6")] { clock := 9, dice := [2] } == some (200, "9 2")

/-! A refused query parameter answers at once, and the handler's program doesn't run. -/

#guard
  ((matchTable Game.routes .get ["stamp"]).map fun m =>
      ((m.2.reply [("sides", "x")] none .empty).eval { clock := 5, dice := [4] }).2) ==
    some { clock := 5, dice := [4] }

/-! A handler that fails after an effect keeps that effect, and answers with its error. -/

#guard (get ["lucky", "3"] [] { clock := 0, dice := [3] }).map (·.1) == some 200

#guard (get ["lucky", "3"] [] { clock := 0, dice := [5] }).map (·.1) == some 409

#guard
  ((matchTable Game.routes .get ["lucky", "3"]).map fun m =>
      ((m.2.reply [] none .empty).eval { clock := 0, dice := [5] }).2.logs) ==
    some ["unlucky"]

/-! A handler with no effects answers the same in every world. -/

#guard get ["plain"] [] { clock := 1 } == get ["plain"] [] { clock := 2, dice := [9] }

/-! The link theorem of an effectful row says the link runs the handler's own program. -/

/--
info: ApiEffectsTests.Game.linkTo_stamp (sides : Nat) (contentType : Option String) (bytes : ByteArray) :
  Option.map (fun m => m.snd.reply (linkTo stamp sides).query contentType bytes)
      (matchTable Game.routes Std.Http.Method.get (linkTo stamp sides).path) =
    some ((Endpoint.ofValue (stamp { } sides)).reply [] contentType bytes)
-/
#guard_msgs in
#check Game.linkTo_stamp

example (sides : Nat) (world : World) :
    (matchTable Game.routes .get (linkTo stamp sides).path).map
        (fun m => ((m.2.reply (linkTo stamp sides).query none .empty).eval world).2.logs) =
      some (world.logs ++ [s!"rolled {world.dice.headD 1} of {sides}"]) := by
  have h :=
    congrArg (Option.map fun program => (program.eval world).2.logs)
      (Game.linkTo_stamp sides none .empty)
  simp only [Option.map_map] at h
  refine Eq.trans h ?_
  simp [Endpoint.ofValue, ToAnswer.answer, stamp, Eff.eval_bind]

end ApiEffectsTests
