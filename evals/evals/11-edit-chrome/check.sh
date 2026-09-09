#!/usr/bin/env bash
# Eval 11: Edit site chrome — add a nav item the DaisyUI way
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

echo "Eval 11: Edit site chrome"
echo ""

check "Team route exists" "grep -q 'Team' src/Data/Route.purs"
check "Team page exists" "test -f src/App/Features/Team/Page.purs"
check "Team linked in SiteShell" "grep -q 'Team' src/App/Ui/Templates/SiteShell.purs"
check "uses navLinkClasses for chrome" "grep -q 'navLinkClasses NavDesktop' src/App/Ui/Templates/SiteShell.purs"
check "uses navLinkClasses for mobile" "grep -q 'navLinkClasses NavMobile' src/App/Ui/Templates/SiteShell.purs"
check "i18n has team copy" "grep -i 'team' src/Data/I18n.purs | grep -iv 'import\|--' | head -1 | grep -q ."
check "chrome uses a DESIGN.md color, not neutral-only (design-system.md #9)" "grep -qE 'text-primary|bg-secondary|text-secondary-content|text-accent|bg-accent' src/App/Ui/Templates/SiteShell.purs"
check "header and footer both wrap in Container.container (design-system.md #10)" "[ \$(grep -c 'Container.container' src/App/Ui/Templates/SiteShell.purs) -ge 2 ]"

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
