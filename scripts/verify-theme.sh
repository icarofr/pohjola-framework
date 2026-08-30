#!/usr/bin/env bash
# Fail if compiled CSS does not embed DESIGN.md primary (#047857) or App.Ui uses Daisy btn-secondary.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p dist/css
bun x @tailwindcss/cli -i css/input.css -o dist/css/styles.css --minify

if ! grep -qi '047857' dist/css/styles.css; then
  echo "ERROR: dist/css/styles.css missing DESIGN.md primary (#047857)"
  exit 1
fi

if grep -rq '"btn-secondary' src/App/Ui/ src/App/Layout/ 2>/dev/null; then
  echo "ERROR: btn-secondary class in App.Ui/App.Layout — use ButtonVariant intents"
  exit 1
fi

if grep -rq "setAttribute('data-theme', 'light')" src/App/ 2>/dev/null; then
  echo "ERROR: Alpine/theme JS sets data-theme to 'light' — use App.Theme.daisyThemeLight (pohjola)"
  exit 1
fi

if grep -rq "setAttribute('data-theme', 'dark')" src/App/ 2>/dev/null; then
  echo "ERROR: Alpine/theme JS sets data-theme to 'dark' — use App.Theme.daisyThemeDark (pohjola-dark)"
  exit 1
fi

if ! grep -q 'pohjola-dark' src/App/Theme.purs; then
  echo "ERROR: App.Theme.purs missing pohjola-dark theme name"
  exit 1
fi

echo "Theme verification OK"
