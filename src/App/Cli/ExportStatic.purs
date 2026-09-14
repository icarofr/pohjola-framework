-- | Static export CLI (`make export-static`) — prerenders every static
-- | route, in every language, to a plain HTML file for hosting with no
-- | server at all (GitHub Pages, any plain file host).
-- |
-- | This is not a JS-less export: Datastar and the shell-router script stay
-- | in the markup unchanged. A click still fires `@get`, and a static host
-- | can't answer that any differently than a direct navigation to the same
-- | path — it serves the identical prerendered file either way. That is
-- | fine: Datastar's client already handles a plain `text/html` response to
-- | an action by treating the whole document as an "outer" elements patch
-- | and morphing `<html>`/`<head>`/`<body>` against it wholesale (verified
-- | against the vendored `datastar.js` — the `text/html` branch of its
-- | fetch handler feeds the entire body through the same path a
-- | `datastar-patch-elements` fragment takes, and outer-mode patching
-- | matches top-level `<html>`/`<head>`/`<body>` tags to their real DOM
-- | node). So the click-morphs-instead-of-reloading feel keeps working
-- | without any live server cooperation.
-- |
-- | Known, accepted gap: the CSP nonce is generated once per export run
-- | and baked identically into every file, not freshly per request the way
-- | the live server's is. A shared nonce across a whole static site is a
-- | real reduction from the live server's per-request guarantee, but is
-- | the only nonce a build-time export can produce at all — there is no
-- | request to generate one against. `App.Html`'s escaping remains the
-- | primary XSS defense either way (see ADR-000); this CSP is
-- | defense-in-depth on top of it, same as the live server.
-- |
-- | Load-bearing constraint: every internal link (`Data.Route.routeUrl`) is
-- | root-relative (`/en/about`), because the live server is always mounted
-- | at a domain root. A GitHub Pages *project* site with no custom domain
-- | is served from `https://user.github.io/repo-name/` instead -- every
-- | link would be missing the `/repo-name` prefix and 404. This export does
-- | not rewrite the whole routing system to carry an arbitrary path prefix
-- | (a much larger, riskier change than this command). Use a custom domain
-- | (`--domain=`, below, writes the `CNAME` file GitHub Pages expects) or a
-- | `<user>.github.io` root repo -- both serve from the domain root, which
-- | is the one assumption this whole codebase already makes.
module App.Cli.ExportStatic (main) where

import Prelude

import App.Bun (randomBase64, writeTextFile, getArgs)
import App.Config (Config)
import App.Layout.Page (renderDocument)
import App.Main (pageRenderer)
import App.Server (cspWithNonce)
import App.Sitemap (renderRobots, renderSitemap)
import Data.Array (uncons)
import Data.Either (Either(..))
import Data.Email (defaultEmailAddress)
import Data.Foldable (for_)
import Data.I18n (Lang, defaultLang)
import Data.Maybe (Maybe(..))
import Data.Route (Route(..), allLangs, routeUrl, staticRoutes)
import Data.String (Pattern(..), Replacement(..), contains, drop, replace)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Effect.Console as Console

type CliArgs = { baseUrl :: String, outDir :: String, domain :: Maybe String }

defaultBaseUrl :: String
defaultBaseUrl = "https://example.github.io"

defaultOutDir :: String
defaultOutDir = "dist-static"

parseCliArgs :: Array String -> CliArgs
parseCliArgs rawArgs =
  parseNext rawArgs { baseUrl: defaultBaseUrl, outDir: defaultOutDir, domain: Nothing }
  where
  parseNext :: Array String -> CliArgs -> CliArgs
  parseNext args acc = case uncons args of
    Nothing -> acc
    Just { head, tail } ->
      if contains (Pattern "--base-url=") head then
        parseNext tail (acc { baseUrl = drop 11 head })
      else if contains (Pattern "--out=") head then
        parseNext tail (acc { outDir = drop 6 head })
      else if contains (Pattern "--domain=") head then
        parseNext tail (acc { domain = Just (drop 9 head) })
      else
        parseNext tail acc

