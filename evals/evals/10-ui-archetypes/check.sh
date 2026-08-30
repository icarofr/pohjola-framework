#!/usr/bin/env bash
# Eval 10: UI archetypes — delegates to canonical policy enforcement.
# Structural: policy/manifest.json + scripts/verify-policy.sh (make gate).
# Behavioral: Test.PolicySpec inside make test.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"

echo "Eval 10: UI archetypes & theme (policy tier)"
echo ""

make gate
bash scripts/verify-theme.sh

echo ""
echo "Running tests (includes PolicySpec behavioral checks)..."
make test

echo ""
echo "Eval 10 OK"
