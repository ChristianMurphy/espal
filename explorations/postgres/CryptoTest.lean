import Spike.Pg.Crypto
open Spike.Pg.Crypto
def main : IO Unit := do
  IO.println (hex (sha256 "abc".toUTF8))
  IO.println (hex (sha256 ("a".pushn 'a' 999).toUTF8))
  IO.println (hex (hmac "key".toUTF8 "The quick brown fox jumps over the lazy dog".toUTF8))
  IO.println (hex (pbkdf2 "pencil".toUTF8 "salt-bytes".toUTF8 4096))
  IO.println (base64 "n,,".toUTF8 ++ " " ++ base64 "ab".toUTF8 ++ " " ++ base64 "abcd".toUTF8)
  IO.println (match unbase64 "W22ZaJ0SNY7soEsUEjb6gQ==" with | some b => hex b | none => "bad")
