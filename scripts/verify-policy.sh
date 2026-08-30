#!/usr/bin/env bash
# Structural policy gate — reads policy/manifest.json (single source of truth).
# Behavioral policy (rendered HTML, cross-feature imports) runs in PolicySpec via make test.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/policy/manifest.json"
cd "$ROOT"

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required for verify-policy.sh"
  exit 1
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: missing $MANIFEST"
  exit 1
fi

fail() {
  echo "ERROR: $1"
  exit 1
}

echo "Policy gate (policy/manifest.json)"

# Banned substrings anywhere in src/
while IFS= read -r pattern; do
  if [[ "$pattern" == "Partial" ]]; then
    if grep -rnE '\bPartial\b' src/ >/dev/null 2>&1; then
      echo "Banned pattern in src/: $pattern"
      grep -rnE '\bPartial\b' src/ | head -5
      exit 1
    fi
  elif grep -rnF "$pattern" src/ >/dev/null 2>&1; then
    echo "Banned pattern in src/: $pattern"
    grep -rnF "$pattern" src/ | head -5
    exit 1
  fi
done < <(jq -r '.bannedSubstrings[]' "$MANIFEST")
echo "  ✓ no banned functions in src/"

# raw/Raw whole-word ban (Makefile historical check)
if grep -rnE '\braw\b|\bRaw\b' src/ >/dev/null 2>&1; then
  fail "raw/Raw found in src/ — Html ADT has no Raw constructor"
fi
echo "  ✓ no raw/Raw in src/"

# FFI allowlist
ffi_allow="$(jq -r '.ffiAllowlist[]' "$MANIFEST" | paste -sd '|' -)"
if grep -rn 'foreign import' src/ | grep -vE "$ffi_allow"; then
  fail "foreign import outside FFI allowlist"
fi
echo "  ✓ FFI allowlist"

# Script elements
script_allow="$(jq -r '.scriptAllowlist[]' "$MANIFEST" | sed 's/^/^/' | sed 's/$/:/' | paste -sd '|' -)"
if grep -rn 'el "script"' src/ | grep -vE "$script_allow"; then
  fail "script elements outside App.Layout.Scripts/Page"
fi
echo "  ✓ script allowlist"

# Env reads
env_allow="$(jq -r '.envReadAllowlist[]' "$MANIFEST" | sed 's/^/^/' | sed 's/$/:/' | paste -sd '|' -)"
if grep -rn 'Node.Process\|lookupEnv' src/ | grep -vE "$env_allow"; then
  fail "env read outside App/Env.purs"
fi
echo "  ✓ env read allowlist"

# Content firewall
if grep -rn 'text "[A-Za-z0-9]' src/App/Features/*/View.purs 2>/dev/null; then
  fail "hardcoded text in feature View.purs — use Data.I18n"
fi
echo "  ✓ content firewall"

# Feature view forbidden patterns
while IFS= read -r pattern; do
  if grep -rn "$pattern" src/App/Features/*/View.purs src/App/Features/*/Components/*.purs 2>/dev/null; then
    fail "forbidden pattern in feature views: $pattern"
  fi
done < <(jq -r '.forbiddenInFeatureViews[]' "$MANIFEST")
echo "  ✓ feature view UI contract"

# App.Ui forbidden patterns
while IFS= read -r pattern; do
  if grep -rq "$pattern" src/App/Ui/ src/App/Layout/ 2>/dev/null; then
    fail "forbidden pattern in App.Ui/Layout: $pattern"
  fi
done < <(jq -r '.forbiddenInAppUi[]' "$MANIFEST")
echo "  ✓ App.Ui intent policy"

# Text tone seam (ADR-008)
TEXT_TONE_PATTERN="$(jq -r '.textTone.pattern' "$MANIFEST")"
TEXT_TONE_ALLOW="$(jq -r '.textTone.allowlist[]' "$MANIFEST" | sed 's/^/^/' | paste -sd '|' -)"
if grep -rn "$TEXT_TONE_PATTERN" src/ | grep -vE "$TEXT_TONE_ALLOW"; then
  fail "raw text-base-content opacity outside App.Ui.TextTone"
fi
echo "  ✓ text tone policy"

# Theme string drift
while IFS= read -r literal; do
  if grep -rq "$literal" src/App/ 2>/dev/null; then
    fail "forbidden theme literal in src/App: $literal"
  fi
done < <(jq -r '.theme.forbiddenDataThemeLiterals[]' "$MANIFEST")

DAISY_LIGHT="$(jq -r '.theme.daisyLight' "$MANIFEST")"
DAISY_DARK="$(jq -r '.theme.daisyDark' "$MANIFEST")"
THEME_MODULE="$(jq -r '.theme.themeModule' "$MANIFEST")"
grep -q "$DAISY_LIGHT" "$THEME_MODULE" || fail "$THEME_MODULE missing $DAISY_LIGHT"
grep -q "$DAISY_DARK" "$THEME_MODULE" || fail "$THEME_MODULE missing $DAISY_DARK"
echo "  ✓ theme module names"

echo "Policy gate OK"
