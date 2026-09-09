-- | Server entry point — MPA architecture
-- |
-- | Server renders all HTML via the Html ADT, Alpine.js provides interactivity.
-- | Routes for every language in `allLangs` (En, Fr, Pt): /en/*, /fr/*, /pt/*
module App.Main (main, pageRenderer, detectLang, htmlOk) where

import Prelude

import App.Alpine (alpineRequestHeader)
import App.Cache (PageCache, defaultTtlMs, insertDynamic, insertStatic, lookupDynamic, lookupStatic, mkPageCache)
import App.Config (Config, loadConfig)
import App.Env (getEnvMaybe)
import App.Error (AppError(..))
import App.Form (FormStatus, parseFormStatus)
import App.Migration (migrate, renderMigrationError)
import App.Features.Home.Page (render) as Home
import App.Html (Html)
import App.Layout.Page (renderErrorFragment, renderErrorPage, renderFragment, renderDocument)
import App.Logger as Log
import App.Server as Server
import App.Sitemap (renderRobots, renderSitemap)
import Data.Array (head)
import Data.Either (Either(..))
import Data.I18n (Lang, defaultLang, parseLang)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.Route (Route(..), isStaticRoute, parseRoute, routeUrl)
import Data.String.Common (split, toLower)
import Data.String.Pattern (Pattern(..))
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)

-- ============================================================================
-- Router
-- ============================================================================

router :: Config -> PageCache -> Server.Request -> Aff Server.Response
router cfg cache { method, path, headers, query, nonce } = case method of
  Server.POST -> pure Server.notFound
  Server.GET -> handleGet cfg cache nonce headers query path
  Server.HEAD -> handleGet cfg cache nonce headers query path
  _ -> pure Server.methodNotAllowed

-- | Shared handler for GET and HEAD (identical except body stripping in Server).
handleGet :: Config -> PageCache -> String -> Map String String -> Map String String -> Array String -> Aff Server.Response
handleGet cfg cache nonce headers query path = case path of
  [] -> redirectRoot headers
  [ "healthz" ] -> pure $ Server.okText "text/plain" "ok"
  [ "dev", "live-reload" ] -> pure $ Server.okTextWith [ Tuple "Cache-Control" "no-cache", Tuple "Connection" "keep-alive" ] "text/event-stream" "retry: 1500\n\n: live-reload connected\n\n"
  [ "robots.txt" ] -> pure $ Server.okTextPublic "text/plain; charset=utf-8" (renderRobots cfg.baseUrl)
  [ "sitemap.xml" ] -> pure $ Server.okTextPublic "application/xml; charset=utf-8" (renderSitemap cfg.baseUrl)
  _ -> case parseRoute path of
    Just { lang, route } -> handleRoute { cfg, cache, nonce, lang, route, headers, query }
    Nothing -> pure $ routeMiss404 nonce (isFragmentRequest headers query) (langFromPath path)

-- | 404 for a path that parses to no route.
-- |
-- | Must honour the fragment contract even though there is no `Route` to build
-- | from: an Alpine AJAX request to an unknown URL would otherwise be answered
-- | with a complete `<!DOCTYPE>` document, which the client swaps into
-- | `#content` — a whole document nested inside the page body.
-- |
-- | This is the same defect W1 fixed in `handleFragment`, in a path W1 never
-- | reached: `handleFragment` only runs after a route parses successfully, so
-- | the fix was narrower than the contract it restored. `renderErrorFragment`
-- | never needed a `Route` value in the first place (see `App.Layout.Page`) —
-- | that unused parameter is gone from its signature.
routeMiss404 :: String -> Boolean -> Lang -> Server.Response
routeMiss404 nonce wantsFragment lang =
  if wantsFragment then
    Server.htmlErrorResponse (renderErrorFragment lang 404) [ varyHeader ] (Server.errorStatusCode 404)
  else
    Server.htmlErrorResponse (renderErrorPage nonce lang 404) [ varyHeader ] (Server.errorStatusCode 404)

-- | Best-effort language for a route-miss 404: the path's leading segment
-- | wins when it carries a language prefix; unknown/prefixless paths fall
-- | back to the site default. Keeps the rendered error page in the user's
-- | language instead of silently re-languaging them on a typo.
langFromPath :: Array String -> Lang
langFromPath path = fromMaybe defaultLang (head path >>= parseLang)

-- | Select the correct page renderer for a route.
-- | Static pages use `staticPage` (pure Html, no error path).
-- | Data-backed pages fetch via Aff and may return `Left AppError`.
-- |
-- | `cfg` is unused while every route is static (`Home` only, so far) —
-- | named `_cfg`, not `cfg`, purely so `make new-feature TYPE=data --wire`'s
-- | regex (which matches either name) still finds this line once a
-- | data-backed route needs it again.
pageRenderer :: Config -> Route -> Lang -> Maybe FormStatus -> Aff (Either AppError Html)
pageRenderer _cfg route lang status = case route of
  Home -> Home.render lang status

-- | Everything a page render needs about the current request, bundled.
-- |
-- | Replaces the seven positional arguments `handleRoute`/`handleStatic`
-- | previously threaded. Request-scoped state now has one home, so a future
-- | cross-cutting concern (a session per ADR-002, say) becomes a field rather
-- | than an eighth positional argument at every call site.
type RequestCtx =
  { cfg :: Config
  , cache :: PageCache
  , nonce :: String
  , lang :: Lang
  , route :: Route
  , headers :: Map String String
  , query :: Map String String
  }

-- | `Vary: x-alpine-request` — the same URL answers a full page or a fragment
-- | depending on that header, so caches must key on it.
varyHeader :: Tuple String String
varyHeader = Tuple "Vary" alpineRequestHeader

statusFor :: RequestCtx -> Maybe FormStatus
statusFor ctx = Map.lookup "status" ctx.query >>= parseFormStatus

-- | HTML 200 with the same Cache-Control policy as full pages: statusful
-- | responses are never stored; others stay private, short-lived.
htmlOk :: Boolean -> Array (Tuple String String) -> String -> Server.Response
htmlOk statusful hdrs body =
  if statusful then Server.okWithNoStore hdrs body else Server.okWith hdrs body

fullPage :: RequestCtx -> Maybe FormStatus -> Html -> Server.Response
fullPage ctx status html =
  htmlOk (isJust status) [ varyHeader ] (renderDocument ctx.cfg.baseUrl ctx.nonce ctx.lang ctx.route html)

-- | Log a page-render failure. Shared by both error paths so the log shape
-- | cannot drift between them.
logRenderFailure :: RequestCtx -> AppError -> Aff Unit
logRenderFailure ctx err =
  liftEffect $ Log.logErr "page-render-failed"
    [ Tuple "path" (routeUrl ctx.lang ctx.route), Tuple "error" (show err) ]

-- | Full-document error response. This block was previously copy-pasted at
-- | three sites in this module.
failurePage :: RequestCtx -> AppError -> Aff Server.Response
failurePage ctx err = do
  logRenderFailure ctx err
  pure $ Server.htmlErrorResponse (renderErrorPage ctx.nonce ctx.lang (errorStatus err)) [ varyHeader ]
    (Server.errorStatusCode (errorStatus err))

-- | Fragment-shaped error response — a fragment request must never be answered
-- | with a full document (ADR-007).
failureFragment :: RequestCtx -> AppError -> Aff Server.Response
failureFragment ctx err = do
  logRenderFailure ctx err
  pure $ Server.htmlErrorResponse
    (renderErrorFragment ctx.lang (errorStatus err))
    [ varyHeader ]
    (Server.errorStatusCode (errorStatus err))

-- | Serve a route.
-- |
-- | Exhaustive over `Route` on purpose. The previous wildcard let a new route
-- | compile while silently inheriting static serving; naming every route forces
-- | a decision. This deliberately does NOT introduce a policy sum type — with
-- | one experimental streaming implementation and dynamically-cached routes
-- | that would be abstraction ahead of need, and exhaustiveness is the property
-- | actually wanted.
-- |
-- | Ordinary pages use buffered rendering. Streaming remains an experimental,
-- | unselected path outside this route-level renderer.
-- | Fragment requests always use the buffered fragment path.
handleRoute :: RequestCtx -> Aff Server.Response
handleRoute ctx =
  if isFragmentRequest ctx.headers ctx.query then
    handleFragment ctx
  else if hasStatusQuery ctx then
    -- A form-status banner is per-request state. A cached body would drop it,
    -- and a cached body carrying it would show one visitor's banner to the
    -- next. This guard is uniform across every route: previously only the
    -- static path checked it, so PostDetail rendered the banner on a cache miss
    -- and silently dropped it on a hit — the same URL answering differently
    -- depending on cache warmth.
    freshPage ctx
  else if isStaticRoute ctx.route then
    cachedStaticPage ctx
  else
    cachedDynamicPage ctx

-- | True when the request carries a form-status banner query.
hasStatusQuery :: RequestCtx -> Boolean
hasStatusQuery ctx = Map.member "status" ctx.query

-- | Alpine AJAX fragment. Note the error path answers with a *fragment*, not a
-- | full document: the client swaps this response into `#content`, so a
-- | `renderErrorPage` here would nest a complete `<!DOCTYPE>` document inside
-- | the page body. See ADR-007 (streaming errors) — the same principle, applied
-- | to the path that lacked it.
-- |
-- | Cacheable fragments reuse the same static/dynamic Html cache as full
-- | documents (keyed by `(Route, Lang)`). Statusful requests stay uncached so
-- | one visitor's form banner never leaks into another response.
handleFragment :: RequestCtx -> Aff Server.Response
handleFragment ctx = do
  result <- fragmentHtml ctx
  case result of
    Left err -> failureFragment ctx err
    Right html ->
      pure $ htmlOk (hasStatusQuery ctx) [ varyHeader ] $ renderFragment ctx.lang ctx.route html

-- | Html for a fragment request: statusful → fresh; otherwise the shared cache.
fragmentHtml :: RequestCtx -> Aff (Either AppError Html)
fragmentHtml ctx =
  if hasStatusQuery ctx then
    pageRenderer ctx.cfg ctx.route ctx.lang (statusFor ctx)
  else if isStaticRoute ctx.route then
    cachedInner ctx
  else
    cachedInnerDynamic ctx

-- | Pure page cached per (route, lang) for the process lifetime.
cachedStaticPage :: RequestCtx -> Aff Server.Response
cachedStaticPage ctx = do
  result <- cachedInner ctx
  case result of
    Left err -> failurePage ctx err
    Right html -> pure $ fullPage ctx Nothing html

-- | Data-backed page cached under a TTL.
cachedDynamicPage :: RequestCtx -> Aff Server.Response
cachedDynamicPage ctx = do
  result <- cachedInnerDynamic ctx
  case result of
    Left err -> failurePage ctx err
    Right html -> pure $ fullPage ctx Nothing html

-- | Lookup or render+insert for static pages. Shared by full and fragment paths.
-- | Never caches `Left` errors.
cachedInner :: RequestCtx -> Aff (Either AppError Html)
cachedInner ctx = do
  mCached <- liftEffect $ lookupStatic ctx.cache.static ctx.route ctx.lang
  case mCached of
    Just html -> pure (Right html)
    Nothing -> do
      result <- pageRenderer ctx.cfg ctx.route ctx.lang Nothing
      case result of
        Left err -> pure (Left err)
        Right html -> do
          liftEffect $ insertStatic ctx.cache.static ctx.route ctx.lang html
          pure (Right html)

-- | Lookup or render+insert for dynamic pages. Shared by full and fragment paths.
-- | Never caches `Left` errors.
cachedInnerDynamic :: RequestCtx -> Aff (Either AppError Html)
cachedInnerDynamic ctx = do
  let key = dynamicCacheKey ctx
  mCached <- liftEffect $ lookupDynamic ctx.cache.dynamic key
  case mCached of
    Just html -> pure (Right html)
    Nothing -> do
      result <- pageRenderer ctx.cfg ctx.route ctx.lang Nothing
      case result of
        Left err -> pure (Left err)
        Right html -> do
          liftEffect $ insertDynamic ctx.cache.dynamic key html defaultTtlMs
          pure (Right html)

-- | Dynamic-cache key: the `(Route, Lang)` pair itself.
-- |
-- | Previously a rendered string (`show route <> ":" <> show lang`), which
-- | rested on `Show Route` being injective — a hand-written instance with
-- | nothing enforcing it. The tuple removes that assumption rather than
-- | testing it: `Ord Route` is derived, so distinct routes are distinct keys
-- | by construction and no encoding can collide.
dynamicCacheKey :: RequestCtx -> Tuple Route Lang
dynamicCacheKey ctx = Tuple ctx.route ctx.lang

-- | Render fresh, cache nothing.
freshPage :: RequestCtx -> Aff Server.Response
freshPage ctx = renderThen ctx (const (pure unit))

-- | Render the page, hand the Html to `store` (which may cache it), respond.
renderThen :: RequestCtx -> (Html -> Aff Unit) -> Aff Server.Response
renderThen ctx store = do
  result <- pageRenderer ctx.cfg ctx.route ctx.lang (statusFor ctx)
  case result of
    Left err -> failurePage ctx err
    Right html -> do
      store html
      pure $ fullPage ctx (statusFor ctx) html

-- | A fragment request is either an Alpine AJAX navigation (x-alpine-request
-- | header) or a prefetch of a ?_frag=1 URL. Both return the same fragment.
isFragmentRequest :: Map String String -> Map String String -> Boolean
isFragmentRequest headers query =
  Map.lookup alpineRequestHeader headers == Just "true" || Map.lookup "_frag" query == Just "1"

-- | Map AppError to HTTP status code
errorStatus :: AppError -> Int
errorStatus = case _ of
  NotFound -> 404
  HttpStatusError _ -> 502
  DecodeError _ -> 500
  HttpError _ -> 500
  FfiError _ -> 500
  ResendError _ -> 500
  Unauthorized -> 401

-- ============================================================================
-- Root redirect — / → /fr or /en based on Accept-Language
-- ============================================================================

redirectRoot :: Map String String -> Aff Server.Response
redirectRoot headers =
  -- 302 (not 301): the language preference redirect must be re-evaluated,
  -- and caches must vary on Accept-Language.
  pure $ Server.redirectVary Server.Found (routeUrl lang Home) [ Tuple "Vary" "Accept-Language" ]
  where
  lang = detectLang $ fromMaybe "" $ Map.lookup "accept-language" headers

-- | Detect language from Accept-Language header.
-- | Parses the first token (before q-value and region suffix), delegates to
-- | `parseLang`. Falls back to `defaultLang` for unsupported languages.
-- | Example: "fr-FR,fr;q=0.9" → "fr-FR" → "fr" → Fr
detectLang :: String -> Lang
detectLang header = fromMaybe defaultLang do
  token <- head (split (Pattern ",") header)
  tag <- head (split (Pattern ";q=") token)
  prefix <- head (split (Pattern "-") (toLower tag))
  parseLang prefix

-- ============================================================================
-- Entry point
-- ============================================================================
--
-- POST /api/contact and /api/newsletter were the Contact page's form
-- submission target and Home's newsletter signup — both deleted in the
-- clean-sheet rebuild (see .scratch/clean-sheet-homepage/). The handling
-- they called into (App.Form's decode/honeypot logic, App.Email's send
-- functions) is untouched kernel, still directly tested by
-- test/FormSpec.purs; only the page-specific HTTP glue that had no page
-- left to serve it was removed. Reintroducing a form is a page-content
-- decision for whichever ticket wants one, not assumed here.

main :: Effect Unit
main = do
  cfg <- loadConfig
  migrateOnly <- getEnvMaybe "MIGRATE_ONLY"
  case migrateOnly of
    Just _ -> case cfg.databaseUrl of
      Nothing -> Log.logErr "migrate-no-db" [ Tuple "msg" "DATABASE_URL not set" ]
      Just url -> launchAff_ do
        result <- migrate url
        liftEffect $ case result of
          Left err -> Log.logErr "migrate-failed" [ Tuple "error" (renderMigrationError err) ]
          Right n -> Log.logInfo "migrate-ok" [ Tuple "applied" (show n) ]
    Nothing -> do
      case cfg.databaseUrl of
        Just url -> launchAff_ do
          result <- migrate url
          liftEffect case result of
            Left err -> Log.logErr "auto-migrate-failed" [ Tuple "error" (renderMigrationError err) ]
            Right n -> if n > 0 then Log.logInfo "auto-migrate-ok" [ Tuple "applied" (show n) ] else pure unit
        Nothing -> pure unit
      cache <- mkPageCache
      Server.serve cfg.port cfg.staticRoot (router cfg cache)
