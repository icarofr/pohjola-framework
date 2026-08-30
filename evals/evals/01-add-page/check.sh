#!/usr/bin/env bash
# Eval 01: Add a static page
# Asserts: page structure (Page.purs + Layout.Page), route added, i18n in both langs
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

# Page exists and uses Layout.Page (not hand-rolled HTML shell)
check "Team/Page.purs exists" "test -f src/App/Features/Team/Page.purs"
check "uses Layout.Page" "grep -q 'App.Layout.Page' src/App/Features/Team/Page.purs"
check "no hand-rolled doctype/html" "! grep -qi '<!doctype\|<html' src/App/Features/Team/Page.purs"

# Route added to Route.purs
check "Route has Team constructor" "grep -q 'Team' src/Data/Route.purs"

# i18n: both languages have entries
check "I18n has team entries" "grep -i 'team' src/Data/I18n.purs | grep -iv 'import\|--' | head -1 | grep -q ."

# No FFI or raw used for a static page
check "no FFI in Team feature" "! grep -r 'foreign import' src/App/Features/Team/ 2>/dev/null"
check "no raw in Team feature" "! grep -r '\braw\b' src/App/Features/Team/ 2>/dev/null"

echo ""
echo "$pass passed, $fail failed"
exit $fail
