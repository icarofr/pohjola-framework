import fs from "node:fs";
import path from "node:path";

const cssPath = path.resolve("dist/css/styles.css");
const outPath = path.resolve("src/App/Layout/Styles.purs");

let css = "";
if (fs.existsSync(cssPath)) {
  css = fs.readFileSync(cssPath, "utf8").trim();
}

const escaped = JSON.stringify(css);

const purs = `-- | Inlined CSS stylesheet — compiled at build time to eliminate render-blocking CSS
module App.Layout.Styles (stylesCss) where

stylesCss :: String
stylesCss = ${escaped}
`;

fs.writeFileSync(outPath, purs, "utf8");
console.log(`[embed-css] Embedded ${css.length} bytes into ${outPath}`);
