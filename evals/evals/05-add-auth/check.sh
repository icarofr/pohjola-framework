#!/usr/bin/env bash
# Eval 05: Add auth
# Asserts: routes through App.Auth (not inline), no Ref Map storage, no JWT
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

echo "Eval 05: Add auth"
echo ""

# Uses App.Auth module (not inline auth checks)
check "imports App.Auth" "grep -r 'App.Auth' src/ 2>/dev/null | grep -v 'App/Auth.purs' | head -1 | grep -q ."
check "uses requireAuth" "grep -r 'requireAuth' src/ 2>/dev/null | grep -v 'App/Auth.purs' | head -1 | grep -q ."
check "uses createSession or destroySession" "grep -r 'createSession\|destroySession' src/ 2>/dev/null | grep -v 'App/Auth.purs' | head -1 | grep -q ."

# No inline session checks in App.Main or feature modules
check "no inline session Ref in App.Main" "! grep 'Ref.*Map.*Session\|Ref.*Map.*session' src/App/Main.purs 2>/dev/null"

# No JWT (ADR-002 default is session cookies)
check "no jose or jsonwebtoken" "! grep -ri 'jose\|jsonwebtoken' src/ 2>/dev/null"

# Dashboard route exists
check "Route has Dashboard" "grep -q 'Dashboard' src/Data/Route.purs"

# No raw password storage (no plaintext passwords in code)
check "no plaintext password storage" "! grep -ri 'password.*=.*\"' src/App/ 2>/dev/null | grep -v 'test\|Test\|--\|import'"

echo ""
echo "$pass passed, $fail failed"
exit $fail
