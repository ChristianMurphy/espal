#!/usr/bin/env bash
# Clones LeanIO at the pinned commit into leanio/ and applies the patches it needs on Lean 4.35 and later.
set -euo pipefail
cd "$(dirname "$0")"
rev=0bb212d57f3dba2d76cf601f76a7c431a51c902e
if [ ! -d leanio ]; then
  git clone -q https://github.com/ecyrbe/leanio leanio
  git -C leanio checkout -q "$rev"
  git -C leanio apply ../patches/lean-4.35.patch
fi
