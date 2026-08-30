#!/usr/bin/env bun
/**
 * Theme build artifact check — compiled CSS must embed DESIGN.md primary.
 */
import { join } from "node:path";
import { fail, readText, run } from "./lib/repo.js";
import { readManifest } from "./lib/policy.js";

const manifest = await readManifest();
const primary = manifest.theme.cssPrimaryHex;
const outFile = join(import.meta.dir, "..", "dist", "css", "styles.css");

run([
  "bun",
  "x",
  "@tailwindcss/cli",
  "-i",
  "css/input.css",
  "-o",
  "dist/css/styles.css",
  "--minify",
]);

const css = await readText(outFile);
if (!css.toLowerCase().includes(primary.toLowerCase())) {
  fail(`dist/css/styles.css missing DESIGN.md primary (#${primary})`);
}

console.log(`Theme build OK (#${primary} in compiled CSS)`);
