module

public import EspalJson
meta import EspalJson
public import Json
meta import Json

/-!
Tests for `decodeBody` and `Problem`. A body that isn't JSON gets a `400` problem, and one that
parses but fails its types or checks gets a `422` that lists every failure. Each pointer prints
as a URI fragment, with the bytes a fragment can't hold percent-encoded.
-/

open Json Espal

public section

namespace ProblemTests

structure Item where
  name : String
  price : Small
  deriving Json

structure Order where
  title : String
  items : Array Item
  some : items.size ≥ 1
  deriving Json

/-- The problem that decoding `body` as an `Order` gives, printed, or "ok". -/
def answer (body : String) : String :=
  match decodeBody Order body.toUTF8 with
  | .ok _ => "ok"
  | .error p => compress (toJson p)

/-! A body that decodes gives the value. -/

#guard answer "{\"title\":\"a\",\"items\":[{\"name\":\"x\",\"price\":2}]}" == "ok"

/-! A body that isn't JSON, or isn't UTF-8, gets the `400` problem with no error list. -/

#guard
  answer "{\"title\":" ==
    "{\"type\":\"/problems/malformed-json\",\"title\":\"The request body is not valid JSON\",\
      \"status\":400}"

#guard (decodeBody Order (ByteArray.mk #[0xff])).toOption.isNone

#guard
  match decodeBody Order (ByteArray.mk #[0xff]) with
  | .error p => p.status == 400
  | .ok _ => false

/-! A body that parses but fails gets the `422` problem, with every failure and its fragment. -/

#guard
  answer "{\"items\":[{\"name\":\"x\",\"price\":\"2\"},{\"name\":3,\"price\":1}],\"extra\":1}" ==
    "{\"type\":\"/problems/validation\",\"title\":\"The request body failed validation\",\
      \"status\":422,\"errors\":[{\"pointer\":\"#/title\",\"detail\":\"missing\"},\
      {\"pointer\":\"#/items/0/price\",\"detail\":\"expected a number\"},\
      {\"pointer\":\"#/items/1/name\",\"detail\":\"expected a string\"},\
      {\"pointer\":\"#/extra\",\"detail\":\"unknown key\"}]}"

#guard
  answer "{\"title\":\"a\",\"items\":[]}" ==
    "{\"type\":\"/problems/validation\",\"title\":\"The request body failed validation\",\
      \"status\":422,\"errors\":[{\"pointer\":\"#\",\"detail\":\"fails the check some\"}]}"

/-! A fragment keeps the characters RFC 3986 allows and percent-encodes the rest, after the
pointer's own `~0` and `~1` escapes. -/

#guard
  (⟨["a b", "c/d", "e~f", "é", "100%"], ""⟩ : DecodeError).fragment ==
    "#/a%20b/c~1d/e~0f/%C3%A9/100%25"

#guard (⟨[], ""⟩ : DecodeError).fragment == "#"

end ProblemTests
