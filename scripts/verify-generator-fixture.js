#!/usr/bin/env bun
/**
 * Exercise auto-scaffold.js in isolated temp copies — idempotence + strict build.
 */
import { join } from "node:path";
import {
  ROOT,
  cpRecursive,
  listDir,
  mkdtemp,
  readText,
  rmRecursive,
  run,
} from "./lib/repo.js";

function assertIncludes(haystack, needle, label) {
  if (!haystack.includes(needle)) {
    console.error(`Missing ${label}: ${needle}`);
    process.exit(1);
  }
}

async function runFixture(cwd, name, type, slug) {
  const lower = name.toLowerCase();
  run(
    [
      "bun",
      "scripts/auto-scaffold.js",
      `--name=${name}`,
      `--type=${type}`,
      `--slug-en=${slug}`,
      `--slug-fr=${slug}`,
      "--wire",
    ],
    { cwd },
  );

  const route = await readText(join(cwd, "src/Data/Route.purs"));
  const main = await readText(join(cwd, "src/App/Main.purs"));
  const i18n = await readText(join(cwd, "src/Data/I18n.purs"));
  const head = await readText(join(cwd, "src/App/Layout/Head.purs"));

  for (const marker of [
    `| ${name}`,
    `${name} -> "${name}"`,
    `"${name}": "${slug}"`,
    `prefetchFor ${name} =`,
  ]) {
    assertIncludes(route, marker, `Route insertion (${name})`);
  }

  const codecCount = route.split(`"${name}": "${slug}"`).length - 1;
  if (codecCount < 2) {
    console.error(`Missing one Route codec insertion: ${name}`);
    process.exit(1);
  }

  assertIncludes(route, `${name} -> d.nav.${lower}`, `Route title (${name})`);
  assertIncludes(main, `${name} ->`, `Main insertion (${name})`);
  assertIncludes(main, `${name}.`, `Main renderer (${name})`);
  assertIncludes(main, `${name} -> cached`, `Main handler (${name})`);
  assertIncludes(i18n, `${lower} :: String`, `I18n type (${name})`);
  assertIncludes(i18n, `${lower}: "${name}"`, `I18n English (${name})`);

  const i18nCount = i18n.split(`${lower}: "${name}"`).length - 1;
  if (i18nCount < 2) {
    console.error(`Missing I18n French insertion: ${name}`);
    process.exit(1);
  }

  assertIncludes(i18n, `  , ${lower}:`, `I18n dictionary (${name})`);
  assertIncludes(head, `${name} -> d.${lower}.body`, `Head insertion (${name})`);
}

async function runCopy(copy) {
  await runFixture(copy, "FixtureStatic", "static", "fixture-static");
  await runFixture(copy, "FixtureData", "data", "fixture-data");
  run(["bun", "x", "spago", "build", "--pure", "--strict"], { cwd: copy });
}

const tmpParent = await mkdtemp("pohjola-generator.");
const tmpSecondParent = await mkdtemp("pohjola-generator.");
const tmp = join(tmpParent, "copy");
const tmpSecond = join(tmpSecondParent, "copy");

try {
  await cpRecursive(ROOT, tmp);
  await cpRecursive(ROOT, tmpSecond);

  await runCopy(tmp);
  await runCopy(tmpSecond);

  for (const wired of [
    "src/Data/Route.purs",
    "src/App/Main.purs",
    "src/Data/I18n.purs",
    "src/App/Layout/Head.purs",
  ]) {
    const a = await readText(join(tmp, wired));
    const b = await readText(join(tmpSecond, wired));
    if (a !== b) {
      console.error(`Generator is not idempotent: ${wired}`);
      process.exit(1);
    }
  }

  for (const feature of ["FixtureStatic", "FixtureData"]) {
    const featurePath = join("src/App/Features", feature);
    const aDir = join(tmp, featurePath);
    const bDir = join(tmpSecond, featurePath);
    const aFiles = listDir(aDir);
    const bFiles = listDir(bDir);
    if (aFiles.join() !== bFiles.join()) {
      console.error(`Generator is not idempotent: ${featurePath} (file list)`);
      process.exit(1);
    }
    for (const entry of aFiles) {
      const a = await readText(join(aDir, entry));
      const b = await readText(join(bDir, entry));
      if (a !== b) {
        console.error(`Generator is not idempotent: ${featurePath}/${entry}`);
        process.exit(1);
      }
    }
  }

  console.log(
    "Generator policy OK (static/data clean-copy fixtures, strict build, idempotence)",
  );
} finally {
  await rmRecursive(tmpParent);
  await rmRecursive(tmpSecondParent);
}
