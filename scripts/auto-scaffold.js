#!/usr/bin/env bun
/**
 * Auto-wiring Feature Scaffolder (inspired by IHP code generators).
 *
 * Scaffolds feature directory structure and optionally auto-wires the feature into
 * Data.Route, App.Main, and Data.I18n with zero manual edits.
 *
 * Usage:
 *   bun scripts/auto-scaffold.js --name=Team [--type=static|data] [--slug-fr=equipe] [--wire]
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { execSync } from "node:child_process";

const args = process.argv.slice(2);
let name = "";
let type = "static";
let slugEn = "";
let slugFr = "";
let wire = false;

for (const arg of args) {
  if (arg.startsWith("--name=")) name = arg.slice(7);
  else if (arg.startsWith("--type=")) type = arg.slice(7);
  else if (arg.startsWith("--slug-en=")) slugEn = arg.slice(10);
  else if (arg.startsWith("--slug-fr=")) slugFr = arg.slice(10);
  else if (arg === "--wire" || arg === "-w") wire = true;
}

if (!name) {
  console.error("Error: --name is required (PascalCase, e.g. Team)");
  process.exit(1);
}

if (type !== "static" && type !== "data") {
  console.error(`Error: --type must be 'static' or 'data' (got: ${type})`);
  process.exit(1);
}

const lower = name.toLowerCase();
if (!slugEn) slugEn = lower;
if (!slugFr) slugFr = slugEn;

const featureDir = `src/App/Features/${name}`;
if (existsSync(featureDir)) {
  console.error(`Error: Feature directory already exists: ${featureDir}`);
  process.exit(1);
}

mkdirSync(featureDir, { recursive: true });

// --- 1. Generate Feature Files ----------------------------------------------

if (type === "static") {
  writeFileSync(
    `${featureDir}/Page.purs`,
    `-- | ${name} page — entry point
module App.Features.${name}.Page where

import App.Error (AppError)
import App.Features.${name}.View (render${name})
import App.Html (Html)
import App.Layout.Page (staticPage)
import Data.Either (Either)
import Data.I18n (Lang)
import Effect.Aff (Aff)

render :: Lang -> Aff (Either AppError Html)
render lang = staticPage (render${name} lang)
`
  );

  writeFileSync(
    `${featureDir}/View.purs`,
    `-- | ${name} page — page-level rendering, orchestrates Components/
module App.Features.${name}.View where

import App.Html (Html)
import App.Ui.Container (container)
import App.Ui.Layout.SectionHeader (Align(..), sectionHeader)
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe(..))

render${name} :: Lang -> Html
render${name} lang =
  let
    d = (dict lang).${lower}
  in
    container "max-w-3xl" "py-16"
      [ sectionHeader { eyebrow: Nothing, title: d.heading, subtitle: Just d.body, align: Left } ]
`
  );
} else {
  // Data-backed feature
  writeFileSync(
    `${featureDir}/Types.purs`,
    `-- | ${name} domain type + JSON decoding.
module App.Features.${name}.Types where

import Prelude

import Data.Argonaut.Decode (class DecodeJson, decodeJson, (.:))
import Data.Newtype (class Newtype)

newtype ${name} = ${name}
  { id :: Int
  , title :: String
  , body :: String
  }

derive instance newtype${name} :: Newtype ${name} _
derive newtype instance eq${name} :: Eq ${name}
derive newtype instance show${name} :: Show ${name}

instance decodeJson${name} :: DecodeJson ${name} where
  decodeJson json = do
    obj <- decodeJson json
    id <- obj .: "id"
    title <- obj .: "title"
    body <- obj .: "body"
    pure (${name} { id, title, body })

`
  );

  writeFileSync(
    `${featureDir}/Service.purs`,
    `-- | ${name} data fetching via HTTP.
module App.Features.${name}.Service where

import Prelude

import App.Config (Config)
import App.Data.Fetch (fetchJson)
import App.Error (AppError)
import App.Features.${name}.Types (${name})
import Data.Either (Either)
import Effect.Aff (Aff)

fetch${name}s :: Config -> Aff (Either AppError (Array ${name}))
fetch${name}s cfg = fetchJson (cfg.postsApiBase <> "/posts")
`
  );

  mkdirSync(`${featureDir}/Components`, { recursive: true });
  writeFileSync(
    `${featureDir}/Components/${name}Card.purs`,
    `-- | ${name} card — presentational component.
module App.Features.${name}.Components.${name}Card where

import App.Features.${name}.Types (${name}(..))
import App.Html (Html, el, text)
import App.Ui.Card (card, cardBody, cardTitle)
import Data.I18n (Lang)

render${name}Card :: Lang -> ${name} -> Html
render${name}Card _ (${name} item) =
  card (cardBody (el "div" []
    [ cardTitle (el "p" [] [ text item.title ])
    , el "p" [] [ text item.body ]
    ]))
`
  );

  writeFileSync(
    `${featureDir}/View.purs`,
    `-- | ${name} view — list rendering, orchestrates Components/
module App.Features.${name}.View where

import App.Features.${name}.Components.${name}Card (render${name}Card)
import App.Features.${name}.Types (${name})
import App.Html (Html)
import App.Ui.Container (container)
import App.Ui.Layout.SectionHeader (Align(..), sectionHeader)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe(..))

render${name}List :: Lang -> Array ${name} -> Html
render${name}List lang items =
  let
    d = (dict lang).${lower}
  in
    container "max-w-3xl" "py-16"
      [ sectionHeader { eyebrow: Nothing, title: d.heading, subtitle: Nothing, align: Left }
      , foldMap (render${name}Card lang) items
      ]

render${name}Error :: Lang -> Html
render${name}Error lang =
  let
    d = (dict lang).${lower}
  in
    container "max-w-3xl" "py-16"
       [ sectionHeader { eyebrow: Nothing, title: d.heading, subtitle: Just (dict lang).common.error500, align: Left } ]
`
  );

  writeFileSync(
    `${featureDir}/Page.purs`,
    `-- | ${name} page — fetches data and renders via View.
module App.Features.${name}.Page where

import Prelude

import App.Config (Config)
import App.Error (AppError)
import App.Features.${name}.Service (fetch${name}s)
import App.Features.${name}.View (render${name}Error, render${name}List)
import App.Html (Html)
import Data.Either (Either(..))
import Data.I18n (Lang)
import Effect.Aff (Aff)

renderList :: Config -> Lang -> Aff (Either AppError Html)
renderList cfg lang = do
  result <- fetch${name}s cfg
  pure case result of
    Right items -> Right (render${name}List lang items)
    Left _ -> Right (render${name}Error lang)
`
  );
}

console.log(`✓ Created feature ${featureDir} (${type})`);

// --- 2. Auto-wiring ---------------------------------------------------------

if (wire) {
  console.log(`⚡ Auto-wiring ${name} across Data.Route, App.Main, and Data.I18n...`);

  // A. Update src/Data/Route.purs
  let routeContent = readFileSync("src/Data/Route.purs", "utf-8");

  const requireMarker = (content, marker, file, description) => {
    if (!content.includes(marker)) {
      throw new Error(`Auto-wiring failed: ${description} was not inserted in ${file}.`);
    }
  };

  // Sum type
  routeContent = routeContent.replace(
    /data Route\s*\n([\s\S]*?)(derive instance genericRoute)/,
    (match, p1, p2) => {
      if (p1.includes(`| ${name}`)) return match;
      return `data Route\n${p1}  | ${name}\n\n${p2}`;
    }
  );

  // Show instance
  routeContent = routeContent.replace(
    /instance showRoute :: Show Route where\s*\n\s*show = case _ of\s*\n([\s\S]*?)(-- ==)/,
    (match, p1, p2) => {
      if (p1.includes(`${name} ->`)) return match;
      return `instance showRoute :: Show Route where\n  show = case _ of\n${p1}    ${name} -> "${name}"\n\n${p2}`;
    }
  );

  // routeCodec En
  routeContent = routeContent.replace(
    /routeCodec En = root \$ prefix "en" \$ G\.sum\s*\n\s*\{([\s\S]*?)\}/,
    (match, p1) => {
      if (p1.includes(`"${name}":`)) return match;
      return `routeCodec En = root $ prefix "en" $ G.sum\n  {${p1}  , "${name}": "${slugEn}" / G.noArgs\n  }`;
    }
  );

  // routeCodec Fr
  routeContent = routeContent.replace(
    /routeCodec Fr = root \$ prefix "fr" \$ G\.sum\s*\n\s*\{([\s\S]*?)\}/,
    (match, p1) => {
      if (p1.includes(`"${name}":`)) return match;
      return `routeCodec Fr = root $ prefix "fr" $ G.sum\n  {${p1}  , "${name}": "${slugFr}" / G.noArgs\n  }`;
    }
  );

  // prefetchFor
  routeContent = routeContent.replace(
    /prefetchFor :: Route -> Array Route\s*\n([\s\S]*?)(-- ==)/,
    (match, p1, p2) => {
      if (p1.includes(`prefetchFor ${name} =`)) return match;
      return `prefetchFor :: Route -> Array Route\n${p1}prefetchFor ${name} = [ Home ]\n\n${p2}`;
    }
  );

  // allRoutes
  routeContent = routeContent.replace(
    /allRoutes = \[([\s\S]*?)\]/,
    (match, p1) => {
      if (p1.includes(name)) return match;
      return `allRoutes = [${p1.trim()}, ${name} ]`;
    }
  );

  // staticRoutes (if static)
  if (type === "static") {
    routeContent = routeContent.replace(
      /staticRoutes = \[([\s\S]*?)\]/,
      (match, p1) => {
        if (p1.includes(name)) return match;
        return `staticRoutes = [${p1.trim()}, ${name} ]`;
      }
    );
  }

  // routeTitle
  routeContent = routeContent.replace(
    /routeTitle lang route =[\s\S]*?case route of\s*\n([\s\S]*?)$/,
    (match, p1) => {
      if (p1.includes(`${name} ->`)) return match;
      return `${match.trimEnd()}\n      ${name} -> d.nav.${lower} <> " — " <> siteTitle\n`;
    }
  );

  writeFileSync("src/Data/Route.purs", routeContent, "utf-8");
  for (const marker of [
    `| ${name}`,
    `${name} -> "${name}"`,
    `"${name}": "${slugEn}"`,
    `"${name}": "${slugFr}"`,
    `prefetchFor ${name} =`,
    `allRoutes = [`,
    `routeTitle lang route =`,
    `${name} -> d.nav.${lower}`,
  ]) requireMarker(routeContent, marker, "src/Data/Route.purs", `Route marker ${marker}`);
  const allRoutesLine = routeContent.match(/allRoutes = \[[^\n]*\n?/);
  if (!allRoutesLine || !allRoutesLine[0].includes(name)) throw new Error(`Auto-wiring failed: allRoutes was not updated in src/Data/Route.purs.`);
  if (type === "static") {
    const staticRoutesLine = routeContent.match(/staticRoutes = \[[^\n]*\n?/);
    if (!staticRoutesLine || !staticRoutesLine[0].includes(name)) throw new Error(`Auto-wiring failed: staticRoutes was not updated in src/Data/Route.purs.`);
  }
  console.log("  ✓ Updated src/Data/Route.purs");

  // B. Update src/App/Main.purs
  let mainContent = readFileSync("src/App/Main.purs", "utf-8");

  const importLine =
    type === "data"
      ? `import App.Features.${name}.Page (renderList) as ${name}`
      : `import App.Features.${name}.Page (render) as ${name}`;

  if (!mainContent.includes(importLine)) {
    mainContent = mainContent.replace(
      /(import App\.Features\.[\s\S]*?Page.*?\n)/,
      `$1${importLine}\n`
    );
  }

  const renderCase =
    type === "data"
      ? `  ${name} -> ${name}.renderList cfg lang`
      : `  ${name} -> ${name}.render lang`;

  if (!mainContent.includes(renderCase)) {
    mainContent = mainContent.replace(
      /(pageRenderer :: Config -> Route -> Lang -> Aff \(Either AppError Html\)\s*\npageRenderer cfg route lang = case route of\s*\n[\s\S]*?PostDetail.*?\n)/,
      (match) => {
        return `${match}${renderCase}\n`;
      }
    );
  }

  const handleRouteCase =
    type === "data"
      ? `    ${name} -> cachedDynamicPage ctx`
      : `    ${name} -> cachedStaticPage ctx`;

  if (!mainContent.includes(handleRouteCase)) {
    mainContent = mainContent.replace(
      /(handleRoute :: RequestCtx -> Aff Server\.Response[\s\S]*?else case ctx\.route of\s*\n[\s\S]*?PostDetail.*?\n)/,
      (match) => {
        return `${match}${handleRouteCase}\n`;
      }
    );
  }

  writeFileSync("src/App/Main.purs", mainContent, "utf-8");
  requireMarker(mainContent, importLine, "src/App/Main.purs", "feature import");
  requireMarker(mainContent, renderCase, "src/App/Main.purs", "pageRenderer case");
  requireMarker(mainContent, handleRouteCase, "src/App/Main.purs", "handleRoute case");
  console.log("  ✓ Updated src/App/Main.purs");

  // C. Update src/Data/I18n.purs
  let i18nContent = readFileSync("src/Data/I18n.purs", "utf-8");

  // 1. Dictionary nav
  i18nContent = i18nContent.replace(
    /(type Dictionary\s*=\s*\{\s*nav\s*::\s*\{[\s\S]*?)(\n\s*\})/,
    (match, p1, p2) => {
      if (p1.includes(`      , ${lower} :: String`)) return match;
      return `${p1}\n      , ${lower} :: String${p2}`;
    }
  );

  // 2. Dictionary section
  i18nContent = i18nContent.replace(
    /(type Dictionary\s*=\s*\{[\s\S]*?)(\n\s*,\s*common\s*::)/,
    (match, p1, p2) => {
      if (p1.includes(`  , ${lower} ::\n      { heading :: String`)) return match;
      return `${p1}\n  , ${lower} ::\n      { heading :: String\n      , body :: String\n      }${p2}`;
    }
  );

  // 3. en nav
  i18nContent = i18nContent.replace(
    /(en\s*::\s*Dictionary\s*\nen\s*=\s*\{\s*nav:\s*\{[\s\S]*?)(\n\s*\})/,
    (match, p1, p2) => {
      if (p1.includes(`      , ${lower}:`)) return match;
      return `${p1}\n      , ${lower}: "${name}"${p2}`;
    }
  );

  // 4. en section
  i18nContent = i18nContent.replace(
    /(en\s*::\s*Dictionary\s*\nen\s*=\s*\{[\s\S]*?)(\n\s*,\s*common:)/,
    (match, p1, p2) => {
      if (p1.includes(`  , ${lower}:\n      { heading:`)) return match;
      return `${p1}\n  , ${lower}:\n      { heading: "${name}"\n      , body: "Explore our ${name}."\n      }${p2}`;
    }
  );

  // 5. fr nav
  i18nContent = i18nContent.replace(
    /(fr\s*::\s*Dictionary\s*\nfr\s*=\s*\{\s*nav:\s*\{[\s\S]*?)(\n\s*\})/,
    (match, p1, p2) => {
      if (p1.includes(`      , ${lower}:`)) return match;
      return `${p1}\n      , ${lower}: "${name}"${p2}`;
    }
  );

  // 6. fr section
  i18nContent = i18nContent.replace(
    /(fr\s*::\s*Dictionary\s*\nfr\s*=\s*\{[\s\S]*?)(\n\s*,\s*common:)/,
    (match, p1, p2) => {
      if (p1.includes(`  , ${lower}:\n      { heading:`)) return match;
      return `${p1}\n  , ${lower}:\n      { heading: "${name}"\n      , body: "Description de ${name}."\n      }${p2}`;
    }
  );

  writeFileSync("src/Data/I18n.purs", i18nContent, "utf-8");
  for (const marker of [
    `      , ${lower} :: String`,
    `  , ${lower} ::\n      { heading :: String`,
    `      , ${lower}: "${name}"`,
    `  , ${lower}:\n      { heading: "${name}"`,
  ]) requireMarker(i18nContent, marker, "src/Data/I18n.purs", `I18n field ${marker}`);
  // The same field names occur in both language dictionaries; verify each one
  // in its own section rather than accepting an English-only replacement.
  for (const lang of ["en", "fr"]) {
    const section = i18nContent.match(new RegExp(`${lang}\\s*::\\s*Dictionary\\s*\\n${lang}\\s*=([\\s\\S]*?)(?=\\n\\n(?:en|fr)\\s*::|$)`));
    if (!section || !section[1].includes(`  , ${lower}:`) || !section[1].includes(`      , ${lower}:`)) {
      throw new Error(`Auto-wiring failed: ${lang} I18n fields were not inserted in src/Data/I18n.purs.`);
    }
  }
  console.log("  ✓ Updated src/Data/I18n.purs");

  // D. Update src/App/Layout/Head.purs (seoDescription)
  let headContent = readFileSync("src/App/Layout/Head.purs", "utf-8");

  // seoDescription has one language-polymorphic case expression. Insert the
  // route once and use the generated dictionary section for both languages.
  const headMarker = `      ${name} -> d.${lower}.body`;
  if (!headContent.includes(headMarker)) {
    const before = headContent;
    headContent = headContent.replace(
      /(seoDescription :: Lang -> Route -> String[\s\S]*?case route of\s*\n[\s\S]*?\n)(\s+PostDetail _ -> [^\n]*\n)/,
      `$1$2      ${name} -> d.${lower}.body\n`
    );
    if (headContent === before) {
      throw new Error("Auto-wiring failed: could not find the seoDescription route case insertion point in src/App/Layout/Head.purs.");
    }
  }

  writeFileSync("src/App/Layout/Head.purs", headContent, "utf-8");
  requireMarker(headContent, headMarker, "src/App/Layout/Head.purs", "seoDescription route case");
  console.log("  ✓ Updated src/App/Layout/Head.purs");

  // Format code
  try {
    execSync("bun x purs-tidy format-in-place 'src/**/*.purs' 'test/**/*.purs'", {
      stdio: "inherit",
    });
    console.log("  ✓ Formatted with purs-tidy");
  } catch (error) {
    console.error("✘ Formatting failed; refusing to complete auto-wiring.");
    throw error;
  }

  console.log("\n⚡ Auto-wiring complete! Validating with Spago build...");
  try {
    execSync("bun x spago build --strict", { stdio: "inherit" });
    console.log("✓ Built successfully with zero compiler errors!");
  } catch (error) {
    console.error("✘ Build check failed. Inspect generated changes.");
    throw error;
  }
}
