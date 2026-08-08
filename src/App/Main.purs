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
import App.Error (AppError(..))
import App.Form (ContactSubmission(..), FormStatus(..), NewsletterSubmission(..), decodeContact, decodeNewsletter, formStatusQuery, parseFormStatus, unEmailAddress, apiContactPath, apiNewsletterPath)
import App.Features.About.Page as About
import App.Features.Contact.Page as Contact
import App.Features.Home.Page as Home
import App.Features.Legal.Page as Legal
import App.Features.Posts.Page as Posts
import App.Html (Html)
import App.Layout.Head (cspNoncePlaceholder)
import App.Layout.Page (renderErrorPage, renderFragment, renderPage, renderShellClose, renderShellOpen)
import App.Logger as Log
import App.RateLimit (RateLimiter, checkRateLimit, mkRateLimiter)
import App.Server as Server
import App.ServerBun (streamResponseImpl)
import App.Sitemap (renderRobots, renderSitemap)
import Data.Array (elem, filter, head)
import Data.Either (Either(..))
import Data.I18n (Lang, defaultLang, parseLang)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe, isNothing)
import Data.Route (Route(..), parseRoute, routeUrl, staticRoutes)
import Data.String (replace) as S
import Data.String.Common (split, toLower)
import Data.String.Pattern (Pattern(..), Replacement(..))
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (Aff)
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
    if verdict.allowed then next
    else do
      liftEffect $ Log.logWarn "rate-limited" [ Tuple "rid" request.id, Tuple "ip" request.ip ]
      pure $ Server.tooManyRequests (fromMaybe skyIsFallingSeconds (verdict.retryAfterMs <#> (_ / 1000.0)))
  where
  -- | Denial without a computed window end should not happen, but if it
  -- | does, a whole-window value is the safe over-wait.
  skyIsFallingSeconds = cfg.rateLimitWindowMs / 1000.0

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
    Just { lang, route } -> handleRoute cfg cache nonce lang route headers query
    Nothing -> pure $ Server.htmlResponse (renderErrorPage (langFromPath path) 404) [] 404

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
  Legal -> Legal.render lang
  PostList -> Posts.renderList cfg lang
  PostDetail id -> Posts.renderDetail cfg lang id

-- | Handle route — returns full page for non-AJAX requests, fragment for AJAX.
-- | PostList streams: shell arrives immediately, content streams when data
-- | resolves via Bun's native fetch in the ReadableStream's async start.
-- | PostDetail can 404, so it can't stream (status committed at shell time).
-- | Fragment requests never stream (small, already fast).
handleRoute :: Config -> PageCache -> String -> Lang -> Route -> Map String String -> Map String String -> Aff Server.Response
handleRoute cfg cache nonce lang route headers query =
  if isFragmentRequest headers query then
    handleFragment cfg lang route
  else
    case route of
      PostList -> streamPostList cfg nonce lang
      PostDetail id -> do
        let key = "post:" <> show id <> ":" <> show lang
        mCached <- liftEffect $ lookupDynamic cache.dynamic key
        case mCached of
          Just body -> pure $ Server.okWith [] body
          Nothing -> do
            res <- handleStatic cfg cache lang route query
            case res.body of
              Server.StringBody b ->
                if res.status == 200 then do
                  liftEffect $ insertDynamic cache.dynamic key b defaultTtlMs
                  pure res
                else pure res
              _ -> pure res
      _ -> handleStatic cfg cache lang route query

-- | Fragment handler — renders the full page content and returns a fragment.
handleFragment :: Config -> Lang -> Route -> Aff Server.Response
handleFragment cfg lang route = do
  result <- pageRenderer cfg route lang
  case result of
    Left err -> do
      liftEffect $ Log.logErr "page-render-failed" [ Tuple "path" (routeUrl lang route), Tuple "error" (show err) ]
      pure $ Server.htmlResponse (renderErrorPage lang (errorStatus err)) [] (errorStatus err)
    Right html ->
      pure $ Server.okWith [ Tuple "Vary" alpineRequestHeader ] $ renderFragment lang route html

-- | Static page handler — renders the full page, returns StringBody.
-- | Sends Vary: x-alpine-request so the browser caches full pages and
-- | fragments separately (the same URL returns different content based
-- | on the x-alpine-request header).
handleStatic :: Config -> PageCache -> Lang -> Route -> Map String String -> Aff Server.Response
handleStatic cfg cache lang route query = do
  let isStatic = route `elem` staticRoutes
  let hasStatus = Map.member "status" query
  let varyHeader = Tuple "Vary" alpineRequestHeader

  if isStatic && not hasStatus then do
    mCached <- liftEffect $ lookupStatic cache.static route lang
    case mCached of
      Just body -> pure $ Server.okWith [ varyHeader ] body
      Nothing -> do
        result <- pageRenderer cfg route lang
        case result of
          Left err -> do
            liftEffect $ Log.logErr "page-render-failed" [ Tuple "path" (routeUrl lang route), Tuple "error" (show err) ]
            pure $ Server.htmlResponse (renderErrorPage lang (errorStatus err)) [] (errorStatus err)
          Right html -> do
            let
              status = Map.lookup "status" query >>= parseFormStatus
              body = renderPage cfg.baseUrl lang route status html
            liftEffect $ insertStatic cache.static route lang body
            pure $ Server.okWith [ varyHeader ] body
  else do
    result <- pageRenderer cfg route lang
    case result of
      Left err -> do
        liftEffect $ Log.logErr "page-render-failed" [ Tuple "path" (routeUrl lang route), Tuple "error" (show err) ]
        pure $ Server.htmlResponse (renderErrorPage lang (errorStatus err)) [] (errorStatus err)
      Right html ->
        let
          status = Map.lookup "status" query >>= parseFormStatus
        in
          pure $ Server.okWith [ varyHeader ] $ renderPage cfg.baseUrl lang route status html

-- | Stream PostList: shell arrives immediately, content streams when the
-- | API fetch resolves. The ReadableStream is created by the FFI's
-- | `streamResponseImpl` — the fetch and stream population happen entirely
-- | in the JS event loop (async start + native fetch), not in a forked Aff.
-- | This avoids the Aff scheduler issue where forked fibers don't resume
-- | reliably on Bun.
streamPostList :: Config -> String -> Lang -> Aff Server.Response
streamPostList cfg nonce lang = do
  stream <- liftEffect $ streamResponseImpl
    (Posts.streamListUrl cfg)
    (Posts.renderListContent lang)
    (S.replace (Pattern cspNoncePlaceholder) (Replacement nonce) (renderShellOpen cfg.baseUrl lang PostList))
    (S.replace (Pattern cspNoncePlaceholder) (Replacement nonce) (renderShellClose lang PostList))
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
  pure $ Server.redirectVary 302 (routeUrl lang Home) [ Tuple "Vary" "Accept-Language" ]
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
  pure $ Server.redirect 303 (routeUrl lang route <> "?status=" <> formStatusQuery status)

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
          result <- sendContactEmail rc { name: contactForm.name, email: unEmailAddress contactForm.email, message: contactForm.message }
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
          result <- sendNewsletterEmail rc (unEmailAddress emailAddr)
          case result of
            Right _ -> redirectStatus lang Home FormSubscribed
            Left err -> liftEffect (Log.logErr "email-failed" [ Tuple "rid" rid, Tuple "form" "newsletter", Tuple "error" (show err) ]) *> redirectStatus lang Home FormError

-- ============================================================================
-- Entry point
-- ============================================================================

main :: Effect Unit
main = do
  cfg <- loadConfig
  limiter <- mkRateLimiter
  cache <- mkPageCache
  when (isNothing cfg.resendApiKey) $ Log.logWarn "resend-key-missing" [ Tuple "msg" "contact/newsletter forms will return status=error" ]
  Server.serve cfg.port cfg.staticRoot (router cfg limiter cache)
