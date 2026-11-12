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

/-! `linkTo` takes the captures and query arguments in the handler's order, without the body. A
`none` leaves its key out. -/

#guard linkTo rows (.ofNat (by decide) 20) == ⟨["queries"], [("queries", "20")]⟩

#guard linkTo search "lean" 2 none == ⟨["search"], [("q", "lean"), ("page", "2")]⟩

#guard
  linkTo search "a&b=c" 0 (some false) ==
    ⟨["search"], [("q", "a&b=c"), ("page", "0"), ("exact", "false")]⟩

#guard linkTo addNote 7 true == ⟨["notes", "7"], [("draft", "true")]⟩

/-! Following a link runs the handler with the arguments the link was built from. -/

/--
info: ApiQueryTests.Site.linkTo_search (q : String) (page : Nat) (exact : Option Bool) (contentType : Option String)
  (bytes : ByteArray) :
  Option.map (fun m => m.snd.reply (linkTo search q page exact).query contentType bytes)
      (matchTable Site.routes Std.Http.Method.get (linkTo search q page exact).path) =
    some ((Endpoint.ofValue (search { } q page exact)).reply [] contentType bytes)
-/
#guard_msgs in
#check Site.linkTo_search

/--
info: ApiQueryTests.Site.linkTo_addNote (id : Nat) (draft : Bool) (contentType : Option String) (bytes : ByteArray) :
  Option.map (fun m => m.snd.reply (linkTo addNote id draft).query contentType bytes)
      (matchTable Site.routes Std.Http.Method.post (linkTo addNote id draft).path) =
    some ((Endpoint.ofBody fun note => addNote { } id draft note).reply [] contentType bytes)
-/
#guard_msgs in
#check Site.linkTo_addNote

/--
info: '_private.EspalTests.ApiQuery.0.ApiQueryTests.Site.linkTo_addNote' depends on axioms: [propext,
 Classical.choice,
 Quot.sound]
-/
#guard_msgs in
#print axioms Site.linkTo_addNote

example (q : String) (page : Nat) :
    (matchTable Site.routes .get (linkTo search q page none).path).map
        (fun m => m.2.reply (linkTo search q page none).query none .empty) =
      some (toReply (search {} q page none)) :=
  Site.linkTo_search q page none none .empty

/-! Each instance reads back what it writes, at the edges of its type. -/

#guard (fromQuery (α := Nat) (toQuery 0)).toOption == some 0

#guard (fromQuery (α := String) (toQuery "")).toOption == some ""

#guard (fromQuery (α := Option String) (toQuery (some ""))).toOption == some (some "")

#guard (fromQuery (α := Option Nat) (toQuery (none : Option Nat))).toOption == some none

#guard
  [(Clamp.ofNat (lo := 3) (hi := 3) (by decide) 0), .ofNat (by decide) 9].all fun c =>
    (fromQuery (toQuery c)).toOption == some c

/-! A query type that can't be written back gets no `linkTo`, and its row still serves. A handler
argument named like a variable of the link theorem doesn't clash with it. -/

structure Even where
  half : Nat

instance : FromQuery Even where
  fromQuery
    | some s => (natOfDigits? s).elim (.error "expected a number") fun n => .ok ⟨n / 2⟩
    | none => .error "missing"

def halve (_ : Public) (n : Even) : Text :=
  s!"{n.half}"

def echoBytes (_ : Public) (bytes : Nat) (contentType : String) : Text :=
  s!"{bytes} {contentType}"

api Odd where
  GET "/halve" => halve
  GET "/echo/:bytes" => echoBytes

#guard
  ((matchTable Odd.routes .get ["halve"]).map fun m => (m.2.reply [("n", "9")] none .empty).body) ==
    some "4".toUTF8

/--
error: failed to synthesize instance of type class
  LinkTo halve ?m.2

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
-/
#guard_msgs in
#check linkTo halve

#guard linkTo echoBytes 3 "x" == ⟨["echo", "3"], [("contentType", "x")]⟩

/--
info: ApiQueryTests.Odd.linkTo_echoBytes (bytes : Nat) (contentType : String) (contentType' : Option String)
  (bytes' : ByteArray) :
  Option.map (fun m => m.snd.reply (linkTo echoBytes bytes contentType).query contentType' bytes')
      (matchTable Odd.routes Std.Http.Method.get (linkTo echoBytes bytes contentType).path) =
    some ((Endpoint.ofValue (echoBytes { } bytes contentType)).reply [] contentType' bytes')
-/
#guard_msgs in
#check Odd.linkTo_echoBytes

end ApiQueryTests
