#!/usr/bin/env bun
/**
 * Sync policy/manifest.json uiClassPolicy.allowedTokens from App/Ui Purs class strings.
 */
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { globSync, ROOT } from "./lib/repo.js";

const manifestPath = join(ROOT, "policy/manifest.json");
const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));

const tokenRe = /class_\s+"([^"]+)"/g;
const tokens = new Set();

for (const file of globSync("src/App/Ui/**/*.purs")) {
  const src = readFileSync(file, "utf8");
  let m;
  while ((m = tokenRe.exec(src)) !== null) {
    for (const part of m[1].split(/\s+/)) {
      if (part) tokens.add(part);
    }
  }
}

const sorted = [ ...tokens ].sort();
const prev = new Set(manifest.uiClassPolicy.allowedTokens);
const added = sorted.filter((t) => !prev.has(t));
const removed = [ ...prev ].filter((t) => !tokens.has(t));

manifest.uiClassPolicy.allowedTokens = sorted;
writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + "\n");

console.log(`[sync-ui-policy] ${sorted.length} allowed tokens (${added.length} added, ${removed.length} removed)`);
if (added.length) console.log("  +", added.slice(0, 40).join(", "), added.length > 40 ? "..." : "");
if (removed.length) console.log("  -", removed.slice(0, 40).join(", "), removed.length > 40 ? "..." : "");
