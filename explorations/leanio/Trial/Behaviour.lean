module

import LeanIO
meta import LeanIO
open Std Http LeanIO

/-! Checks the trial's claims about LeanIO's range and ETag helpers. -/

/-- The range LeanIO serves for one `Range` header on a 1,893-byte file, as `(start, length)`. -/
def served (header : String) : Option (Nat × Nat) := pickRange (parseRange header) 1893

#guard served "bytes=0-9" == some (0, 10)
-- A start past the end gives a zero-length range at 0, which RangeFile sends as a 206.
#guard served "bytes=1993-" == some (0, 0)
-- An end before the start gives one byte, where RFC 9110 calls the range invalid.
#guard served "bytes=20-10" == some (20, 1)
#guard served "bytes=0-1_0" == some (0, 11)
-- Only the first of several ranges counts.
#guard served "bytes=5-9,0-1" == some (5, 5)
#guard served "BYTES=0-9" == none

def metadata (sec : Int) (nsec : UInt32) (size : UInt64) : IO.FS.Metadata :=
  { accessed := ⟨0, 0⟩, modified := ⟨sec, nsec⟩, byteSize := size, type := .file, numLinks := 1 }

-- Two versions of a file with different times and sizes get the same ETag.
#guard computeETag (metadata 1700000000 12345 678) == computeETag (metadata 1700000000 1234 5678)
