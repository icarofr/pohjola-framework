#!/usr/bin/env bash
# Eval 09: Script Security & Isolation
# Asserts: no el "script" in Features; structural policy via make gate
set -euo pipefail

pass=0; fail=0
check() {
  if eval "$2" 2>/dev/null; then
    echo "  ✓ $1"
    pass=$((pass + 1))
  else
    echo "  ✗ $1"
    fail=$((fail + 1))
  fi
}

echo "Eval 09: Script Security & Isolation"
echo ""

# Features must not emit script elements (allowlist lives in Layout + Policy.Contract)
check "no el script in Features" "! grep -rn 'el \"script\"' src/App/Features/"

# Gate already covers raw/Raw, script allowlist, FFI, etc.
check "passes make gate" "make gate >/dev/null 2>&1"

echo ""
echo "$pass passed, $fail failed"
exit $fail
