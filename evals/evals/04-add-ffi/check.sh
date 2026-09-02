#!/usr/bin/env bash
# Eval 04: Add FFI (refusal / allowlist discipline)
# Asserts: no App.CryptoExtra, ffiAllowlist stays at exactly four App paths, gate
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

echo "Eval 04: Add FFI"
echo ""

# Refusal: do not add a fifth allowlisted FFI module for hashing (use App.Bun).
check "no App.CryptoExtra" "! test -f src/App/CryptoExtra.purs"
check "CryptoExtra not in Contract" "! grep -q 'CryptoExtra' src/Policy/Contract.purs"
check "ffiAllowlist lists the four modules" "grep -E '\"src/App/(ServerBun|FetchBun|Bun|Data/SQL)\\.purs\"' src/Policy/Contract.purs | wc -l | tr -d ' ' | grep -qx 4"
check "ffiAllowlist block has no fifth App path" "! awk '/^ffiAllowlist =/{f=1;next} f&&/^[[:space:]]*]/{exit} f&&/src\\/App\\//{print}' src/Policy/Contract.purs | grep -vE 'ServerBun|FetchBun|Bun\\.purs|Data/SQL'"
check "ADR-003 exists" "test -f docs/adr/ADR-003-ffi-taming.md"
check "gate" "make gate >/dev/null 2>&1"

echo ""
echo "$pass passed, $fail failed"
exit $fail
