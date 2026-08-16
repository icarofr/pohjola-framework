#!/usr/bin/env bash
# Eval 09: Script Security & Isolation
# Asserts: el "script" only exists in App.Layout.Scripts and App.Layout.Page, no raw JS
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

# Script elements restricted exclusively to App.Layout.Scripts and App.Layout.Page
check "no script outside Layout.Scripts and Layout.Page" "! grep -rn 'el \"script\"' src/ | grep -v '^src/App/Layout/Scripts\.purs:' | grep -v '^src/App/Layout/Page\.purs:'"

# No raw HTML escape hatch in source
check "no raw/Raw in src/" "! grep -rnE '\braw\b|\bRaw\b' src/"

# Gate check succeeds
check "passes make gate" "make gate >/dev/null 2>&1"

echo ""
echo "$pass passed, $fail failed"
exit $fail
