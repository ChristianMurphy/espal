module

import LeanIO
open Std Http Async LeanIO

/-!
Parses one multipart body with LeanIO, sent whole and then split into chunks in every way this
file tries, and reports each split whose entries differ from the whole body's.
-/

inductive Seen where
  | field (name value : String)
  | file (name filename : String) (body : List UInt8)
  | error
deriving BEq

def Seen.show : Seen → String
  | .field n v => s!"field {n}={v.quote}"
  | .file n f b => s!"file {n} {f} {(String.fromUTF8? (ByteArray.mk b.toArray)).getD "?" |>.quote}"
  | .error => "error"

def showAll (es : List Seen) : String := s!"[{", ".intercalate (es.map Seen.show)}]"

def boundary := "XyZ"

def crlf (lines : List String) : String := String.intercalate "\r\n" lines

def mixed : ByteArray := (crlf [
  "--XyZ",
  "Content-Disposition: form-data; name=\"title\"",
  "",
  "Hello multipart world",
  "--XyZ",
  "Content-Disposition: form-data; name=\"doc\"; filename=\"a.txt\"",
  "Content-Type: text/plain",
  "",
  "file body line 1",
  "line 2",
  "--XyZ",
  "Content-Disposition: form-data; name=\"note\"",
  "",
  "second field",
  "--XyZ--",
  ""]).toUTF8

def fileOnly : ByteArray := (crlf [
  "--XyZ",
  "Content-Disposition: form-data; name=\"doc\"; filename=\"a.txt\"",
  "",
  "file body line 1",
  "line 2",
  "--XyZ--",
  ""]).toUTF8

def parseWith (chunks : List ByteArray) : IO (List Seen) := Async.block do
  let req ← (Request.new |>.method .post |>.uri! "/upload"
      |>.header! "Content-Type" s!"multipart/form-data; boundary={boundary}").stream fun s => do
    for c in chunks do
      s.send (Chunk.ofByteArray c)
  ContextAsync.run do
    match ← FromRequestBody.from_request_body (α := MultiPartForm) req with
    | .error _ => return [.error]
    | .ok mp =>
      let mut out := #[]
      while let some entry := ← mp.nextEntry do
        match entry with
        | .field n v => out := out.push (.field n v)
        | .file f =>
          let acc ← IO.mkRef ByteArray.empty
          f.stream fun c => acc.modify (· ++ c)
          out := out.push (.file f.name f.filename (← acc.get).toList)
      return out.toList

def splitEvery (b : ByteArray) (n : Nat) : List ByteArray :=
  (List.range ((b.size + n - 1) / n)).map fun i => b.extract (i * n) (min b.size ((i + 1) * n))

/-- The end of the first part's headers, for the split that keeps them in one chunk. -/
def headerEnd? (body : ByteArray) : Option Nat :=
  ((List.range body.size).find? fun i => body.extract i (i + 4) == "\r\n\r\n".toUTF8).map (· + 4)

def check (verbose : Bool) (name : String) (body : ByteArray) : IO Nat := do
  let whole ← parseWith [body]
  IO.println s!"{name}, whole body: {showAll whole}"
  let mut bad := 0
  let mut shown : List String := []
  let mut cases : List (String × String × List ByteArray) := []
  for k in [1:body.size] do
    cases := ("split at", s!"{k}", [body.extract 0 k, body.extract k body.size]) :: cases
  for n in [1:body.size] do
    cases := ("chunks of", s!"{n}", splitEvery body n) :: cases
  if let some h := headerEnd? body then
    for n in [1:body.size - h] do
      cases := ("headers whole, then chunks of", s!"{n}",
        body.extract 0 h :: splitEvery (body.extract h body.size) n) :: cases
  for (kind, size, chunks) in cases.reverse do
    let got ← parseWith chunks
    if got != whole then
      bad := bad + 1
      if verbose || !shown.contains kind then
        shown := kind :: shown
        IO.println s!"{kind} {size}: {showAll got}"
  IO.println s!"{name}: {bad} of {cases.length} splits differ from the whole body"
  return bad

public def main (args : List String) : IO UInt32 := do
  let verbose := args.contains "-v"
  let bad := (← check verbose "mixed" mixed) + (← check verbose "file only" fileOnly)
  return if bad == 0 then 0 else 1
