#!/usr/bin/env bun
/**
 * App.Bun FFI surface tripwire — informational, like `make audit`. Never
 * fails the build. Diffs the live Bun.* surface reached from src/App/Bun.js
 * against a checked-in baseline (scripts/bun-ffi-surface.json) and prints
 * what changed, so a growing FFI surface is visible instead of relying
 * purely on review discipline (App.Bun is the one FFI module exempt from
 * needing a new Policy.Contract allowlist entry per addition).
 */
import { join, ok, readText, ROOT } from "./lib/repo.js";

const BUN_PURS = join(ROOT, "src/App/Bun.purs");
const BUN_JS = join(ROOT, "src/App/Bun.js");
const BASELINE_PATH = join(ROOT, "scripts/bun-ffi-surface.json");

const pursSource = await readText(BUN_PURS);
const jsSource = await readText(BUN_JS);
const baseline = JSON.parse(await readText(BASELINE_PATH));

const foreignImportCount = (pursSource.match(/^foreign import /gm) ?? []).length;

// Strip `//` line comments first — this file's header/doc comments mention
// Bun.* names in prose (including its own "App.Bun.js" filename), which
// would otherwise pollute the surface extracted from real code.
const jsCodeOnly = jsSource
  .split("\n")
  .map((line) => line.replace(/\/\/.*$/, ""))
  .join("\n");

const bunGlobals = [
  ...new Set(jsCodeOnly.match(/\bBun\.[A-Za-z_$][\w$]*(?:\.[A-Za-z_$][\w$]*)*/g) ?? []),
].sort();

const addedGlobals = bunGlobals.filter((g) => !baseline.bunGlobals.includes(g));
const removedGlobals = baseline.bunGlobals.filter((g) => !bunGlobals.includes(g));
const countDelta = foreignImportCount - baseline.foreignImportCount;

if (addedGlobals.length === 0 && removedGlobals.length === 0 && countDelta === 0) {
  ok(`App.Bun FFI surface unchanged (${foreignImportCount} foreign imports, ${bunGlobals.length} Bun.* globals).`);
} else {
  console.log("⚠ App.Bun FFI surface changed since scripts/bun-ffi-surface.json was last updated:");
  if (countDelta !== 0) {
    console.log(`  foreign import count: ${baseline.foreignImportCount} -> ${foreignImportCount}`);
  }
  for (const g of addedGlobals) console.log(`  + ${g}`);
  for (const g of removedGlobals) console.log(`  - ${g}`);
  console.log("  Informational only — this does not fail the build.");
  console.log("  If intentional, update scripts/bun-ffi-surface.json to re-arm this check.");
}
