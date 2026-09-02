#!/usr/bin/env bun
/**
 * Auto-wiring Feature Scaffolder (inspired by IHP code generators).
 *
 * Scaffolds feature directory structure and optionally auto-wires the feature into
 * Data.Route, App.Main, and Data.I18n with zero manual edits.
 *
 * Usage:
 *   bun scripts/auto-scaffold.js --name=Team [--type=static|data] [--slug-fr=equipe] [--slug-pt=equipe] [--wire]
 */

import { exists, readText, run, writeText } from "./lib/repo.js";

const args = process.argv.slice(2);
let name = "";
let type = "static";
let slugEn = "";
let slugFr = "";
let slugPt = "";
let wire = false;
let chrome = false;

for (const arg of args) {
  if (arg.startsWith("--name=")) name = arg.slice(7);
  else if (arg.startsWith("--type=")) type = arg.slice(7);
  else if (arg.startsWith("--slug-en=")) slugEn = arg.slice(10);
  else if (arg.startsWith("--slug-fr=")) slugFr = arg.slice(10);
  else if (arg.startsWith("--slug-pt=")) slugPt = arg.slice(10);
  else if (arg === "--wire" || arg === "-w") wire = true;
  else if (arg === "--chrome" || arg === "-c") chrome = true;
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
if (!slugPt) slugPt = slugEn;

async function main() {
const featureDir = `src/App/Features/${name}`;
if (await exists(featureDir)) {
  console.error(`Error: Feature directory already exists: ${featureDir}`);
  process.exit(1);
}

// --- 1. Generate Feature Files ----------------------------------------------

if (type === "static") {
  await writeText(
    `${featureDir}/Page.purs`,
    `-- | ${name} page — entry point
module App.Features.${name}.Page where

import App.Error (AppError)
import App.Features.${name}.View (render${name})
import App.Form (FormStatus)
import App.Html (Html)
import App.Layout.Page (staticPage)
import Data.Either (Either)
import Data.I18n (Lang)
import Data.Maybe (Maybe)
import Effect.Aff (Aff)

render :: Lang -> Maybe FormStatus -> Aff (Either AppError Html)
render lang status = staticPage (render${name} lang status)
`
  );

  await writeText(
    `${featureDir}/View.purs`,
    `-- | ${name} page view — fills Editorial template slots only.
module App.Features.${name}.View where

import App.Form (FormStatus)
import App.Html (Html)
import App.Ui.Templates.PageHeader as PageHeader
import App.Ui.Templates.Render (renderPage)
import App.Ui.Templates.Types
  ( EditorialSlots
  , PageTemplate(..)
  , editorialSlots
  , valuesSlotsFromArray
  )
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe(..))
import Data.Route (Route(..))

render${name} :: Lang -> Maybe FormStatus -> Html
render${name} lang status =
  renderPage lang ${name} status (Editorial (pageSlots lang))

pageSlots :: Lang -> EditorialSlots
pageSlots lang =
  let
    d = (dict lang).${lower}
    nav = (dict lang).nav
  in
    editorialSlots
      d.heading
      (Just d.body)
      { heading: d.heading
      , lead: d.body
      , body: d.body
      }
      (valuesSlotsFromArray d.heading d.body [])
      [ PageHeader.breadcrumbHome lang nav.home
      , PageHeader.breadcrumbHere d.heading
      ]
`
  );
} else {
  // Data-backed feature — Types + Service + Page + View (exemplar: Posts/)
  await writeText(
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

${lower}Id :: ${name} -> Int
${lower}Id (${name} row) = row.id

${lower}Title :: ${name} -> String
${lower}Title (${name} row) = row.title

${lower}Body :: ${name} -> String
${lower}Body (${name} row) = row.body
`
  );

  await writeText(
    `${featureDir}/Service.purs`,
    `-- | ${name} data service — fetchJson boundary.
module App.Features.${name}.Service
  ( fetch${name}
  , fetch${name}s
  ) where

import Prelude

import App.Config (Config)
import App.Data.Fetch (fetchJson)
import App.Error (AppError)
import App.Features.${name}.Types (${name})
import Data.Either (Either)
import Effect.Aff (Aff)

fetch${name}s :: Config -> Aff (Either AppError (Array ${name}))
fetch${name}s cfg = fetchJson (cfg.postsApiBase <> "/posts")

fetch${name} :: Config -> Int -> Aff (Either AppError ${name})
fetch${name} cfg id = fetchJson (cfg.postsApiBase <> "/posts/" <> show id)
`
  );

  await writeText(
    `${featureDir}/Page.purs`,
    `-- | ${name} page — entry point with async data fetching.
module App.Features.${name}.Page (renderList, renderDetail) where

import Prelude

import App.Config (Config)
import App.Error (AppError)
import App.Features.${name}.Service (fetch${name}, fetch${name}s)
import App.Features.${name}.View (render${name}Detail, render${name}Error, render${name}List)
import App.Form (FormStatus)
import App.Html (Html)
import Data.Either (Either(..))
import Data.I18n (Lang)
import Data.Maybe (Maybe)
import Effect.Aff (Aff)

renderList :: Config -> Lang -> Maybe FormStatus -> Aff (Either AppError Html)
renderList cfg lang status = do
  result <- fetch${name}s cfg
  pure case result of
    Right items -> Right (render${name}List lang status items)
    Left _ -> Right (render${name}Error lang status)

renderDetail :: Config -> Lang -> Int -> Maybe FormStatus -> Aff (Either AppError Html)
renderDetail cfg lang id status = do
  result <- fetch${name} cfg id
  pure case result of
    Right item -> Right (render${name}Detail lang status item)
    Left err -> Left err
`
  );

  await writeText(
    `${featureDir}/View.purs`,
    `-- | ${name} feature views — Feed and Article templates.
module App.Features.${name}.View where

import Prelude

import App.Features.${name}.Types (${name}, ${lower}Body, ${lower}Id, ${lower}Title)
import App.Form (FormStatus)
import App.Html (Html)
import App.Ui.Templates.PageHeader as PageHeader
import App.Ui.Templates.Render (renderPage)
import App.Ui.Templates.Types
  ( ActionTarget(..)
  , FeedCard
  , PageTemplate(..)
  , articleSlots
  , feedSlots
  )
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe)
import Data.Route (Route(..))

render${name}List :: Lang -> Maybe FormStatus -> Array ${name} -> Html
render${name}List lang status items =
  let
    d = (dict lang).${lower}
    nav = (dict lang).nav
  in
    renderPage lang ${name} status
      ( Feed
          ( feedSlots
              d.heading
              d.body
              [ PageHeader.breadcrumbHome lang nav.home
              , PageHeader.breadcrumbHere d.heading
              ]
              (map (toCard lang) items)
          )
      )

render${name}Detail :: Lang -> Maybe FormStatus -> ${name} -> Html
render${name}Detail lang status item =
  let
    d = (dict lang).${lower}
    nav = (dict lang).nav
    idNum = ${lower}Id item
    title = ${lower}Title item
  in
    renderPage lang ${name} status
      ( Article
          ( articleSlots
              (d.heading <> " #" <> show idNum)
              title
              ""
              (d.heading <> " #" <> show idNum)
              (${lower}Body item)
              [ PageHeader.breadcrumbHome lang nav.home
              , PageHeader.breadcrumbLink lang ${name} d.heading
              , PageHeader.breadcrumbHere title
              ]
          )
      )

render${name}Error :: Lang -> Maybe FormStatus -> Html
render${name}Error lang status =
  render${name}List lang status []

toCard :: Lang -> ${name} -> FeedCard
toCard lang item =
  let
    d = (dict lang).${lower}
  in
    { imageUrl: ""
    , imageAlt: ${lower}Title item
    , date: ""
    , category: d.heading
    , title: ${lower}Title item
    , excerpt: ${lower}Body item
    , authorName: ""
    , authorRole: ""
    , target: Internal { lang, route: ${name} }
    }
`
  );
}

console.log(`✓ Created feature ${featureDir} (${type})`);

const requireMarker = (content, marker, file, description) => {
  if (!content.includes(marker)) {
    throw new Error(`Auto-wiring failed: ${description} was not inserted in ${file}.`);
  }
};

// --- 2. Auto-wiring ---------------------------------------------------------

if (wire) {
  console.log(`⚡ Auto-wiring ${name} across Data.Route, App.Main, and Data.I18n...`);

  // A. Update src/Data/Route.purs
  let routeContent = await readText("src/Data/Route.purs");

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

  // routeCodec Pt
  routeContent = routeContent.replace(
    /routeCodec Pt = root \$ prefix "pt" \$ G\.sum\s*\n\s*\{([\s\S]*?)\}/,
    (match, p1) => {
      if (p1.includes(`"${name}":`)) return match;
      return `routeCodec Pt = root $ prefix "pt" $ G.sum\n  {${p1}  , "${name}": "${slugPt}" / G.noArgs\n  }`;
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

  await writeText("src/Data/Route.purs", routeContent);
  for (const marker of [
    `| ${name}`,
    `${name} -> "${name}"`,
    `"${name}": "${slugEn}"`,
    `"${name}": "${slugFr}"`,
    `"${name}": "${slugPt}"`,
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
  let mainContent = await readText("src/App/Main.purs");

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
      ? `  ${name} -> ${name}.renderList cfg lang status`
      : `  ${name} -> ${name}.render lang status`;

  if (!mainContent.includes(renderCase)) {
    const pageRendererRe =
      /(pageRenderer _?cfg route lang status = case route of\n)([\s\S]*?)(\n\n-- \| Everything)/;
    if (pageRendererRe.test(mainContent)) {
      mainContent = mainContent.replace(pageRendererRe, (match, header, cases, footer) => {
        if (cases.includes(renderCase)) return match;
        const trimmed = cases.endsWith("\n") ? cases : `${cases}\n`;
        return `${header}${trimmed}${renderCase}\n${footer}`;
      });
    } else {
      mainContent = mainContent.replace(
        /(pageRenderer :: Config -> Route -> Lang -> Maybe FormStatus -> Aff \(Either AppError Html\)\s*\npageRenderer _?cfg route lang status = case route of\s*\n[\s\S]*?PostDetail.*?\n)/,
        (match) => `${match}${renderCase}\n`
      );
    }
  }

  const handleRouteCase =
    type === "data"
      ? `    ${name} -> cachedDynamicPage ctx`
      : `    ${name} -> cachedStaticPage ctx`;

  if (!mainContent.includes(handleRouteCase)) {
    const handleRouteRe =
      /(else case ctx\.route of\n)([\s\S]*?)(\n\n-- \| True when)/;
    if (handleRouteRe.test(mainContent)) {
      mainContent = mainContent.replace(handleRouteRe, (match, header, cases, footer) => {
        if (cases.includes(handleRouteCase)) return match;
        const trimmed = cases.endsWith("\n") ? cases : `${cases}\n`;
        return `${header}${trimmed}${handleRouteCase}\n${footer}`;
      });
    } else {
      mainContent = mainContent.replace(
        /(handleRoute :: RequestCtx -> Aff Server\.Response[\s\S]*?else case ctx\.route of\s*\n[\s\S]*?PostDetail.*?\n)/,
        (match) => `${match}${handleRouteCase}\n`
      );
    }
  }

  // Second exhaustive Route case (shared fragment cache). Anchor on the
  // footer after fragmentHtml so we never double-patch handleRoute above.
  const fragmentHtmlCase =
    type === "data"
      ? `    ${name} -> cachedInnerDynamic ctx`
      : `    ${name} -> cachedInner ctx`;

  if (!mainContent.includes(fragmentHtmlCase)) {
    const fragmentHtmlRe =
      /(else case ctx\.route of\n)([\s\S]*?)(\n\n-- \| Pure page cached)/;
    if (fragmentHtmlRe.test(mainContent)) {
      mainContent = mainContent.replace(fragmentHtmlRe, (match, header, cases, footer) => {
        if (cases.includes(fragmentHtmlCase)) return match;
        const trimmed = cases.endsWith("\n") ? cases : `${cases}\n`;
        return `${header}${trimmed}${fragmentHtmlCase}\n${footer}`;
      });
    } else {
      mainContent = mainContent.replace(
        /(fragmentHtml :: RequestCtx -> Aff \(Either AppError Html\)[\s\S]*?else case ctx\.route of\s*\n[\s\S]*?PostDetail.*?\n)/,
        (match) => `${match}${fragmentHtmlCase}\n`
      );
    }
  }

  await writeText("src/App/Main.purs", mainContent);
  requireMarker(mainContent, importLine, "src/App/Main.purs", "feature import");
  requireMarker(mainContent, renderCase, "src/App/Main.purs", "pageRenderer case");
  requireMarker(mainContent, handleRouteCase, "src/App/Main.purs", "handleRoute case");
  requireMarker(mainContent, fragmentHtmlCase, "src/App/Main.purs", "fragmentHtml case");
  console.log("  ✓ Updated src/App/Main.purs");

  // C. Update src/Data/I18n.purs
  let i18nContent = await readText("src/Data/I18n.purs");

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

  // 7. pt nav
  i18nContent = i18nContent.replace(
    /(pt\s*::\s*Dictionary\s*\npt\s*=\s*\{\s*nav:\s*\{[\s\S]*?)(\n\s*\})/,
    (match, p1, p2) => {
      if (p1.includes(`      , ${lower}:`)) return match;
      return `${p1}\n      , ${lower}: "${name}"${p2}`;
    }
  );

  // 8. pt section
  i18nContent = i18nContent.replace(
    /(pt\s*::\s*Dictionary\s*\npt\s*=\s*\{[\s\S]*?)(\n\s*,\s*common:)/,
    (match, p1, p2) => {
      if (p1.includes(`  , ${lower}:\n      { heading:`)) return match;
      return `${p1}\n  , ${lower}:\n      { heading: "${name}"\n      , body: "Explore o ${name}."\n      }${p2}`;
    }
  );

  const headPreview = await readText("src/App/Layout/Head.purs");
  const headUsesSeoDescriptions =
    /d\.seo\.\w+Description/.test(headPreview) && !/PostDetail _ ->/.test(headPreview);
  if (headUsesSeoDescriptions && !i18nContent.includes(`${lower}Description :: String`)) {
    i18nContent = i18nContent.replace(
      /(,\s*seo\s*::\s*\{[\s\S]*?)(\n\s*\}\s*\n\s*, )/,
      (match, p1, p2) => {
        if (p1.includes(`${lower}Description :: String`)) return match;
        return `${p1}\n      , ${lower}Description :: String${p2}`;
      }
    );
    i18nContent = i18nContent.replace(
      /(,\s*seo:\s*\{[\s\S]*?)(\n\s*\}\s*\n\s*, )/g,
      (match, p1, p2) => {
        if (p1.includes(`${lower}Description:`)) return match;
        return `${p1}\n      , ${lower}Description: "SEO for ${name}."${p2}`;
      }
    );
  }

  await writeText("src/Data/I18n.purs", i18nContent);
  for (const marker of [
    `      , ${lower} :: String`,
    `  , ${lower} ::\n      { heading :: String`,
    `      , ${lower}: "${name}"`,
    `  , ${lower}:\n      { heading: "${name}"`,
  ]) requireMarker(i18nContent, marker, "src/Data/I18n.purs", `I18n field ${marker}`);
  // The same field names occur in each language dictionary; verify each one
  // in its own section rather than accepting an English-only replacement.
  for (const lang of ["en", "fr", "pt"]) {
    const section = i18nContent.match(new RegExp(`${lang}\\s*::\\s*Dictionary\\s*\\n${lang}\\s*=([\\s\\S]*?)(?=\\n\\n(?:en|fr|pt|dict)\\s*::|$)`));
    if (!section || !section[1].includes(`  , ${lower}:`) || !section[1].includes(`      , ${lower}:`)) {
      throw new Error(`Auto-wiring failed: ${lang} I18n fields were not inserted in src/Data/I18n.purs.`);
    }
  }
  console.log("  ✓ Updated src/Data/I18n.purs");

  // D. Update src/App/Layout/Head.purs (seoDescription)
  let headContent = await readText("src/App/Layout/Head.purs");

  // seoDescription has one language-polymorphic case expression. Insert the
  // route once and use the generated dictionary section for both languages.
  const headMarker = `      ${name} -> d.${lower}.body`;
  const headSeoMarker = `      ${name} -> d.seo.${lower}Description`;
  if (!headContent.includes(headMarker) && !headContent.includes(headSeoMarker)) {
    const before = headContent;
    if (!headUsesSeoDescriptions) {
      headContent = headContent.replace(
        /(seoDescription :: Lang -> Route -> String[\s\S]*?case route of\s*\n[\s\S]*?\n)(\s+PostDetail _ -> [^\n]*\n)/,
        `$1$2      ${name} -> d.${lower}.body\n`
      );
    }
    if (headContent === before) {
      headContent = headContent.replace(
        /(seoDescription :: Lang -> Route -> String[\s\S]*?case route of\n)([\s\S]*?)(\n\n--)/,
        (match, header, cases, footer) => {
          const seoCase = `      ${name} -> d.seo.${lower}Description\n`;
          if (cases.includes(seoCase.trim())) return match;
          const trimmed = cases.endsWith("\n") ? cases : `${cases}\n`;
          return `${header}${trimmed}${seoCase}${footer}`;
        }
      );
    }
    if (headContent === before) {
      throw new Error("Auto-wiring failed: could not find the seoDescription route case insertion point in src/App/Layout/Head.purs.");
    }
  }

  await writeText("src/App/Layout/Head.purs", headContent);
  if (headContent.includes(headMarker)) {
    requireMarker(headContent, headMarker, "src/App/Layout/Head.purs", "seoDescription route case");
  } else {
    requireMarker(headContent, headSeoMarker, "src/App/Layout/Head.purs", "seoDescription route case");
  }
  console.log("  ✓ Updated src/App/Layout/Head.purs");

  if (chrome) {
    console.log(`⚡ Auto-wiring chrome for ${name} in SiteShell...`);
    let shellContent = await readText("src/App/Ui/Templates/SiteShell.purs");
    const labelField = `${lower}Label`;

    if (!shellContent.includes(`${labelField} :: String`)) {
      shellContent = shellContent.replace(
        /(type ShellLabels\s*=\s*\{[\s\S]*?)(  , copyright :: String\n  \})/,
        `$1  , ${labelField} :: String\n$2`,
      );
      shellContent = shellContent.replace(
        /(shellLabels lang =[\s\S]*?)(    , copyright: d\.footer\.copyright\n  \})/,
        `$1    , ${labelField}: d.nav.${lower}\n$2`,
      );
    }

    const desktopLine = `                , desktopNavLink lang route ${name} labels.${labelField}`;
    if (!shellContent.includes(desktopLine)) {
      shellContent = shellContent.replace(
        /(desktopNavLink lang route Contact labels\.contactLabel\n)/,
        `$1${desktopLine}\n`,
      );
    }

    const mobileLine = `            , mobileNavLink lang route ${name} labels.${labelField}`;
    if (!shellContent.includes(mobileLine)) {
      shellContent = shellContent.replace(
        /(mobileNavLink lang route Contact labels\.contactLabel\n)/,
        `$1${mobileLine}\n`,
      );
    }

    const footerLine = `        , footerLink lang route ${name} labels.${labelField}`;
    if (!shellContent.includes(footerLine)) {
      shellContent = shellContent.replace(
        /(footerLink lang route Contact labels\.contactLabel\n)/,
        `$1${footerLine}\n`,
      );
    }

    await writeText("src/App/Ui/Templates/SiteShell.purs", shellContent);
    for (const marker of [
      `${labelField} :: String`,
      `${labelField}: d.nav.${lower}`,
      desktopLine.trim(),
      mobileLine.trim(),
      footerLine.trim(),
    ]) {
      requireMarker(shellContent, marker, "src/App/Ui/Templates/SiteShell.purs", `chrome ${marker}`);
    }
    console.log("  ✓ Updated src/App/Ui/Templates/SiteShell.purs (chrome)");
  }

  // Format code
  try {
    run(
      [
        "bun",
        "x",
        "purs-tidy",
        "format-in-place",
        "src/**/*.purs",
        "test/**/*.purs",
      ],
      { throwOnError: true },
    );
    console.log("  ✓ Formatted with purs-tidy");
  } catch (error) {
    console.error("✘ Formatting failed; refusing to complete auto-wiring.");
    throw error;
  }

  console.log("\n⚡ Auto-wiring complete! Validating with Spago build...");
  if (!chrome) {
    console.log("  → Add nav links: make new-feature NAME=... WIRE=1 CHROME=1 (or docs/conventions/chrome-checklist.md)");
  }
  try {
    run(["bun", "x", "spago", "build", "--strict"], { throwOnError: true });
    console.log("✓ Built successfully with zero compiler errors!");
  } catch (error) {
    console.error("✘ Build check failed. Inspect generated changes.");
    throw error;
  }
} else if (chrome) {
  console.error("Error: --chrome requires --wire (CHROME=1 implies WIRE=1)");
  process.exit(1);
}
}

await main();
