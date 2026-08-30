#!/usr/bin/env bun
import { join } from "node:path";
import { file } from "bun";
import { ROOT, readText, writeText } from "./lib/repo.js";

const cssPath = join(ROOT, "dist/css/styles.css");
const outPath = join(ROOT, "src/App/Layout/Styles.purs");

let css = "";
if (await file(cssPath).exists()) {
  css = (await readText(cssPath)).trim();
}

const escaped = JSON.stringify(css);

const purs = `-- | Inlined CSS stylesheet — compiled at build time to eliminate render-blocking CSS
module App.Layout.Styles (stylesCss) where

stylesCss :: String
stylesCss = ${escaped}
`;

await writeText(outPath, purs);
console.log(`[embed-css] Embedded ${css.length} bytes into ${outPath}`);
