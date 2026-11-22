#!/usr/bin/env bash
# Builds the libpq binding and `c/pq_stress.c` with the sanitizers, and runs the stress program
# against the server named by ESPAL_TEST_DATABASE. Lean links with its own toolchain, which has
# no sanitizer runtimes, so this builds with the system compiler against Lean's shared runtime.
set -euo pipefail
cd "$(dirname "$0")"

prefix="$(lean --print-prefix)"
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT

for sanitizer in address,undefined thread; do
  cc -g -O1 -fsanitize="$sanitizer" -fno-omit-frame-pointer -Wall -Werror \
    -I "$prefix/include" -I "$(pg_config --includedir)" \
    ../packages/espal-postgres/c/pq.c c/pq_stress.c \
    -L "$prefix/lib/lean" -Wl,-rpath,"$prefix/lib/lean" -lleanshared \
    "$(pg_config --libdir)/libpq.so" -lpthread \
    -o "$out/pq_stress"
  echo "pq_stress with -fsanitize=$sanitizer"
  "$out/pq_stress"
done
