#!/usr/bin/env bash
# Eval 06: Component architecture
# Asserts: Container usage, Components/ split, no hand-written mx-auto max-w-*, no cross-feature imports
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

# Page exists and uses Layout.Page (not hand-rolled HTML shell)
check "Team/Page.purs exists" "test -f src/App/Features/Team/Page.purs"
check "uses Layout.Page" "grep -q 'App.Layout.Page' src/App/Features/Team/Page.purs"
check "no hand-rolled doctype/html" "! grep -qi '<!doctype\|<html' src/App/Features/Team/Page.purs"

# Route added to Route.purs
check "Route has Team constructor" "grep -q 'Team' src/Data/Route.purs"

# i18n: both languages have entries
check "Dictionary has team entries (en)" "grep -i 'team' src/App/Data/I18n/Dictionary.purs | grep -iv 'import\|--' | head -1 | grep -q ."

# No FFI or raw used for a static page
check "no FFI in Team feature" "! grep -r 'foreign import' src/App/Features/Team/ 2>/dev/null"
check "no raw in Team feature" "! grep -r '\braw\b' src/App/Features/Team/ 2>/dev/null"

# Component architecture: View.purs uses container (not hand-written mx-auto max-w-*)
check "View.purs imports App.Ui.Container" "grep -q 'App.Ui.Container' src/App/Features/Team/View.purs"
check "View.purs uses container function" "grep -q 'container' src/App/Features/Team/View.purs"
check "no hand-written mx-auto max-w-* in View.purs" "! grep -q 'mx-auto max-w-' src/App/Features/Team/View.purs"

# No hand-written mx-auto max-w-* anywhere in features (the rule is repo-wide)
check "no hand-written mx-auto max-w-* in any feature" "! grep -r 'mx-auto max-w-' src/App/Features/ 2>/dev/null"

# No cross-feature imports (Team must not import Posts, Home, etc.)
check "no cross-feature imports" "! grep -r 'import App.Features.Posts\|import App.Features.Home\|import App.Features.About\|import App.Features.Contact\|import App.Features.Legal' src/App/Features/Team/ 2>/dev/null"

# Semantic text tones: no raw opacity modifiers in features (ADR-008)
check "no raw text-base-content/N in features" "! grep -r 'text-base-content/' src/App/Features/ 2>/dev/null"

echo ""
echo "$pass passed, $fail failed"
exit $fail
