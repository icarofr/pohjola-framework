#!/usr/bin/env bash
# Eval 01: Add a static page
# Asserts: Page+View, Templates.Render, route, i18n, no FFI, gate
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

echo "Eval 01: Add a static page"
echo ""

check "Team/Page.purs exists" "test -f src/App/Features/Team/Page.purs"
check "Team/View.purs exists" "test -f src/App/Features/Team/View.purs"
check "View uses Templates.Render" "grep -q 'App.Ui.Templates.Render' src/App/Features/Team/View.purs"
check "Page uses staticPage" "grep -q 'App.Layout.Page' src/App/Features/Team/Page.purs"
check "no class_ in View" "! grep -q 'class_' src/App/Features/Team/View.purs"
check "Route has Team" "grep -q 'Team' src/Data/Route.purs"
check "I18n has team entries" "grep -i 'team' src/Data/I18n.purs | grep -iv 'import\|--' | head -1 | grep -q ."
check "no FFI" "! grep -r 'foreign import' src/App/Features/Team/"
check "gate" "make gate >/dev/null 2>&1"

echo ""
echo "$pass passed, $fail failed"
exit $fail
