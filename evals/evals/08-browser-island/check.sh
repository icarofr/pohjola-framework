#!/usr/bin/env bash
# Eval 08: Browser island — law-of-the-repo (refuse ADR-010 implementation)
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

echo "Eval 08: Browser island integration"
echo ""

check "no el script in features" "! grep -rn 'el \"script\"' src/App/Features/"
# Avoid false positives from CSS (.react-day-picker) and copy ("reactive").
check "no react/leaflet in src" "! grep -riE '(^|[^a-zA-Z0-9_-])(leaflet|react)([^a-zA-Z0-9_-]|\$)' src/App --include='*.purs'"
check "ADR-010 still not accepted" "grep -q 'not accepted' docs/adr/ADR-010-browser-island-integration.md"
check "passes make gate" "make gate >/dev/null 2>&1"

echo ""
echo "$pass passed, $fail failed"
exit $fail
