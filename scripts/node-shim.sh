#!/usr/bin/env bash
args=()
for arg in "$@"; do
  case "$arg" in
    --no-warnings=*) args+=("--no-warnings") ;;
    *) args+=("$arg") ;;
  esac
done
exec bun "${args[@]}"
