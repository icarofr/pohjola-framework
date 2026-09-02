#!/usr/bin/env bash
# Eval 03: Add a form via Form page template
# Asserts: Beta View uses Form template, no App.Ui.Form in features, decode in App.Form, honeypot
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

echo "Eval 03: Add a form"
echo ""

check "Beta/View.purs exists" "test -f src/App/Features/Beta/View.purs"
check "View uses Form template" "grep -q 'Form' src/App/Features/Beta/View.purs"
check "View uses Templates.Render" "grep -q 'App.Ui.Templates.Render' src/App/Features/Beta/View.purs"
check "no App.Ui.Form in Features" "! grep -r 'import App.Ui.Form' src/App/Features/"
check "decode lives in App.Form" "grep -q 'decodeBeta\|BetaSignup' src/App/Form.purs || grep -q 'beta' src/App/Form.purs"
check "honeypot website" "grep -q 'website' src/App/Ui/Templates/Form.purs"
check "no client-side fetch in Features" "! grep -r 'fetch(' src/App/Features/ 2>/dev/null | grep -v '.purs'"
check "gate" "make gate >/dev/null 2>&1"

echo ""
echo "$pass passed, $fail failed"
exit $fail
