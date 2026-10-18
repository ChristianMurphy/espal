/-!
SHA-256, HMAC-SHA-256, PBKDF2-HMAC-SHA-256 and Base64, as SCRAM-SHA-256 sign-in needs them. Spike
code: written for clarity, checked against Python's `hashlib`, and not tuned or proved.
-/

namespace Spike.Pg.Crypto

def k : Array UInt32 := #[
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2]

def h0 : Array UInt32 := #[
  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]

@[inline] def rotr (x : UInt32) (n : UInt32) : UInt32 := (x >>> n) ||| (x <<< (32 - n))

def compress (h : Array UInt32) (msg : ByteArray) (off : Nat) : Array UInt32 := Id.run do
  let mut w : Array UInt32 := Array.mkEmpty 64
  for i in [0:16] do
    let b := fun j => (msg.get! (off + 4 * i + j)).toUInt32
    w := w.push ((b 0 <<< 24) ||| (b 1 <<< 16) ||| (b 2 <<< 8) ||| b 3)
  for i in [16:64] do
    let x := w[i - 15]!
    let y := w[i - 2]!
    let s0 := rotr x 7 ^^^ rotr x 18 ^^^ (x >>> 3)
    let s1 := rotr y 17 ^^^ rotr y 19 ^^^ (y >>> 10)
    w := w.push (w[i - 16]! + s0 + w[i - 7]! + s1)
  let mut a := h[0]!; let mut b := h[1]!; let mut c := h[2]!; let mut d := h[3]!
  let mut e := h[4]!; let mut f := h[5]!; let mut g := h[6]!; let mut hh := h[7]!
  for i in [0:64] do
    let s1 := rotr e 6 ^^^ rotr e 11 ^^^ rotr e 25
    let ch := (e &&& f) ^^^ ((~~~e) &&& g)
    let t1 := hh + s1 + ch + k[i]! + w[i]!
    let s0 := rotr a 2 ^^^ rotr a 13 ^^^ rotr a 22
    let maj := (a &&& b) ^^^ (a &&& c) ^^^ (b &&& c)
    let t2 := s0 + maj
    hh := g; g := f; f := e; e := d + t1; d := c; c := b; b := a; a := t1 + t2
  return #[h[0]! + a, h[1]! + b, h[2]! + c, h[3]! + d, h[4]! + e, h[5]! + f, h[6]! + g, h[7]! + hh]

def sha256 (data : ByteArray) : ByteArray := Id.run do
  let bits := data.size.toUInt64 * 8
  let mut msg := data.push 0x80
  while msg.size % 64 != 56 do
    msg := msg.push 0
  for i in [0:8] do
    msg := msg.push ((bits >>> (56 - 8 * i.toUInt64)).toUInt8)
  let mut h := h0
  for blk in [0:msg.size / 64] do
    h := compress h msg (64 * blk)
  let mut out := ByteArray.empty
  for x in h do
    out := out.push (x >>> 24).toUInt8 |>.push (x >>> 16).toUInt8 |>.push (x >>> 8).toUInt8 |>.push x.toUInt8
  return out

def xorBytes (a b : ByteArray) : ByteArray := Id.run do
  let mut out := ByteArray.empty
  for i in [0:a.size] do
    out := out.push (a.get! i ^^^ b.get! i)
  return out

def hmac (key msg : ByteArray) : ByteArray := Id.run do
  let mut k := if key.size > 64 then sha256 key else key
  while k.size < 64 do
    k := k.push 0
  let ipad := xorBytes k (ByteArray.mk (Array.replicate 64 0x36))
  let opad := xorBytes k (ByteArray.mk (Array.replicate 64 0x5c))
  return sha256 (opad ++ sha256 (ipad ++ msg))

/-- PBKDF2-HMAC-SHA-256 with a 32-byte output, the only length SCRAM-SHA-256 needs. -/
def pbkdf2 (password salt : ByteArray) (iterations : Nat) : ByteArray := Id.run do
  let mut u := hmac password (salt ++ ByteArray.mk #[0, 0, 0, 1])
  let mut t := u
  for _ in [1:iterations] do
    u := hmac password u
    t := xorBytes t u
  return t

def alphabet : String := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

def base64 (data : ByteArray) : String := Id.run do
  let chars := alphabet.toList.toArray
  let mut out := ""
  let mut i := 0
  while i < data.size do
    let b0 := data.get! i
    let b1 := if i + 1 < data.size then data.get! (i + 1) else 0
    let b2 := if i + 2 < data.size then data.get! (i + 2) else 0
    let n := (b0.toNat <<< 16) ||| (b1.toNat <<< 8) ||| b2.toNat
    out := out.push chars[(n >>> 18) &&& 63]! |>.push chars[(n >>> 12) &&& 63]!
    out := out.push (if i + 1 < data.size then chars[(n >>> 6) &&& 63]! else '=')
    out := out.push (if i + 2 < data.size then chars[n &&& 63]! else '=')
    i := i + 3
  return out

def unbase64 (s : String) : Option ByteArray := do
  let mut bits := 0
  let mut nbits := 0
  let mut out := ByteArray.empty
  for c in s.toList do
    if c == '=' then break
    let v ← (alphabet.toList.idxOf? c)
    bits := (bits <<< 6) ||| v
    nbits := nbits + 6
    if nbits >= 8 then
      nbits := nbits - 8
      out := out.push ((bits >>> nbits) &&& 0xff).toUInt8
  return out

def hex (b : ByteArray) : String :=
  b.foldl (fun s x => s ++ (if x < 16 then "0" else "") ++ String.ofList (Nat.toDigits 16 x.toNat)) ""

end Spike.Pg.Crypto
