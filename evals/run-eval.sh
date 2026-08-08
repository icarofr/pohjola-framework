#!/usr/bin/env bash
# Run an agent eval.
#
# Usage:
#   ./evals/run-eval.sh <name>           # show the prompt
#   ./evals/run-eval.sh <name> --check   # run assertions
#   ./evals/run-eval.sh                  # list available evals
#
set -euo pipefail

EVALS_DIR="$(cd "$(dirname "$0")" && pwd)/evals"

# No args: list available evals
if [ $# -lt 1 ]; then
  echo "Available evals:"
  for d in "$EVALS_DIR"/*/; do
    [ -d "$d" ] && echo "  $(basename "$d")"
  done
  exit 0
fi

EVAL="$1"
EVAL_DIR="$EVALS_DIR/$EVAL"

if [ ! -d "$EVAL_DIR" ]; then
  echo "Eval not found: $EVAL"
  echo "Available: $(ls -1 "$EVALS_DIR" 2>/dev/null | tr '\n' ' ')"
  exit 1
fi

if [ "${2:-}" = "--check" ]; then
  echo "Checking: $EVAL"
  echo ""
  bash "$EVAL_DIR/check.sh"
else
  echo "=== Prompt ==="
  echo ""
  cat "$EVAL_DIR/PROMPT.md"
  echo ""
  echo "=== Instructions ==="
  echo "1. Read the prompt above"
  echo "2. Implement the change in this repo"
  echo "3. Run: ./evals/run-eval.sh $EVAL --check"
  echo "4. All checks must pass. Fix and re-check if any fail."
  echo "5. Then run: make check"
fi
