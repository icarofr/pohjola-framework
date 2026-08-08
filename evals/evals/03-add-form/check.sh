#!/usr/bin/env bash
# Eval 03: Add a form
# Asserts: App.Form contract (honeypot, Submission type, decode), no client-side JS
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

echo "Eval 03: Add a form"
echo ""

# Uses the App.Form contract (not a hand-rolled form decoder)
check "imports App.Form" "grep -r 'App.Form' src/App/Features/ 2>/dev/null | grep -iv 'import App.Form (FormStatus)' | head -1 | grep -q ."

# Honeypot field present (the "website" field is the honeypot in App.Form)
check "honeypot field (website)" "grep -ri 'website' src/App/Features/ 2>/dev/null | grep -iv 'import\|--' | head -1 | grep -q ."

# No client-side JS (no x-data with functions, no onSubmit, no fetch in views)
check "no onSubmit in views" "! grep -r 'onSubmit\|@submit' src/App/Features/ 2>/dev/null | grep -v '.purs'"
check "no client-side fetch" "! grep -r 'fetch(' src/App/Features/ 2>/dev/null | grep -v '.purs'"

# Decode returns a Submission type (pattern matching on variants)
check "has Submission type" "grep -r 'Submission' src/App/ 2>/dev/null | grep -iv 'import\|--' | head -1 | grep -q ."

# Form posts to same origin (no external action URLs)
check "no external form action" "! grep -r 'action=\"http' src/App/Features/ 2>/dev/null"

echo ""
echo "$pass passed, $fail failed"
exit $fail