-- | `pageRenderer`'s `Config` param is unused by every static route today
-- | (see App.Main's own comment on that parameter) -- this exists only to
-- | satisfy the type, not because the static export needs real config.
stubConfig :: Config
stubConfig =
  { port: 0
  , staticRoot: "dist"
  , baseUrl: "https://example.com"
  , resendApiKey: Nothing
  , emailFrom: defaultEmailAddress "noreply@example.com"
  , emailTo: defaultEmailAddress "contact@example.com"
  , postsApiBase: ""
  , rateLimitMax: 0
  , rateLimitWindowMs: 60000.0
  , databaseUrl: Nothing
  , secureCookies: true
  }

-- | Insert a CSP <meta> tag right after <head> -- a static file has no
-- | server to send the header from, so it goes in the markup instead.
-- | Reuses `cspWithNonce` so the policy string has one source of truth
-- | with the live server.
injectCsp :: String -> String -> String
injectCsp nonce html =
  replace (Pattern "<head>") (Replacement ("<head><meta http-equiv=\"Content-Security-Policy\" content=\"" <> cspWithNonce nonce <> "\">")) html

-- | Directory-style output path so both `/en/about` and `/en/about/`
-- | resolve (the common static-host convention: a request for a directory
-- | serves its `index.html`).
routeFilePath :: String -> Lang -> Route -> String
routeFilePath outDir lang route = outDir <> routeUrl lang route <> "/index.html"

exportPage :: String -> String -> String -> Lang -> Route -> Aff Unit
exportPage baseUrl outDir nonce lang route = do
  result <- pageRenderer stubConfig route lang Nothing
  case result of
    Left err ->
      liftEffect $ Console.error ("✘ " <> routeUrl lang route <> ": " <> show err)
    Right html -> do
      let
        document = injectCsp nonce (renderDocument baseUrl nonce lang route html)
        path = routeFilePath outDir lang route
      writeRes <- writeTextFile path document
      case writeRes of
        Left err -> liftEffect $ Console.error ("✘ " <> path <> ": " <> err)
        Right _ -> liftEffect $ Console.log ("✓ " <> path)

-- | Client-side redirect to the default language's home page -- `Route`
-- | has no notion of a bare "/", so there is no rendered page to serve
-- | there directly; this is the static-export equivalent of the live
-- | server's Accept-Language-based `redirectRoot`, minus the content
-- | negotiation a static file can't do.
rootRedirectHtml :: String -> String
rootRedirectHtml baseUrl =
  "<!DOCTYPE html><html><head><meta charset=\"UTF-8\" /><meta http-equiv=\"refresh\" content=\"0; url="
    <> target
    <> "\" /><link rel=\"canonical\" href=\""
    <> baseUrl
    <> target
    <> "\" /></head><body><p>Redirecting to <a href=\""
    <> target
    <> "\">"
    <> target
    <> "</a>&hellip;</p></body></html>"
  where
  target = routeUrl defaultLang Home

writeOrLog :: String -> String -> Aff Unit
writeOrLog path content = do
  writeRes <- writeTextFile path content
  case writeRes of
    Left err -> liftEffect $ Console.error ("✘ " <> path <> ": " <> err)
    Right _ -> liftEffect $ Console.log ("✓ " <> path)

runExportStatic :: Aff Unit
runExportStatic = do
  argsList <- liftEffect getArgs
  let cli = parseCliArgs argsList
  nonce <- liftEffect $ randomBase64 18
  for_ allLangs \lang ->
    for_ staticRoutes \route ->
      exportPage cli.baseUrl cli.outDir nonce lang route
  writeOrLog (cli.outDir <> "/index.html") (rootRedirectHtml cli.baseUrl)
  writeOrLog (cli.outDir <> "/robots.txt") (renderRobots cli.baseUrl)
  writeOrLog (cli.outDir <> "/sitemap.xml") (renderSitemap cli.baseUrl)
  writeOrLog (cli.outDir <> "/.nojekyll") ""
  case cli.domain of
    Just domain -> writeOrLog (cli.outDir <> "/CNAME") domain
    Nothing -> pure unit
  liftEffect $ Console.log ("Static export complete: " <> cli.outDir <> " (base URL " <> cli.baseUrl <> ")")

main :: Effect Unit
main = launchAff_ runExportStatic
