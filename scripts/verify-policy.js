#!/usr/bin/env bun
/**
 * Structural policy gate — reads policy/manifest.json (single source of truth).
 * Behavioral policy runs in PolicySpec via make test.
 */
import { join } from "node:path";
import {
  ROOT,
  fail,
  globSync,
  ok,
  readText,
  rel,
} from "./lib/repo.js";
import { readManifest, srcSourceFiles } from "./lib/policy.js";

process.chdir(ROOT);

const manifest = await readManifest();

console.log("Policy gate (policy/manifest.json)");

// Banned substrings anywhere in src/
for (const pattern of manifest.bannedSubstrings) {
  const hits = [];
  for (const file of srcSourceFiles()) {
    const content = await readText(file);
    const match =
      pattern === "Partial"
        ? /\bPartial\b/.test(content)
        : content.includes(pattern);
    if (match) {
      hits.push(rel(file));
    }
  }
  if (hits.length > 0) {
    console.error(`Banned pattern in src/: ${pattern}`);
    for (const hit of hits.slice(0, 5)) {
      console.error(hit);
    }
    process.exit(1);
  }
}
ok("no banned functions in src/");

// raw/Raw whole-word ban
for (const file of srcSourceFiles()) {
  const content = await readText(file);
  if (/\braw\b|\bRaw\b/.test(content)) {
    fail("raw/Raw found in src/ — Html ADT has no Raw constructor");
  }
}
ok("no raw/Raw in src/");

// FFI allowlist
for (const file of srcSourceFiles()) {
  const r = rel(file);
  const content = await readText(file);
  if (content.includes("foreign import") && !manifest.ffiAllowlist.includes(r)) {
    console.error(`foreign import outside FFI allowlist: ${r}`);
    process.exit(1);
  }
}
ok("FFI allowlist");

// Script elements
for (const file of srcSourceFiles()) {
  const r = rel(file);
  const content = await readText(file);
  if (
    content.includes('el "script"') &&
    !manifest.scriptAllowlist.includes(r)
  ) {
    console.error(`script elements outside App.Layout.Scripts/Page: ${r}`);
    process.exit(1);
  }
}
ok("script allowlist");

// Env reads
for (const file of srcSourceFiles()) {
  const r = rel(file);
  const content = await readText(file);
  if (
    (content.includes("Node.Process") || content.includes("lookupEnv")) &&
    !manifest.envReadAllowlist.includes(r)
  ) {
    console.error(`env read outside App/Env.purs: ${r}`);
    process.exit(1);
  }
}
ok("env read allowlist");

// Content firewall
const viewFiles = globSync("src/App/Features/*/View.purs");
for (const file of viewFiles) {
  const content = await readText(file);
  const hits = content
    .split("\n")
    .filter((line) => /text "[A-Za-z0-9]/.test(line));
  if (hits.length > 0) {
    console.error(hits.join("\n"));
    fail("hardcoded text in feature View.purs — use Data.I18n");
  }
}
ok("content firewall");

// Feature view forbidden patterns
const featureFiles = [
  ...globSync("src/App/Features/*/View.purs"),
  ...globSync("src/App/Features/*/Components/*.purs"),
];
for (const pattern of manifest.forbiddenInFeatureViews) {
  for (const file of featureFiles) {
    if ((await readText(file)).includes(pattern)) {
      console.error(`${rel(file)}: ${pattern}`);
      fail(`forbidden pattern in feature views: ${pattern}`);
    }
  }
}
ok("feature view UI contract");

// Feature view import allowlist — primitives stay inside App.Ui / Templates
const forbiddenImports = manifest.forbiddenImportsInFeatureViews ?? [];
for (const mod of forbiddenImports) {
  for (const file of featureFiles) {
    const content = await readText(file);
    if (content.includes(`import ${mod}`)) {
      console.error(`${rel(file)}: import ${mod}`);
      console.error(
        "Hint: feature views compose via App.Ui.Templates.renderPage + slot records only.",
      );
      console.error(
        "See: docs/conventions/component-checklist.md | eval: make eval EVAL=12-add-ui-component --check",
      );
      fail(`forbidden import in feature views: ${mod}`);
    }
  }
}
ok("feature view import contract");

// Feature view call allowlist — compose blueprints, not primitive soup
const forbiddenCalls = manifest.forbiddenCallsInFeatureViews ?? [];
for (const call of forbiddenCalls) {
  for (const file of featureFiles) {
    if ((await readText(file)).includes(call)) {
      console.error(`${rel(file)}: ${call}`);
      fail(`forbidden call in feature views: ${call}`);
    }
  }
}
ok("feature view blueprint contract");

// App.Ui forbidden patterns
const uiLayoutFiles = [
  ...globSync("src/App/Ui/**/*.purs"),
  ...globSync("src/App/Layout/**/*.purs"),
];
for (const pattern of manifest.forbiddenInAppUi) {
  for (const file of uiLayoutFiles) {
    if ((await readText(file)).includes(pattern)) {
      fail(`forbidden pattern in App.Ui/Layout: ${pattern}`);
    }
  }
}
ok("App.Ui intent policy");

// Text tone seam (ADR-008)
const textTonePattern = manifest.textTone.pattern;
const textToneAllow = new Set(manifest.textTone.allowlist);
for (const file of srcSourceFiles()) {
  const r = rel(file);
  if (textToneAllow.has(r)) {
    continue;
  }
  const content = await readText(file);
  if (content.includes(textTonePattern)) {
    console.error(`${r}: ${textTonePattern}`);
    fail("raw text-base-content opacity outside App.Ui.TextTone");
  }
}
ok("text tone policy");

// Theme string drift
const appFiles = globSync("src/App/**/*.purs");
for (const literal of manifest.theme.forbiddenDataThemeLiterals) {
  for (const file of appFiles) {
    if ((await readText(file)).includes(literal)) {
      fail(`forbidden theme literal in src/App: ${literal}`);
    }
  }
}

const themeModulePath = join(ROOT, manifest.theme.themeModule);
const themeSource = await readText(themeModulePath);
if (!themeSource.includes("setAttribute('data-theme'")) {
  fail(`${manifest.theme.themeModule} missing data-theme application`);
}
if (themeSource.includes("classList.toggle('dark'")) {
  fail(`${manifest.theme.themeModule} still uses html.dark`);
}
ok("theme module data-theme");

console.log("Policy gate OK");
