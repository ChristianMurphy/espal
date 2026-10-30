module

public import EspalJson
meta import EspalJson
public import Json
meta import Json

/-!
Tests for 64-bit integers as decimal strings. `decimalInt?` reads only the spelling `toString`
writes, so the `Int64` decoder refuses leading zeros, `-0` and `+`. lean-json's `UInt64` decoder
still accepts leading zeros. Both refuse a value one past each end of their range.
-/

open Json Espal

public section

namespace DecimalTests

/-- The message from decoding `j` as `α`, or "ok". -/
def outcome (α : Type) [FromJson α] (j : Json) : String :=
  match (fromJson? j : Except String α) with
  | .ok _ => "ok"
  | .error e => e

/-! `decimalInt?` reads the one spelling `toString` writes, and nothing else. -/

#guard decimalInt? "0" 20 == some 0

#guard decimalInt? "-42" 20 == some (-42)

#guard decimalInt? "-9223372036854775808" 20 == some (-9223372036854775808)

#guard decimalInt? "-0" 20 == none

#guard decimalInt? "007" 20 == none

#guard decimalInt? "+5" 20 == none

#guard decimalInt? "" 20 == none

#guard decimalInt? "-" 20 == none

#guard decimalInt? "12a" 20 == none

#guard decimalInt? " 1" 20 == none

#guard decimalInt? "123" 2 == none

/-! `Int64` travels as a decimal string, takes both ends of its range, and refuses one past each. -/

#guard compress (toJson (-42 : Int64)) == "\"-42\""

#guard outcome Int64 "9223372036854775807" == "ok"

#guard outcome Int64 "-9223372036854775808" == "ok"

#guard
  outcome Int64 "9223372036854775808" ==
    "expected an integer from -9223372036854775808 to 9223372036854775807"

#guard
  outcome Int64 "-9223372036854775809" ==
    "expected an integer from -9223372036854775808 to 9223372036854775807"

#guard outcome Int64 "007" == "expected a string holding a decimal integer"

#guard outcome Int64 "123456789012345678901" == "expected a string holding a decimal integer"

#guard outcome Int64 (.num (Number.ofInt 5)) == "expected a string"

/-! `UInt64` uses lean-json's codec. It takes both ends of its range, refuses one past the top, and
accepts leading zeros. -/

#guard compress (toJson (18446744073709551615 : UInt64)) == "\"18446744073709551615\""

#guard outcome UInt64 "0" == "ok"

#guard outcome UInt64 "18446744073709551615" == "ok"

#guard outcome UInt64 "18446744073709551616" == "value is too large for UInt64"

#guard outcome UInt64 "007" == "ok"

/-! A derived codec takes 64-bit fields. -/

structure Account where
  id : Int64
  balance : UInt64
  deriving Json

#guard
  compress (toJson ({ id := -1, balance := 18446744073709551615 } : Account)) ==
    "{\"id\":\"-1\",\"balance\":\"18446744073709551615\"}"

#guard
  outcome Account (mkObj [("id", "01"), ("balance", "2")]) ==
    "/id: expected a string holding a decimal integer"

end DecimalTests
