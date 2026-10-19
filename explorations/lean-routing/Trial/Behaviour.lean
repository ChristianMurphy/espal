import Routing

/-! Behaviours the trial write-up reports, checked when the package builds. -/

open Routing

route_table App
  [ userByName := "/users/:name:String",
    newUser := "/users/new",
    user := "/users/:id:Nat" ]

def routes : List (Route String) :=
  [ .get App.patterns.userByName (fun (name : String) => s!"name {name}"),
    .get App.patterns.newUser "new",
    .get App.patterns.user (fun (id : Nat) => s!"id {id}") ]

-- The first route takes both paths, so the other two never run, and nothing reports it.
#guard dispatchTable routes .get ["users", "new"] == some "name new"

#guard dispatchTable routes .get ["users", "42"] == some "name 42"

def userId (path : List String) : Option Nat :=
  dispatch App.patterns.user (fun (id : Nat) => id) path

-- One user answers at several paths.
#guard userId ["users", "42"] == some 42

#guard userId ["users", "0042"] == some 42

#guard userId ["users", "4_2"] == some 42

#guard userId ["users", "+42"] == none

-- Links use the shortest spelling.
#guard App.links.user 42 == "/users/42"

-- Two rows may share a pattern.
route_table Twice
  [ a := "/x/:id:Nat",
    b := "/x/:n:Nat" ]

#guard Twice.links.a 1 == Twice.links.b 1
