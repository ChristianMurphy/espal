module

import EspalJson
meta import EspalJson
import EspalRoute
meta import EspalRoute

/-!
Tests for query parameters in the `api` command. An argument that no capture names reads the
query parameter of its name when its type has a `FromQuery` instance. A missing or malformed
parameter gets the `400` problem that names it, and a clamped one never fails.
-/

open Espal Routing Json

namespace ApiQueryTests

abbrev Count :=
  Clamp 1 500

structure Note where
  text : String
  deriving Json

def rows (_ : Public) (queries : Count) : Text :=
  s!"{queries.val} rows"

def search (_ : Public) (q : String) (page : Nat) (exact : Option Bool) : Text :=
  s!"{q} {page} {exact}"

def addNote (_ : Public) (id : Nat) (draft : Bool) (note : Note) : Text :=
  s!"{id} {draft} {note.text}"

api Site where
  GET "/queries" => rows
  GET "/search" => search
  POST "/notes/:id" => addNote

/-- The status and text that the route for `method` and `path` answers `query` and `body` with. -/
def answer (method : Std.Http.Method) (path : List String) (query : Query) (body : String := "") :
    Option (UInt16 × String) := do
  let (_, endpoint) ← matchTable Site.routes method path
  let reply := endpoint.reply query (some "application/json") body.toUTF8
  return (reply.status, ← String.fromUTF8? reply.body)

/-! A clamped parameter reads a missing or malformed value as its lower bound, and moves any
other value inside its bounds. -/

#guard answer .get ["queries"] [("queries", "20")] == some (200, "20 rows")

#guard answer .get ["queries"] [] == some (200, "1 rows")

#guard answer .get ["queries"] [("queries", "foo")] == some (200, "1 rows")

#guard answer .get ["queries"] [("queries", "0")] == some (200, "1 rows")

#guard answer .get ["queries"] [("queries", "501")] == some (200, "500 rows")

/-! Each query argument reads the parameter of its own name. An optional one may be absent, and a
repeated key reads its first value. -/

#guard
  answer .get ["search"] [("page", "2"), ("q", "lean"), ("q", "other")] == some (200, "lean 2 none")

#guard
  answer .get ["search"] [("q", "lean"), ("page", "2"), ("exact", "true")] ==
    some (200, "lean 2 (some true)")

/-! A missing or malformed parameter gets the `400` problem that names it, and the handler doesn't
run. -/

#guard
  answer .get ["search"] [("q", "lean")] ==
    some
      (400,
        "{\"type\":\"/problems/query\",\"title\":\"A query parameter is invalid\",\"status\":400,\
          \"parameter\":\"page\",\"detail\":\"missing\"}")

#guard
  answer .get ["search"] [("q", "lean"), ("page", "-1")] ==
    some
      (400,
        "{\"type\":\"/problems/query\",\"title\":\"A query parameter is invalid\",\"status\":400,\
          \"parameter\":\"page\",\"detail\":\"expected a natural number\"}")

#guard
  (answer .get ["search"] [("q", "lean"), ("page", "1"), ("exact", "yes")]).map (·.1) == some 400

/-! A row can take a capture, a query parameter and a body together. The query is checked before
the body. -/

#guard
  answer .post (pathTo addNote 7) [("draft", "true")] "{\"text\":\"hi\"}" == some (200, "7 true hi")

#guard (answer .post (pathTo addNote 7) [] "{\"text\":\"hi\"}").map (·.1) == some 400

#guard (answer .post (pathTo addNote 7) [("draft", "true")] "{}").map (·.1) == some 422

/-! The link theorem of a row with a query argument names the endpoint that reads it. -/

/--
info: ApiQueryTests.Site.pathTo_rows :
  matchTable Site.routes Std.Http.Method.get (pathTo rows) =
    some
      ({ method := Std.Http.Method.get, segs := [PathSeg.lit "queries" ⋯] },
        Endpoint.noBody fun query => withQuery query "queries" fun queries => toReply (rows { } queries))
-/
#guard_msgs in
#check Site.pathTo_rows

end ApiQueryTests
