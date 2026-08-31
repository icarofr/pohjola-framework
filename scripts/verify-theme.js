#!/usr/bin/env bun
/**
 * Theme build artifact check — compiled CSS must embed DESIGN.md primary.
 */
import { join } from "node:path";
import { fail, readText, run, ROOT } from "./lib/repo.js";

const cssInput = await readText(join(ROOT, "css", "input.css"));
const match = cssInput.match(/--color-primary:\s*#([0-9a-fA-F]+)/);
if (!match) {
  fail("css/input.css missing --color-primary declaration");
}
const primary = match[1];
const outFile = join(ROOT, "dist", "css", "styles.css");

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
