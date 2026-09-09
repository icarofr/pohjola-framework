#!/usr/bin/env bun
/**
 * e2e/src drift gate for the data-page-* fragment-swap contract.
 *
 * App.Datastar.purs's `dataPage*Attr` constants are the single source of
 * truth for which data-page-* attributes the app actually emits/syncs
 * (docs/conventions/datastar-contracts.md). Nothing statically stops an
 * e2e spec from asserting on a data-page-* attribute that source no
 * longer defines -- that's exactly how e2e/i18n.spec.js broke CI this
 * session (it kept asserting on synced metadata after the sync script
 * was intentionally narrowed). This catches that one narrow, mechanical
 * slice of the problem: a dead data-page-* reference. It does NOT catch
 * behavioral drift (an attribute that still exists but whose value no
 * longer changes the way a test expects) -- that class needs a real
 * browser and stays Playwright/CI's job.
 */
import { globSync, ok, readText, rel, ROOT } from "./lib/repo.js";

const DATASTAR_PURS = `${ROOT}/src/App/Datastar.purs`;

const datastarSource = await readText(DATASTAR_PURS);
const definedAttrs = new Set(
  [...datastarSource.matchAll(/^dataPage\w+Attr = "(data-page-[a-z-]+)"/gm)].map(
    (m) => m[1],
  ),
);

if (definedAttrs.size === 0) {
  console.error(
    `Error: found no \`dataPage*Attr = "data-page-..."\` definitions in ${DATASTAR_PURS}. ` +
      "Either App.Datastar.purs moved/was renamed, or this script's pattern needs updating.",
  );
  process.exit(1);
}

const specFiles = globSync("e2e/*.spec.js").sort();
const unknownRefs = [];

for (const file of specFiles) {
  const content = await readText(file);
  const found = new Set(content.match(/data-page-[a-z-]+/g) ?? []);
  for (const attr of found) {
    if (!definedAttrs.has(attr)) {
      unknownRefs.push({ file: rel(file), attr });
    }
  }
}

if (unknownRefs.length === 0) {
  ok(
    `e2e specs only reference live data-page-* attributes (${[...definedAttrs].join(", ")}).`,
  );
} else {
  console.error(
    "e2e spec(s) reference a data-page-* attribute App.Datastar.purs no longer defines:",
  );
  for (const { file, attr } of unknownRefs) {
    console.error(`  ${file}: "${attr}"`);
  }
  console.error(
    `Currently defined: ${[...definedAttrs].join(", ") || "(none)"}. ` +
      "Update the spec to match the current contract, or restore the attribute if this was unintentional.",
  );
  process.exit(1);
}
