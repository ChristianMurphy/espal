/-!
Postgres frontend/backend protocol 3.0 messages: the startup and SCRAM messages, the extended query
messages, and a decoder for backend messages.
-/

namespace Spike.Pg.Wire

def be32 (n : UInt32) : ByteArray :=
  ⟨#[(n >>> 24).toUInt8, (n >>> 16).toUInt8, (n >>> 8).toUInt8, n.toUInt8]⟩

def be16 (n : UInt16) : ByteArray := ⟨#[(n >>> 8).toUInt8, n.toUInt8]⟩

def cstr (s : String) : ByteArray := s.toUTF8.push 0

def frame (tag : Char) (body : ByteArray) : ByteArray :=
  ByteArray.mk #[tag.toNat.toUInt8] ++ be32 (body.size + 4).toUInt32 ++ body

def startup (user database : String) : ByteArray :=
  let body := be32 196608 ++ cstr "user" ++ cstr user ++ cstr "database" ++ cstr database ++ ⟨#[0]⟩
  be32 (body.size + 4).toUInt32 ++ body

def saslInitial (mechanism : String) (data : ByteArray) : ByteArray :=
  frame 'p' (cstr mechanism ++ be32 data.size.toUInt32 ++ data)

def saslResponse (data : ByteArray) : ByteArray := frame 'p' data

def parse (name query : String) (types : Array UInt32) : ByteArray :=
  frame 'P' (cstr name ++ cstr query ++ be16 types.size.toUInt16 ++ types.foldl (· ++ be32 ·) .empty)

/-- Binds binary parameters to a prepared statement and asks for binary results. -/
def bind (statement : String) (params : Array ByteArray) : ByteArray :=
  frame 'B' (cstr "" ++ cstr statement ++ be16 1 ++ be16 1 ++ be16 params.size.toUInt16 ++
    params.foldl (fun acc p => acc ++ be32 p.size.toUInt32 ++ p) .empty ++ be16 1 ++ be16 1)

def execute : ByteArray := frame 'E' (cstr "" ++ be32 0)

def sync : ByteArray := frame 'S' .empty

def terminate : ByteArray := frame 'X' .empty

def u32At (b : ByteArray) (i : Nat) : UInt32 :=
  (b.get! i).toUInt32 <<< 24 ||| (b.get! (i + 1)).toUInt32 <<< 16 |||
  (b.get! (i + 2)).toUInt32 <<< 8 ||| (b.get! (i + 3)).toUInt32

def u16At (b : ByteArray) (i : Nat) : UInt16 :=
  (b.get! i).toUInt16 <<< 8 ||| (b.get! (i + 1)).toUInt16

/-- A backend message: its tag and body. -/
structure Msg where
  tag : Char
  body : ByteArray

/-- Splits complete messages off the front of `buf`, returning them and the unread rest. -/
def split (buf : ByteArray) : Array Msg × ByteArray := Id.run do
  let mut msgs := #[]
  let mut pos := 0
  while pos + 5 ≤ buf.size do
    let len := (u32At buf (pos + 1)).toNat
    if pos + 1 + len > buf.size then break
    msgs := msgs.push { tag := Char.ofNat (buf.get! pos).toNat, body := buf.extract (pos + 5) (pos + 1 + len) }
    pos := pos + 1 + len
  return (msgs, buf.extract pos buf.size)

/-- Columns of a `DataRow`; `none` is SQL `NULL`. -/
def dataRow (body : ByteArray) : Array (Option ByteArray) := Id.run do
  let n := (u16At body 0).toNat
  let mut cols := #[]
  let mut pos := 2
  for _ in [0:n] do
    let len := u32At body pos
    pos := pos + 4
    if len == 0xFFFFFFFF then
      cols := cols.push none
    else
      cols := cols.push (some (body.extract pos (pos + len.toNat)))
      pos := pos + len.toNat
  return cols

/-- The `M` (message) field of an `ErrorResponse`, with its `C` (SQLSTATE) code. -/
def errorText (body : ByteArray) : String := Id.run do
  let mut pos := 0
  let mut msg := ""
  let mut code := ""
  while pos < body.size && body.get! pos != 0 do
    let field := Char.ofNat (body.get! pos).toNat
    let mut stop := pos + 1
    while stop < body.size && body.get! stop != 0 do
      stop := stop + 1
    let value := String.fromUTF8! (body.extract (pos + 1) stop)
    if field == 'M' then msg := value
    if field == 'C' then code := value
    pos := stop + 1
  return s!"{code}: {msg}"

end Spike.Pg.Wire
