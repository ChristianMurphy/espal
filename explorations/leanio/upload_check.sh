#!/usr/bin/env bash
# Builds LeanIO's upload example on Lean 4.36.0-rc1, sends it text fields of three sizes and a
# 200 MB file, and prints what arrived with the server's peak memory.
set -euo pipefail
cd "$(dirname "$0")/leanio"
lake +leanprover/lean4:v4.36.0-rc1 build upload >/dev/null
work=$(mktemp -d)
trap 'kill "$pid" 2>/dev/null; rm -rf "$work" uploads' EXIT
.lake/build/bin/upload >/dev/null 2>&1 &
pid=$!
sleep 1
peak() { grep VmHWM "/proc/$pid/status" | tr -s ' \t' ' '; }
echo "at start: $(peak)"
for n in 100 20000 200000 50000000; do
  head -c "$n" /dev/zero | tr '\0' a > "$work/field.txt"
  got=$(curl -s -F "title=<$work/field.txt" http://127.0.0.1:8081/upload |
    python3 -c 'import json, sys; print(len(json.load(sys.stdin)["fields"][0][1]))')
  echo "text field of $n bytes arrived as $got bytes"
done
head -c 200000000 /dev/urandom > "$work/file.bin"
curl -s -F "doc=@$work/file.bin" http://127.0.0.1:8081/upload >/dev/null
sent=$(sha256sum < "$work/file.bin" | cut -c1-16)
saved=$(sha256sum < uploads/file.bin | cut -c1-16)
echo "200 MB file: sent $sent, saved $saved"
echo "at end: $(peak)"
