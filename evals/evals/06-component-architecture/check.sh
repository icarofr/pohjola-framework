#!/usr/bin/env bash
# Eval 06: Component architecture + ADR-012 UI contract
# Asserts: Templates.Render in View, Layout.Page for staticPage, no class_, no cross-feature imports
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

echo "Eval 06: Component architecture"
echo ""

# Page exists: document wrapper via Layout.Page; body via Templates.Render
check "Team/Page.purs exists" "test -f src/App/Features/Team/Page.purs"
check "Team/View.purs exists" "test -f src/App/Features/Team/View.purs"
check "Page uses Layout.Page" "grep -q 'App.Layout.Page' src/App/Features/Team/Page.purs"
check "View uses Templates.Render" "grep -q 'App.Ui.Templates.Render' src/App/Features/Team/View.purs"
check "no hand-rolled doctype/html" "! grep -qi '<!doctype\|<html' src/App/Features/Team/Page.purs"

# Route added to Route.purs
check "Route has Team constructor" "grep -q 'Team' src/Data/Route.purs"

# i18n: languages have entries
check "I18n has team entries" "grep -i 'team' src/Data/I18n.purs | grep -iv 'import\|--' | head -1 | grep -q ."

# No FFI or raw used for a static page
check "no FFI in Team feature" "! grep -r 'foreign import' src/App/Features/Team/ 2>/dev/null"
check "no raw in Team feature" "! grep -r '\braw\b' src/App/Features/Team/ 2>/dev/null"

# ADR-012: feature views fill template slots (no class_)
check "no class_ in Team View.purs" "! grep -q 'class_' src/App/Features/Team/View.purs"
check "no class_ in Team Components" "! grep -r 'class_' src/App/Features/Team/Components/ 2>/dev/null"

# No hand-written mx-auto max-w-* anywhere in features
check "no hand-written mx-auto max-w-* in any feature" "! grep -r 'mx-auto max-w-' src/App/Features/ 2>/dev/null"

# No cross-feature imports
check "no cross-feature imports" "! grep -r 'import App.Features.Posts\|import App.Features.Home\|import App.Features.About\|import App.Features.Contact' src/App/Features/Team/ 2>/dev/null"

# Semantic text tones: no raw opacity modifiers in features (ADR-008)
check "no raw text-base-content/N in features" "! grep -r 'text-base-content/' src/App/Features/ 2>/dev/null"

echo ""
echo "$pass passed, $fail failed"
exit $fail
