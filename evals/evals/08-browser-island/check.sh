#!/usr/bin/env bash
# Eval 08: Browser island integration (ADR-010, ADR-000)
# Asserts: Uses App.Alpine typed constructors, no raw script tags in views, passes gate
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

# Guardrail checks: No custom script elements in features
check "no el script in features" "! grep -rn 'el \"script\"' src/App/Features/ 2>/dev/null"
check "no raw script tags in views" "! grep -rni '<script' src/App/Features/ 2>/dev/null"

# Alpine constructors used
check "interactivity through App.Alpine" "grep -rn 'App.Alpine' src/App/Features/ 2>/dev/null | grep -q 'App.Alpine'"

# Gate passes
check "passes make gate" "make gate >/dev/null 2>&1"

echo ""
echo "$pass passed, $fail failed"
exit $fail
