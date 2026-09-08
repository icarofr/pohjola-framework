#!/usr/bin/env bun
/**
 * Regenerate docs/conventions/ui-coverage.md — App.Ui primitive ↔ DaisyUI vendor index.
 *
 * --check: don't write, compare the freshly-generated content against the
 * committed file and exit 1 if they differ. Catches exactly the bug this
 * flag was added for: a regen that ran without vendor/daisyui checked out
 * (globSync returns nothing, silently blanking the "unwrapped" list) got
 * committed as if it were correct, and nothing caught it until a later,
 * unrelated session noticed by inspection.
 */
import { join } from "node:path";
import { exists, globSync, readText, writeText, ROOT } from "./lib/repo.js";

const CHECK = process.argv.includes("--check");
const OUT = join(ROOT, "docs/conventions/ui-coverage.md");
const VENDOR_DIR = join(ROOT, "vendor/daisyui/skills/daisyui/components");
const UI_DIR = join(ROOT, "src/App/Ui");

// Bun.file(path).exists() only answers for files, not directories, so a
// glob against the vendor dir is the actual signal: zero matches means
// either the submodule isn't checked out or DaisyUI genuinely shipped no
// component docs, and there's no way to tell those apart from here — both
// make regenerating unsafe.
if (globSync("vendor/daisyui/skills/daisyui/components/*.md").length === 0) {
  console.error(
    `Error: no .md files under ${VENDOR_DIR}. The vendor/daisyui submodule isn't checked out ` +
      `(run \`make deps\`, or \`git submodule update --init --depth 1 vendor/daisyui\`). ` +
      `Regenerating without it would silently blank the "unwrapped" list, which is the exact` +
      ` bug this check exists to catch — refusing to run.`,
  );
  process.exit(1);
}

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
| \`App.Ui.Templates.Schedule\` | Fixture/match list |
| \`App.Ui.Templates.Form\` | Form page (fieldset + submit) |

## Chrome-only (SiteShell, not App.Ui primitives)

${chromeOnly.map((c) => `- \`${c}\``).join("\n")}

## Vendor docs without App.Ui wrapper yet

${unwrapped.length === 0 ? "_All vendor components are either wrapped or chrome-only._" : unwrapped.map((c) => `- [${c}](vendor/daisyui/skills/daisyui/components/${c}.md)`).join("\n")}
`;

if (CHECK) {
  const current = (await exists(OUT)) ? await readText(OUT) : "";
  if (current === md) {
    console.log(`OK: docs/conventions/ui-coverage.md matches a fresh regen (${rows.length} primitives, ${unwrapped.length} unwrapped).`);
  } else {
    console.error(
      "docs/conventions/ui-coverage.md is stale — it doesn't match what `make ui-coverage` " +
        "would generate right now. Run `make ui-coverage` and commit the result.",
    );
    process.exit(1);
  }
} else {
  await writeText(OUT, md);
  console.log(`Wrote ${OUT} (${rows.length} primitives, ${unwrapped.length} unwrapped vendor docs)`);
}
