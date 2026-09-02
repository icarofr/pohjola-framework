#!/usr/bin/env bash
# Eval 12: DaisyUI component / template slot discipline
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

echo "Eval 12: UI component / template slots"
echo ""

check "App.Ui.Breadcrumbs exists" "test -f src/App/Ui/Breadcrumbs.purs"
check "page-header-breadcrumbs marker" "grep -q 'pageHeaderBreadcrumbs' src/App/Ui/Templates/Contract.purs"
check "Contact uses breadcrumbs" "grep -q 'breadcrumb' src/App/Features/Contact/View.purs"
check "About has no class_" "! grep -q 'class_' src/App/Features/About/View.purs"
check "About view has no App.Ui primitive imports" "! grep -E 'import App\\.Ui\\.[A-Z][a-zA-Z]+' src/App/Features/About/View.purs | grep -v 'App\\.Ui\\.Templates' | grep -q ."

echo ""
echo "Running gate + tests..."
if make gate && make test; then
  echo "  ✓ make gate && make test"
  pass=$((pass + 1))
else
  echo "  ✗ make gate && make test"
  fail=$((fail + 1))
fi

echo ""
echo "$pass passed, $fail failed"
exit $fail
