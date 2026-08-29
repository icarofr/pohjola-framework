#!/usr/bin/env bash
set -euo pipefail

# Exercise the canonical generator outside the checkout.  The copy includes the
# lockfile and local tool configuration, but never writes to the real tree.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/pohjola-generator.XXXXXX")"
TMP_SECOND="$(mktemp -d "${TMPDIR:-/tmp}/pohjola-generator.XXXXXX")"
cleanup() {
  rm -rf "$TMP"
  rm -rf "$TMP_SECOND"
}
trap cleanup EXIT

cp -R "$ROOT/." "$TMP/"
cp -R "$ROOT/." "$TMP_SECOND/"

run_fixture() {
  local name="$1" type="$2" slug="$3"
  local lower="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
  bun scripts/auto-scaffold.js --name="$name" --type="$type" \
    --slug-en="$slug" --slug-fr="$slug" --wire

  local route="src/Data/Route.purs" main="src/App/Main.purs" i18n="src/Data/I18n.purs" head="src/App/Layout/Head.purs"
  for marker in "| $name" "${name} -> \"$name\"" "\"$name\": \"$slug\"" "prefetchFor $name ="; do
    grep -Fq "$marker" "$route" || { echo "Missing Route insertion: $marker" >&2; return 1; }
  done
  [[ "$(grep -Fc "\"$name\": \"$slug\"" "$route")" -ge 2 ]] || { echo "Missing one Route codec insertion: $name" >&2; return 1; }
  grep -Fq "${name} -> d.nav.${lower}" "$route" || { echo "Missing Route title insertion: $name" >&2; return 1; }
  grep -Fq "${name} ->" "$main" || { echo "Missing Main insertion: $name" >&2; return 1; }
  grep -Fq "${name}." "$main" || { echo "Missing Main renderer insertion: $name" >&2; return 1; }
  grep -Fq "${name} -> cached" "$main" || { echo "Missing Main handler insertion: $name" >&2; return 1; }
  grep -Fq "${lower} :: String" "$i18n" || { echo "Missing I18n type insertion: $name" >&2; return 1; }
  grep -Fq "${lower}: \"$name\"" "$i18n" || { echo "Missing I18n English insertion: $name" >&2; return 1; }
  [[ "$(grep -Fc "${lower}: \"$name\"" "$i18n")" -ge 2 ]] || { echo "Missing I18n French insertion: $name" >&2; return 1; }
  grep -Fq "  , ${lower}:" "$i18n" || { echo "Missing I18n dictionary section: $name" >&2; return 1; }
  grep -Fq "${name} -> d.${lower}.body" "$head" || { echo "Missing Head insertion: $name" >&2; return 1; }
}

run_copy() {
  local copy="$1"
  (
    cd "$copy"
    run_fixture FixtureStatic static fixture-static
    run_fixture FixtureData data fixture-data
    bun x spago build --pure --strict
  )
}

run_copy "$TMP"

# Compare against a separate clean copy so the first generated feature
# directories and all of their wiring are restored together.  Do not use git
# diff here: strict builds can alter checkout metadata without changing the
# generated files.
run_copy "$TMP_SECOND"

for wired in src/Data/Route.purs src/App/Main.purs src/Data/I18n.purs src/App/Layout/Head.purs; do
  if ! cmp "$TMP/$wired" "$TMP_SECOND/$wired"; then
    echo "Generator is not idempotent: $wired" >&2
    exit 1
  fi
done

for feature in FixtureStatic FixtureData; do
  feature_path="src/App/Features/$feature"
  if ! diff -ru "$TMP/$feature_path" "$TMP_SECOND/$feature_path"; then
    echo "Generator is not idempotent: $feature_path" >&2
    exit 1
  fi
done

echo "Generator policy OK (static/data clean-copy fixtures, strict build, idempotence)"
