#!/usr/bin/env bash
# Eval 07: UI page archetypes + theme contract (visionless quality gates)
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

echo "Eval 07: UI archetypes & theme"
echo ""

check "DESIGN.md defines primary color" "grep -q 'primary: \"#047857\"' DESIGN.md"
check "css/input.css uses pohjola theme" "grep -q 'name: \"pohjola\"' css/input.css"
check "theme verify script exists" "test -x scripts/verify-theme.sh"

check "Home uses landingPage" "grep -q 'landingPage' src/App/Features/Home/View.purs"
check "Contact uses hubPage" "grep -q 'hubPage' src/App/Features/Contact/View.purs"
check "About uses editorialPage" "grep -q 'editorialPage' src/App/Features/About/View.purs"
check "Posts list uses feedPage" "grep -q 'feedPage' src/App/Features/Posts/View.purs"
check "Posts list uses teaserCard" "grep -q 'teaserCard' src/App/Features/Posts/Components/PostCard.purs"
check "Posts list avoids actionCard" "! grep -q 'actionCard' src/App/Features/Posts/View.purs"

check "no btn-secondary class in App.Ui" "! grep -rq '\"btn-secondary' src/App/Ui/ 2>/dev/null"
check "ButtonSecondary maps to btn-outline" "grep -q 'ButtonSecondary -> \"btn-outline\"' src/App/Ui/Button.purs"

check "PageSection blueprint exists" "test -f src/App/Ui/Layout/PageSection.purs"
check "HubPage blueprint exists" "test -f src/App/Ui/Layout/HubPage.purs"
check "FeedPage blueprint exists" "test -f src/App/Ui/Layout/FeedPage.purs"
check "Hero frozen recipe" "grep -q 'heroSectionClass' src/App/Ui/Layout/Hero.purs"
check "Hero avoids max-w-md slab" "! grep -q 'max-w-md' src/App/Ui/Layout/Hero.purs"
check "Hero uses base canvas not gray band" "grep -q 'bg-base-100' src/App/Ui/Layout/Hero.purs && ! grep -q 'bg-base-200' src/App/Ui/Layout/Hero.purs"

check "EmptyState frozen card recipe" "grep -q 'emptyStateCardClass' src/App/Ui/EmptyState.purs"
check "EmptyState avoids hero slab" "! grep -q 'hero bg-base-200' src/App/Ui/EmptyState.purs"
check "ActionCard frozen CTA variant" "grep -q 'actionCardCtaVariant' src/App/Ui/Layout/ActionCard.purs"
check "ArticlePage frozen byline" "grep -q 'authorBylineClass' src/App/Ui/Layout/ArticlePage.purs"

check "Header avoids shadow-lg dropdowns" "! grep -q 'shadow-lg' src/App/Layout/Header.purs"
check "Header mobile lang avoids btn-primary" "! grep -q 'btn-primary' src/App/Layout/Header.purs"
check "Footer uses base canvas" "grep -q 'bg-base-100' src/App/Layout/Footer.purs && ! grep -q 'bg-base-200' src/App/Layout/Footer.purs"
check "Page error content uses theme tokens" "grep -q 'text-primary' src/App/Layout/Page.purs && ! grep -q 'text-gray-900' src/App/Layout/Page.purs"
check "Page form status uses Alert" "grep -q 'Alert.alert' src/App/Layout/Page.purs"

echo ""
echo "$pass passed, $fail failed"
exit $fail
