#!/usr/bin/env bun
/**
 * Regenerate docs/conventions/ui-coverage.md — App.Ui primitive ↔ DaisyUI vendor index.
 */
import { join } from "node:path";
import { globSync, readText, writeText, ROOT } from "./lib/repo.js";

const OUT = join(ROOT, "docs/conventions/ui-coverage.md");
const VENDOR_DIR = join(ROOT, "vendor/daisyui/skills/daisyui/components");
const UI_DIR = join(ROOT, "src/App/Ui");

const primitives = globSync("src/App/Ui/*.purs").sort();
const vendorDocs = globSync("vendor/daisyui/skills/daisyui/components/*.md").sort();

const vendorNames = new Set(
  vendorDocs.map((p) => p.split("/").pop().replace(".md", "")),
);

const rows = [];
for (const file of primitives) {
  const base = file.split("/").pop().replace(".purs", "");
  const content = await readText(file);
  const docMatch = content.match(
    /vendor\/daisyui\/skills\/daisyui\/components\/([a-z0-9-]+)\.md/,
  );
  const vendor = docMatch ? docMatch[1] : "—";
  rows.push({ module: `App.Ui.${base}`, vendor, file });
}

const wrapped = new Set(rows.map((r) => r.vendor).filter((v) => v !== "—"));
const unwrapped = [...vendorNames]
  .filter((n) => !wrapped.has(n))
  .sort();

const chromeOnly = [
  "drawer",
  "navbar",
  "dropdown",
  "menu",
  "footer",
  "join",
  "theme-controller",
].filter((n) => vendorNames.has(n));

let md = `# UI coverage map (generated)

Regenerate: \`make ui-coverage\`

Maps \`App.Ui\` primitives to DaisyUI vendor docs. Feature views must not import these — use \`App.Ui.Templates\` slots (\`docs/conventions/component-checklist.md\`).

## App.Ui primitives

| Module | DaisyUI doc | Source |
|---|---|---|
`;

for (const { module, vendor, file } of rows) {
  const docLink =
    vendor === "—"
      ? "—"
      : `[${vendor}](vendor/daisyui/skills/daisyui/components/${vendor}.md)`;
  md += `| \`${module}\` | ${docLink} | \`${file}\` |\n`;
}

md += `
## Page templates

| Module | Role |
|---|---|
| \`App.Ui.Templates.SiteShell\` | Site chrome (drawer, navbar, footer, theme) |
| \`App.Ui.Templates.Landing\` | Marketing landing |
| \`App.Ui.Templates.Hub\` | Card hub + optional breadcrumbs |
| \`App.Ui.Templates.Editorial\` | Long-form static |
| \`App.Ui.Templates.Feed\` | Post/list grid |
| \`App.Ui.Templates.Article\` | Article detail |

## Chrome-only (SiteShell, not App.Ui primitives)

${chromeOnly.map((c) => `- \`${c}\``).join("\n")}

## Vendor docs without App.Ui wrapper yet

${unwrapped.length === 0 ? "_All vendor components are either wrapped or chrome-only._" : unwrapped.map((c) => `- [${c}](vendor/daisyui/skills/daisyui/components/${c}.md)`).join("\n")}
`;

await writeText(OUT, md);
console.log(`Wrote ${OUT} (${rows.length} primitives, ${unwrapped.length} unwrapped vendor docs)`);
