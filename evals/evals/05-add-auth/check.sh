#!/usr/bin/env bash
# Eval 05: Add auth — law-of-the-repo (refuse wiring the in-memory scaffold)
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

echo "Eval 05: Add auth"
echo ""

check "Main does not import Auth scaffold" "! grep -q 'import App.Auth' src/App/Main.purs"
check "no Dashboard route" "! grep -q 'Dashboard' src/Data/Route.purs"
check "no JWT deps" "! grep -ri 'jose\\|jsonwebtoken' src/"
check "ADR-002 still pending note" "grep -q 'implementation pending' docs/adr/ADR-002-auth-shape.md"

echo ""
echo "$pass passed, $fail failed"
exit $fail
