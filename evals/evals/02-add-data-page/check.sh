#!/usr/bin/env bash
# Eval 02: Add a data-backed page
# Asserts: four-file split (Types/Service/Page/View), fetchJson boundary, no cross-feature imports
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

echo "Eval 02: Add a data-backed page"
echo ""

# Four-file split
check "Jobs/Types.purs exists" "test -f src/App/Features/Jobs/Types.purs"
check "Jobs/Service.purs exists" "test -f src/App/Features/Jobs/Service.purs"
check "Jobs/Page.purs exists" "test -f src/App/Features/Jobs/Page.purs"
check "Jobs/View.purs exists" "test -f src/App/Features/Jobs/View.purs"

# UI via Templates.Render (not Layout.Page as the page body API)
check "View uses Templates.Render" "grep -q 'App.Ui.Templates.Render' src/App/Features/Jobs/View.purs"
check "no class_ in View" "! grep -q 'class_' src/App/Features/Jobs/View.purs"

# Service uses the shared fetch boundary (not direct Affjax)
check "Service imports App.Data.Fetch" "grep -q 'App.Data.Fetch' src/App/Features/Jobs/Service.purs"
check "Service does not import Affjax directly" "! grep -q 'import Affjax' src/App/Features/Jobs/Service.purs"

# No cross-feature imports (Jobs must not import Posts, Home, etc.)
check "no cross-feature imports" "! grep -r 'import App.Features.Posts\|import App.Features.Home\|import App.Features.About\|import App.Features.Contact\|import App.Features.Legal' src/App/Features/Jobs/ 2>/dev/null"

# Errors as values (Either), not exceptions
check "Service returns Either" "grep -q 'Either' src/App/Features/Jobs/Service.purs"

# Route added (all langs including Pt use the same Route constructors)
check "Route has Jobs or JobList constructor" "grep -q 'Job' src/Data/Route.purs"
check "Pt route codec includes Job" "grep -A40 'routeCodec Pt' src/Data/Route.purs | grep -q 'Job'"
check "I18n has jobs entries" "grep -i 'job' src/Data/I18n.purs | grep -iv 'import\|--' | head -1 | grep -q ."

echo ""
echo "$pass passed, $fail failed"
exit $fail
