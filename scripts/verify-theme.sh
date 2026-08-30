#!/usr/bin/env bash
# Theme build artifact check — compiled CSS must embed DESIGN.md primary.
# String/theme-name policy lives in policy/manifest.json + PolicySpec.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/policy/manifest.json"
cd "$ROOT"

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required for verify-theme.sh"
  exit 1
fi

PRIMARY="$(jq -r '.theme.cssPrimaryHex' "$MANIFEST")"

mkdir -p dist/css
bun x @tailwindcss/cli -i css/input.css -o dist/css/styles.css --minify

if ! grep -qi "$PRIMARY" dist/css/styles.css; then
  echo "ERROR: dist/css/styles.css missing DESIGN.md primary (#$PRIMARY)"
  exit 1
fi

echo "Theme build OK (#$PRIMARY in compiled CSS)"
