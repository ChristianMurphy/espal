module

import EspalJson
meta import EspalJson
import EspalRoute
meta import EspalRoute

/-!
Tests for `Api.allowed`, which lists the methods that a path answers. The server puts the list in
the `Allow` header of a `405`, and answers `404` when it is empty.
-/

open Espal Routing Json

namespace ApiMethodTests

structure Note where
  text : String
  deriving Json

def listNotes (_ : Public) : Text :=
  "notes"

def addNote (_ : Public) (note : Note) : Note :=
  note

def showNote (_ : Public) (id : Nat) : Text :=
  s!"note {id}"

def dropNote (_ : Public) (id : Nat) : Text :=
  s!"dropped {id}"

def showDraft (_ : Public) : Text :=
  "draft"

api Notes where
  GET "/notes" => listNotes
  POST "/notes" => addNote
  GET "/notes/draft" => showDraft
  GET "/notes/:id" => showNote
  DELETE "/notes/:id" => dropNote

/-! Each method appears once, in the order of its first row. -/

#guard Notes.allowed ["notes"] == [.get, .post]

#guard Notes.allowed ["notes", "7"] == [.get, .delete]

/-! A path that only one row's pattern accepts lists only that row's method. -/

#guard Notes.allowed ["notes", "draft"] == [.get]

/-! A path that no row accepts lists nothing, so its answer stays `404`. -/

#guard Notes.allowed ["notes", "7", "edit"] == []

#guard Notes.allowed ["notes", "-1"] == []

#guard Notes.allowed [] == []

/-! The `405` reply names the methods in its `Allow` header. -/

#guard
  (Reply.methodNotAllowed ((Notes.allowed ["notes"]).map toString)).headers ==
    [("allow", "GET, POST")]

#guard (Reply.methodNotAllowed ["GET"]).status == 405

end ApiMethodTests
