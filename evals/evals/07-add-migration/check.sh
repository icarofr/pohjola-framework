#!/usr/bin/env bash
# Eval 07: Add database migration
# Asserts: Migration placed in migrations/, numbered prefix, valid SQL syntax, no down-migrations (ADR-009)
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

echo "Eval 07: Add database migration"
echo ""

# Migration file exists with numbered prefix
check "migration file exists in migrations/" "ls migrations/*tags*.sql >/dev/null 2>&1"
check "migration has numbered prefix" "ls migrations/[0-9][0-9][0-9]_*.sql >/dev/null 2>&1"

# Migration content checks
check "creates tags table" "grep -qi 'CREATE TABLE' migrations/*tags*.sql 2>/dev/null"
check "defines post_id column" "grep -qi 'post_id' migrations/*tags*.sql 2>/dev/null"
check "no down migration files (ADR-009)" "! ls migrations/*.down.sql >/dev/null 2>&1"

# Safe SQL checks
check "no arbitrary foreign imports in migration" "! grep -rn 'foreign import' migrations/ 2>/dev/null"

echo ""
echo "$pass passed, $fail failed"
exit $fail
