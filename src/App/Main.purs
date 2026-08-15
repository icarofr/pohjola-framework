-- | Server entry point — MPA architecture
-- |
-- | Server renders all HTML via the Html ADT, Alpine.js provides interactivity.
-- | Bilingual routes: /en/* and /fr/*
module App.Main (main, pageRenderer, detectLang) where

import Prelude

import App.Alpine (alpineRequestHeader)
import App.Cache (PageCache, defaultTtlMs, insertDynamic, insertStatic, lookupDynamic, lookupStatic, mkPageCache)
import App.Config (Config, loadConfig)
import App.Email (ResendConfig, parseForm, sendContactEmail, sendNewsletterEmail)
import App.Env (getEnvMaybe)
import App.Error (AppError(..))
import App.Form (ContactSubmission(..), FormStatus(..), NewsletterSubmission(..), decodeContact, decodeNewsletter, formStatusQuery, parseFormStatus, apiContactPath, apiNewsletterPath)
import App.Migration (migrate, renderMigrationError)
import App.Features.About.Page as About
import App.Features.Contact.Page as Contact
import App.Features.Home.Page as Home
import App.Features.Posts.Page as Posts
import App.Html (Html)
import App.Layout.Page (renderErrorFragment, renderErrorPage, renderFragment, renderPage, renderShellClose, renderShellOpen)
import App.Logger as Log
import App.RateLimit (RateLimiter, RateLimitVerdict(..), checkRateLimit, mkRateLimiter)
import App.Server as Server
import App.ServerBun (streamResponseImpl)
import App.Sitemap (renderRobots, renderSitemap)
import Data.Array (filter, head)
import Data.Either (Either(..))
import Data.I18n (Lang, defaultLang, parseLang)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe, isNothing)
import Data.Route (Route(..), parseRoute, routeUrl)
import Data.String.Common (split, toLower)
import Data.String.Pattern (Pattern(..))
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)

-- ============================================================================
-- Router
-- ============================================================================

-- | Rate-limit gate for the two form POST endpoints. A `rateLimitMax` of 0
-- | disables limiting (local dev). Denials get a 429 with Retry-After equal
-- | to the current window's remaining lifetime (not a fresh full window) —
-- | telling a denied client to wait 60s when the window opens in 3s is wrong.
rateGate :: Config -> RateLimiter -> Server.Request -> Aff Server.Response -> Aff Server.Response
rateGate cfg limiter request next =
  if cfg.rateLimitMax <= 0 then next
  else do
    verdict <- liftEffect $ checkRateLimit limiter cfg.rateLimitMax cfg.rateLimitWindowMs request.ip
    case verdict of
      Allowed -> next
      Denied retryAfterMs -> do
        liftEffect $ Log.logWarn "rate-limited" [ Tuple "rid" request.id, Tuple "ip" request.ip ]
        pure $ Server.tooManyRequests (retryAfterMs / 1000.0)

router :: Config -> RateLimiter -> PageCache -> Server.Request -> Aff Server.Response
router cfg limiter cache request@{ method, path, headers, body, query, nonce } = case method of
  Server.POST -> case path of
    _ | path == filter (not <<< eq "") (split (Pattern "/") apiContactPath) -> rateGate cfg limiter request (handleContact cfg request.id headers body)
    _ | path == filter (not <<< eq "") (split (Pattern "/") apiNewsletterPath) -> rateGate cfg limiter request (handleNewsletter cfg request.id headers body)
    _ -> pure Server.notFound
  Server.GET -> handleGet cfg cache nonce headers query path
  Server.HEAD -> handleGet cfg cache nonce headers query path
  _ -> pure Server.methodNotAllowed

-- | Shared handler for GET and HEAD (identical except body stripping in Server).
handleGet :: Config -> PageCache -> String -> Map String String -> Map String String -> Array String -> Aff Server.Response
handleGet cfg cache nonce headers query path = case path of
  [] -> redirectRoot headers
  [ "healthz" ] -> pure $ Server.okText "text/plain" "ok"
  [ "robots.txt" ] -> pure $ Server.okText "text/plain" (renderRobots cfg.baseUrl)
  [ "sitemap.xml" ] -> pure $ Server.okText "application/xml" (renderSitemap cfg.baseUrl)
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
-- | the fix was narrower than the contract it restored. `Home` stands in for
-- | the missing route, exactly as `renderErrorPage` already does for its header.
routeMiss404 :: String -> Boolean -> Lang -> Server.Response
routeMiss404 nonce wantsFragment lang =
  if wantsFragment then
    Server.htmlErrorResponse (renderErrorFragment lang Home 404) [ varyHeader ] (Server.errorStatusCode 404)
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
-- | Data-backed pages (Posts) fetch via Aff and may return `Left AppError`.
pageRenderer :: Config -> Route -> Lang -> Aff (Either AppError Html)
pageRenderer cfg route lang = case route of
  Home -> Home.render lang
  About -> About.render lang
  Contact -> Contact.render lang
  PostList -> Posts.renderList cfg lang
  PostDetail id -> Posts.renderDetail cfg lang id

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

fullPage :: RequestCtx -> Maybe FormStatus -> Html -> Server.Response
fullPage ctx status html =
  Server.okWith [ varyHeader ] (renderPage ctx.cfg.baseUrl ctx.nonce ctx.lang ctx.route status html)

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
    (renderErrorFragment ctx.lang ctx.route (errorStatus err))
    [ varyHeader ]
    (Server.errorStatusCode (errorStatus err))

-- | Serve a route.
-- |
-- | Exhaustive over `Route` on purpose. The previous wildcard let a new route
-- | compile while silently inheriting static serving; naming every route forces
-- | a decision. This deliberately does NOT introduce a policy sum type — with
-- | one streamed and one dynamically-cached route that would be abstraction
-- | ahead of need, and exhaustiveness is the property actually wanted.
-- |
-- | PostList streams: the shell arrives immediately, content follows when the
-- | upstream fetch resolves. PostDetail can 404, so it cannot stream — the
-- | status is committed at shell time. Fragment requests never stream.
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
  else case ctx.route of
    Home -> cachedStaticPage ctx
    About -> cachedStaticPage ctx
    Contact -> cachedStaticPage ctx
    PostList -> streamPostList ctx
    PostDetail _ -> cachedDynamicPage ctx

-- | True when the request carries a form-status banner query.
hasStatusQuery :: RequestCtx -> Boolean
hasStatusQuery ctx = Map.member "status" ctx.query

-- | Alpine AJAX fragment. Note the error path answers with a *fragment*, not a
-- | full document: the client swaps this response into `#content`, so a
-- | `renderErrorPage` here would nest a complete `<!DOCTYPE>` document inside
-- | the page body. See ADR-007 (streaming errors) — the same principle, applied
-- | to the path that lacked it.
handleFragment :: RequestCtx -> Aff Server.Response
handleFragment ctx = do
  result <- pageRenderer ctx.cfg ctx.route ctx.lang
  case result of
    Left err -> failureFragment ctx err
    Right html ->
      pure $ Server.okWith [ varyHeader ] $ renderFragment ctx.lang ctx.route html

-- | Pure page cached per (route, lang) for the process lifetime.
cachedStaticPage :: RequestCtx -> Aff Server.Response
cachedStaticPage ctx = do
  mCached <- liftEffect $ lookupStatic ctx.cache.static ctx.route ctx.lang
  case mCached of
    Just html -> pure $ fullPage ctx Nothing html
    Nothing -> renderThen ctx \html ->
      liftEffect $ insertStatic ctx.cache.static ctx.route ctx.lang html

-- | Data-backed page cached under a TTL.
cachedDynamicPage :: RequestCtx -> Aff Server.Response
cachedDynamicPage ctx = do
  let key = dynamicCacheKey ctx
  mCached <- liftEffect $ lookupDynamic ctx.cache.dynamic key
  case mCached of
    Just html -> pure $ fullPage ctx Nothing html
    Nothing -> renderThen ctx \html ->
      liftEffect $ insertDynamic ctx.cache.dynamic key html defaultTtlMs

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
  result <- pageRenderer ctx.cfg ctx.route ctx.lang
  case result of
    Left err -> failurePage ctx err
    Right html -> do
      store html
      pure $ fullPage ctx (statusFor ctx) html

-- | Stream PostList: shell arrives immediately, content streams when the
-- | API fetch resolves. The ReadableStream is created by the FFI's
-- | `streamResponseImpl` — the fetch and stream population happen entirely
-- | in the JS event loop (async start + native fetch), not in a forked Aff.
-- | This avoids the Aff scheduler issue where forked fibers don't resume
-- | reliably on Bun.
streamPostList :: RequestCtx -> Aff Server.Response
streamPostList ctx = do
  stream <- liftEffect $ streamResponseImpl
    (Posts.streamListUrl ctx.cfg)
    (Posts.renderListContent ctx.lang)
    (renderShellOpen ctx.cfg.baseUrl ctx.nonce ctx.lang PostList)
    (renderShellClose ctx.nonce ctx.lang PostList)
  pure $ Server.streamResponse stream

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
-- POST handlers
-- ============================================================================

-- | Detect language from form body (hidden `lang` field), fall back to default.
formLang :: String -> Lang
formLang bodyStr = fromMaybe defaultLang (parseForm bodyStr "lang" >>= parseLang)

-- | Same-origin gate for form POSTs. If an Origin header is present, it must
-- | match our deployed origin exactly. Absent header (curl, no-JS, privacy
-- | tools) is allowed — CSRF risk without Origin is handled by the honeypot
-- | and redirect-only responses (no body, no side effects beyond email).
sameOriginOk :: Config -> Map String String -> Boolean
sameOriginOk cfg headers = case Map.lookup "origin" headers of
  Nothing -> true
  Just origin -> origin == cfg.baseUrl

-- | Success redirect back to the referring form, with banner status query.
redirectStatus :: Lang -> Route -> FormStatus -> Aff Server.Response
redirectStatus lang route status =
  pure $ Server.redirect Server.SeeOther (routeUrl lang route <> "?status=" <> formStatusQuery status)

-- | Build a ResendConfig from the app config when the API key is present.
resendConfig :: Config -> Maybe ResendConfig
resendConfig cfg = (\apiKey -> { apiKey, from: cfg.emailFrom, to: cfg.emailTo }) <$> cfg.resendApiKey

handleContact :: Config -> String -> Map String String -> Aff String -> Aff Server.Response
handleContact cfg rid headers body =
  if not (sameOriginOk cfg headers) then do
    liftEffect $ Log.logWarn "form-rejected" [ Tuple "rid" rid, Tuple "reason" "origin" ]
    pure Server.notFound
  else do
    bodyStr <- body
    let lang = formLang bodyStr
    case decodeContact bodyStr of
      HoneypotHit -> do
        liftEffect $ Log.logWarn "form-rejected" [ Tuple "rid" rid, Tuple "reason" "honeypot" ]
        redirectStatus lang Contact FormSuccess
      InvalidContact -> redirectStatus lang Contact FormError
      SubmitContact contactForm -> case resendConfig cfg of
        Nothing -> do
          liftEffect $ Log.logWarn "email-not-configured" [ Tuple "rid" rid, Tuple "form" "contact" ]
          redirectStatus lang Contact FormError
        Just rc -> do
          result <- sendContactEmail rc { name: contactForm.name, email: contactForm.email, message: contactForm.message }
          case result of
            Right _ -> redirectStatus lang Contact FormSuccess
            Left err -> liftEffect (Log.logErr "email-failed" [ Tuple "rid" rid, Tuple "form" "contact", Tuple "error" (show err) ]) *> redirectStatus lang Contact FormError

handleNewsletter :: Config -> String -> Map String String -> Aff String -> Aff Server.Response
handleNewsletter cfg rid headers body =
  if not (sameOriginOk cfg headers) then do
    liftEffect $ Log.logWarn "form-rejected" [ Tuple "rid" rid, Tuple "reason" "origin" ]
    pure Server.notFound
  else do
    bodyStr <- body
    let lang = formLang bodyStr
    case decodeNewsletter bodyStr of
      NewsletterHoneypot -> do
        liftEffect $ Log.logWarn "form-rejected" [ Tuple "rid" rid, Tuple "reason" "honeypot" ]
        redirectStatus lang Home FormSubscribed
      InvalidNewsletter -> redirectStatus lang Home FormError
      SubmitNewsletter emailAddr -> case resendConfig cfg of
        Nothing -> do
          liftEffect $ Log.logWarn "email-not-configured" [ Tuple "rid" rid, Tuple "form" "newsletter" ]
          redirectStatus lang Home FormError
        Just rc -> do
          result <- sendNewsletterEmail rc emailAddr
          case result of
            Right _ -> redirectStatus lang Home FormSubscribed
            Left err -> liftEffect (Log.logErr "email-failed" [ Tuple "rid" rid, Tuple "form" "newsletter", Tuple "error" (show err) ]) *> redirectStatus lang Home FormError

-- ============================================================================
-- Entry point
-- ============================================================================

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
      limiter <- mkRateLimiter
      cache <- mkPageCache
      when (isNothing cfg.resendApiKey) $ Log.logWarn "resend-key-missing" [ Tuple "msg" "contact/newsletter forms will return status=error" ]
      Server.serve cfg.port cfg.staticRoot (router cfg limiter cache)
