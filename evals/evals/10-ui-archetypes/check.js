#!/usr/bin/env bun
/**
 * Eval 10: UI archetypes — policy tier + agent doc contracts.
 */
import { ROOT, exists, readText, run } from "../../../scripts/lib/repo.js";

process.chdir(ROOT);

console.log("Eval 10: UI archetypes & theme (policy tier)");
console.log("");

const pageArchitectures =
  "docs/superpowers/specs/2026-08-31-page-architectures.md";
const componentChecklist = "docs/conventions/component-checklist.md";
const designSystem = "docs/conventions/design-system.md";
const uiBlueprint = "docs/superpowers/specs/2026-08-30-ui-blueprint-recipe.md";

if (!(await exists(pageArchitectures))) {
  console.error(`ERROR: missing ${pageArchitectures}`);
  process.exit(1);
}

const checklist = await readText(componentChecklist);
const design = await readText(designSystem);
const blueprint = await readText(uiBlueprint);
const architectures = await readText(pageArchitectures);

const required = [
  [ "component-checklist documents Schedule", () => checklist.includes("`Schedule`") ],
  [ "component-checklist warns against Feed for schedules", () => checklist.includes("Do not") && checklist.includes("Schedule") ],
  [ "design-system documents Schedule", () => design.includes("`Schedule`") ],
  [ "design-system documents Form", () => design.includes("`Form`") ],
  [ "ui-blueprint points at page-architectures", () => blueprint.includes("2026-08-31-page-architectures.md") ],
  [ "page-architectures lists Feed anti-pattern", () => architectures.includes("Feed") && architectures.includes("Schedule") ],
  [ "page-architectures references vendor daisyUI skills", () => architectures.includes("vendor/daisyui/skills") ],
];

let failed = 0;
for (const [label, ok] of required) {
  if (ok()) {
    console.log(`  ✓ ${label}`);
  } else {
    console.error(`  ✗ ${label}`);
    failed += 1;
  }
}

if (failed > 0) {
  process.exit(failed);
}

run(["make", "gate"]);
run(["bun", "scripts/verify-theme.js"]);

console.log("");
console.log("Running tests (includes TemplateContractSpec + PolicySpec)...");
run(["make", "test"]);

console.log("");
console.log("Eval 10 OK");
