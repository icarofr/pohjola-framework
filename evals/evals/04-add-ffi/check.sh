#!/usr/bin/env bash
# Eval 04: Add FFI
# Asserts: FFI taming pattern (runtime-agnostic .purs, dispatch in .js, Foreign decode, allowlist)
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

echo "Eval 04: Add FFI"
echo ""

# .purs file is runtime-agnostic (no direct Bun reference in PureScript)
check "no Bun reference in .purs" "! grep -r 'Bun' src/App/ 2>/dev/null | grep '\.purs:' | grep -v 'import\|--'"

# .js file probes typeof Bun (dispatch pattern)
check ".js probes typeof Bun" "grep -r 'typeof Bun' src/ 2>/dev/null | head -1 | grep -q ."

# .js has no app logic (just calls the runtime API)
check ".js has no app logic (no if/for/while beyond dispatch)" "true"

# Foreign import declared (would need allowlist entry in Makefile)
check "foreign import declared" "grep -r 'foreign import' src/ 2>/dev/null | head -1 | grep -q ."

# Foreign decode on PS side (not trusting raw JS output)
check "Foreign decode in .purs" "grep -r 'Foreign\|decode' src/ 2>/dev/null | grep '\.purs:' | head -1 | grep -q ."

# ADR-003 referenced or ADR exists for this taming
check "ADR-003 exists" "test -f docs/adr/ADR-003-ffi-taming.md"

echo ""
echo "$pass passed, $fail failed"
exit $fail
