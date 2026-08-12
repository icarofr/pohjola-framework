-- | HTTP server boundary — Bun.serve via tamed FFI (ADR-003, ADR-007).
-- |
-- | Effects in the type (Aff for async), errors as values. The PS side owns
-- | all routing, security headers, and error containment. The JS side
-- | (App.ServerBun.js) is plumbing only — no app logic.
-- | Export list is explicit for the opaque `ErrorStatus` boundary and the
-- | closed `RedirectKind` set. `ErrorStatus 200` is unconstructible outside
-- | this module and `errorStatusCode` is the only way in.
-- |
-- | This was previously an open `module App.Server where`, which exports every
-- | constructor — so the "constructor unexported" claim in the comment below
-- | was false and the boundary was still a convention. Adding a member here
-- | without thinking is how that regresses.
module App.Server
  ( Method(..)
  , Request
  , ResponseBody(..)
  , Response
  , ErrorStatus
  , errorStatusCode
  , RedirectKind(..)
  , redirectStatus
  , redirectCachePolicy
  , securityHeaders
  , cspWithNonce
  , withCsp
  , htmlCacheControl
  , errorCacheControl
  , ok
  , okWith
  , okText
  , htmlErrorResponse
  , notFound
  , methodNotAllowed
  , internalError
  , redirect
  , redirectVary
  , tooManyRequests
  , withRequestId
  , fileResponse
  , streamResponse
  , serveStatic
  , serve
  , nextRequestId
  , parseMethod
  , parsePath
  , parseQuery
  , headersToMap
  , isUnsafePath
  ) where

import Prelude

import App.Alpine (alpineRequestHeader)
import App.Config (mimeType)
import App.Logger (Level(..))
import App.Logger as AppLog
import App.ServerBun (JsRequest, JsResponse, ReadableStream, generateNonce, serveImpl)
import Data.Array (cons, filter, mapMaybe, tail)
import Data.Either (Either(..))
import Data.Foldable (any, intercalate, null)
import Data.FormURLEncoded (decode)
import Data.FormURLEncoded as FormURLEncoded
import Data.Int as Int
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (split) as S
import Data.String.Common (toLower)
import Data.String.Pattern (Pattern(..))
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (Aff, attempt, launchAff_)
import Effect.Class (liftEffect)
import Effect.Ref as Ref
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn2, runEffectFn1)
import Foreign (unsafeToForeign)
import Foreign.Object (Object)
import Foreign.Object as Object
import Node.Encoding (Encoding(..))
import Node.FS.Aff as FS

-- ============================================================================
-- Types
-- ============================================================================

data Method = GET | HEAD | POST | MethodOther String

derive instance eqMethod :: Eq Method

instance showMethod :: Show Method where
  show = case _ of
    GET -> "GET"
    HEAD -> "HEAD"
    POST -> "POST"
    MethodOther m -> m

type Request =
  { id :: String
  , ip :: String
  , method :: Method
  , path :: Array String
  , headers :: Map String String
  , body :: Aff String
  , query :: Map String String
  , nonce :: String
  }

data ResponseBody
  = StringBody String
  | StreamBody ReadableStream

type Response =
  { status :: Int
  , headers :: Array (Tuple String String)
  , body :: ResponseBody
  }

-- ============================================================================
-- Security headers — applied to every response
-- ============================================================================

-- | CSP is NOT here — it's per-request (nonce-based). See `cspWithNonce` and
-- | `withCsp`. The `serve` function injects it after generating the nonce.
-- |
-- | Threat model: the primary XSS defense is upstream — the Html ADT escapes
-- | all text via Bun.escapeHTML, the unsafe HTML constructor is gate-banned
-- | outside 6 allowlisted modules, and ContractSpec property-tests that
-- | rendered text never contains unescaped `<`/`>`. CSP is defense-in-depth
-- | for future developer mistakes (an unsafe-HTML call passing user-influenced
-- | data, user data flowing into an Alpine constructor argument).
-- | `unsafe-eval` is required by Alpine's standard build (it evaluates
-- | attribute expressions via `new Function()`); the CSP build can't call
-- | global functions like the `fetch()` in `prefetchHover` and would force a
-- | custom-JS seam violating ADR-000. `unsafe-inline` was dropped in favour
-- | of per-request nonces on the two head `<script>` snippets and the JSON-LD
-- | script. See ADR-000 addendum.
securityHeaders :: Array (Tuple String String)
securityHeaders =
  [ Tuple "X-Content-Type-Options" "nosniff"
  , Tuple "X-Frame-Options" "DENY"
  , Tuple "Referrer-Policy" "strict-origin-when-cross-origin"
  , Tuple "Strict-Transport-Security" "max-age=31536000; includeSubDomains" -- Disable for local dev if needed
  , Tuple "Permissions-Policy" "camera=(), microphone=(), geolocation=()" -- Restrictive defaults
  ]

-- | CSP with a per-request nonce. `unsafe-eval` is required by Alpine's
-- | standard build; `strict-dynamic` lets the nonced Alpine script load its
-- | AJAX plugin without separate allowlisting. `'self'` is a fallback for
-- | browsers without `strict-dynamic` support.
cspWithNonce :: String -> String
cspWithNonce nonce =
  "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'nonce-"
    <> nonce
    <> "' 'self' 'unsafe-eval' 'strict-dynamic'"

-- | Inject the nonce-based CSP into a response's headers. Called by `serve`
-- | after generating the nonce. Replaces any existing CSP header.
withCsp :: String -> Response -> Response
withCsp nonce response =
  response { headers = cons (Tuple "Content-Security-Policy" (cspWithNonce nonce)) (filter (not <<< isCsp) response.headers) }
  where
  isCsp (Tuple k _) = k == "Content-Security-Policy"

-- ============================================================================
-- Constructors
-- ============================================================================

-- | Cache policy for successful HTML responses.
-- |
-- | `private` is not optional for a full page. Those embed a per-request CSP
-- | nonce (`renderPage` and `renderShellOpen` both take one). A
-- | shared cache storing such a response would replay one visitor's nonce to
-- | every other visitor, which destroys the property that makes a nonce worth
-- | having — unpredictability per response. CSP itself would not break, since
-- | the cached response carries its own matching header, but the defence it
-- | provides would be hollow.
-- |
-- | The `max-age` is load-bearing, and was established by measurement rather
-- | than reasoning. `private` alone leaves the response explicit but never
-- | fresh, with no validator to revalidate against — so nothing is reused, and
-- | the hover prefetch becomes pure overhead. With ten seconds the visitor's
-- | own browser serves the click from cache, which is what the prefetch was
-- | always for.
-- |
-- | The trade: within that window one nonce is reused, for that visitor only.
-- | Exploiting it requires already knowing the nonce, and learning it requires
-- | reading the response — which same-origin policy prevents, and which would
-- | permit immediate injection anyway. See RECONCILIATION.md "W6 outcome".
-- |
-- | AJAX fragments share this policy for a *different* reason, which the
-- | previous wording obscured by saying "each HTML response embeds a nonce":
-- | `renderFragment` emits no `<script>` tags and therefore no nonce at all
-- | (verified — a fragment response contains zero `nonce=` attributes).
-- | Fragments take `private` as a conservative default rather than a
-- | requirement, and `max-age` for the same click-reuse reason as pages.
-- |
-- | This also settles ADR-007's worry that `Vary` "proved fragile": with
-- | `private`, shared caches do not store these responses at all, so the CDN
-- | mishandling that motivated the concern cannot arise. `Vary` still guards
-- | the browser's own cache, which handles it correctly.
htmlCacheControl :: Tuple String String
htmlCacheControl = Tuple "Cache-Control" "private, max-age=10"

ok :: String -> Response
ok body = okWith [] body

-- | Successful HTML response.
-- |
-- | Unlike `redirectVary`, this does **not** take a caching choice, and that is
-- | deliberate rather than an oversight of the same class. Redirects have two
-- | genuinely correct behaviours selected by HTTP semantics — a 302 must be
-- | re-evaluated, a 301 is permanently cacheable — so the caller has a real
-- | decision to make. Successful HTML here has one: every response this
-- | constructor produces is either a full page (which embeds a per-request CSP
-- | nonce and must never be shared-cached) or an AJAX fragment (which carries
-- | no nonce and no user data, and takes `private` as the conservative
-- | default). Neither may be public.
-- |
-- | Adding a public-cache arm here would therefore *create* a hazard
-- | that does not currently exist: a caller could select it for a nonce-bearing
-- | page and publish one visitor's nonce. Today that is unrepresentable. The
-- | fix for "policy justified by who calls it" is to make the premise checked
-- | rather than to invent a choice — see the fragment/nonce assertions in
-- | ContractSpec.
-- |
-- | Policy emitted **last**, so a caller-supplied `Cache-Control` in `hdrs`
-- | cannot replace it. It previously came first and was overridable — the same
-- | defect fixed for the error and redirect constructors, left behind here.
okWith :: Array (Tuple String String) -> String -> Response
okWith hdrs body =
  { status: 200
  , headers: securityHeaders
      <> [ Tuple "Content-Type" "text/html; charset=utf-8" ]
      <> hdrs
      <> [ htmlCacheControl ]
  , body: StringBody body
  }

okText :: String -> String -> Response
okText contentType body =
  { status: 200, headers: securityHeaders <> [ Tuple "Content-Type" contentType ], body: StringBody body }

-- | An HTTP error status, guaranteed to be in 400..599.
-- |
-- | Exported as a type only — the constructor is withheld by the export list
-- | above, so `errorStatusCode` is the sole way to obtain one. That is what
-- | keeps `htmlErrorResponse`'s `no-store` from being a convention about who
-- | happens to call it today.
newtype ErrorStatus = ErrorStatus Int

-- | Smart constructor. **Clamps rather than rejects** — the signature is total,
-- | so there is no failure channel to report through.
-- |
-- | Out-of-range inputs become 500: anything below 400 is a success or redirect
-- | status that must never be answered with `no-store`, and anything above 599
-- | is not a valid HTTP status at all and would otherwise reach `new Response`
-- | at the Bun boundary. The previous version bounded only the lower end, so
-- | `errorStatusCode 999` passed through.
errorStatusCode :: Int -> ErrorStatus
errorStatusCode n = ErrorStatus (if n >= 400 && n <= 599 then n else 500)

-- | Cache policy for error responses: never store them.
-- |
-- | Emitted **last** in every error constructor. The Bun bridge applies headers
-- | with `Headers.set` in iteration order (`ServerBun.js`), so a duplicate key
-- | later in the array wins. Placing this after caller-supplied `extraHeaders`
-- | means a caller cannot replace the policy by passing its own
-- | `Cache-Control` — previously it came first and was overridable.
-- |
-- | `htmlCacheControl`'s `max-age` exists so a hover prefetch can be reused by
-- | the click. Applied to an error that is exactly wrong: a transient 502 or
-- | 500 would stick in the visitor's browser for ten seconds, so a retry after
-- | the upstream recovered would still be answered from cache. Errors are the
-- | one response class where staleness is never acceptable, because the whole
-- | point of retrying is to get a different answer.
errorCacheControl :: Tuple String String
errorCacheControl = Tuple "Cache-Control" "no-store"

-- | HTML **error** response with a status and extra headers.
-- |
-- | Named for what it is rather than what it renders. The previous generic
-- | status constructor implied any HTML response could use it, while the body
-- | unconditionally emitted `no-store` — so a future successful page routed
-- | through it would have silently become non-cacheable. The status is now an
-- | `ErrorStatus`, so the constructor cannot be reached with a 2xx at all: the
-- | policy is enforced by the type rather than by every caller happening to be
-- | an error today.
htmlErrorResponse :: String -> Array (Tuple String String) -> ErrorStatus -> Response
htmlErrorResponse body extraHeaders (ErrorStatus status) =
  { status
  , headers: securityHeaders
      <> [ Tuple "Content-Type" "text/html; charset=utf-8" ]
      <> extraHeaders
      <> [ errorCacheControl ]
  , body: StringBody body
  }

notFound :: Response
notFound =
  { status: 404, headers: securityHeaders <> [ Tuple "Content-Type" "text/plain; charset=utf-8" ] <> [ errorCacheControl ], body: StringBody "Not Found" }

methodNotAllowed :: Response
methodNotAllowed =
  { status: 405, headers: securityHeaders <> [ Tuple "Content-Type" "text/plain; charset=utf-8" ] <> [ errorCacheControl ], body: StringBody "Method Not Allowed" }

internalError :: Response
internalError =
  { status: 500, headers: securityHeaders <> [ Tuple "Content-Type" "text/plain; charset=utf-8" ] <> [ errorCacheControl ], body: StringBody "Internal Server Error" }

-- | The kind of redirect, which fixes BOTH the status code and the cache policy.
-- |
-- | Two rounds of iteration landed here. The first version baked `no-store`
-- | into a generic constructor — a policy justified only by today's callers.
-- | The second made the policy an independent argument, which forced a decision
-- | but could not force a *sound* one: a public policy remained pairable with a
-- | 302, and the status was a bare `Int`, so a non-3xx status was expressible too.
-- |
-- | HTTP already determines the pairing, so the caller has no free choice to
-- | make: 301 and 308 are permanent and cacheable; 302, 303 and 307 are
-- | request-dependent and must not be stored. Encoding the kind rather than the
-- | policy makes the invalid combinations unrepresentable instead of merely
-- | undocumented.
data RedirectKind
  = MovedPermanently
  -- ^ 301 — permanent, cacheable.
  | PermanentRedirect
  -- ^ 308 — permanent, cacheable, method-preserving.
  | Found
  -- ^ 302 — request-dependent. The root language redirect: a stored copy would
  -- pin one visitor's `Accept-Language` for everyone reusing it.
  | SeeOther
  -- ^ 303 — post/redirect/get. The form response carries a `?status=` banner,
  -- which is per-request state.
  | TemporaryRedirect

-- ^ 307 — request-dependent, method-preserving.
--
-- The kind derives the status/policy pairing, but not the *location*: for a
-- permanent kind the caller remains responsible for supplying a
-- request-independent target, which an arbitrary `String` cannot prove.

derive instance eqRedirectKind :: Eq RedirectKind

-- | Status code for a redirect kind. Total, and the only source of a redirect
-- | status — a non-3xx redirect is now unrepresentable.
redirectStatus :: RedirectKind -> Int
redirectStatus = case _ of
  MovedPermanently -> 301
  PermanentRedirect -> 308
  Found -> 302
  SeeOther -> 303
  TemporaryRedirect -> 307

-- | Cache policy for a redirect kind. Derived from the kind, not chosen: the
-- | permanent kinds are cacheable, the request-dependent ones never stored.
redirectCachePolicy :: RedirectKind -> Tuple String String
redirectCachePolicy = case _ of
  MovedPermanently -> Tuple "Cache-Control" "public, max-age=3600"
  PermanentRedirect -> Tuple "Cache-Control" "public, max-age=3600"
  Found -> errorCacheControl
  SeeOther -> errorCacheControl
  TemporaryRedirect -> errorCacheControl

redirect :: RedirectKind -> String -> Response
redirect kind location = redirectVary kind location []

-- | Policy emitted last so caller-supplied `extraHeaders` cannot replace it.
redirectVary :: RedirectKind -> String -> Array (Tuple String String) -> Response
redirectVary kind location extraHeaders =
  { status: redirectStatus kind
  , headers: securityHeaders <> [ Tuple "Location" location ] <> extraHeaders <> [ redirectCachePolicy kind ]
  , body: StringBody ""
  }

-- | 429 for rate-limited POSTs, with Retry-After so well-behaved clients
-- | (and curl users) know when the window opens again.
tooManyRequests :: Number -> Response
tooManyRequests retryAfterSec =
  { status: 429
  , headers: securityHeaders <>
      [ Tuple "Content-Type" "text/plain; charset=utf-8"
      , Tuple "Retry-After" (show (Int.ceil retryAfterSec))
      , errorCacheControl
      ]
  , body: StringBody "Too Many Requests"
  }

-- | Append the correlation header. Called by `serve` for EVERY response
-- | (including 500 containment), so clients/log readers can always
-- | correlate.
withRequestId :: String -> Response -> Response
withRequestId rid response = response { headers = response.headers <> [ Tuple "x-request-id" rid ] }

-- | Static file response (CSS, JS, images — never risk String mangling).
-- | Test-only: in production, Bun's `{ dir }` routes serve static files.
fileResponse :: String -> String -> Response
fileResponse contentType body =
  { status: 200
  , headers: securityHeaders <>
      [ Tuple "Content-Type" contentType
      , Tuple "Cache-Control" "public, max-age=3600"
      ]
  , body: StringBody body
  }

-- | Streaming response — shell arrives immediately, content streams in.
-- |
-- | Carries `Vary: x-alpine-request` like every other HTML response. Without
-- | it a cache could serve this full streamed document to a request that asked
-- | for a fragment, since the two differ only by that request header. This was
-- | the one HTML response missing it.
streamResponse :: ReadableStream -> Response
streamResponse stream =
  { status: 200
  , headers: securityHeaders <>
      [ Tuple "Content-Type" "text/html; charset=utf-8"
      , htmlCacheControl
      , Tuple "Vary" alpineRequestHeader
      ]
  , body: StreamBody stream
  }

-- ============================================================================
-- Static files — test-only (Bun's { dir } routes serve static in production)
-- ============================================================================

-- | Serve a file from staticRoot. Returns `Nothing` when the file doesn't
-- | exist, the MIME type is unknown, or the path is unsafe. Kept for
-- | ContractSpec and ServerSpec tests; not on the production hot path.
serveStatic :: String -> Array String -> Aff (Maybe Response)
serveStatic staticRoot path
  | isUnsafePath path = pure Nothing
  | null path = pure Nothing
  | otherwise =
      let
        fileName = intercalate "/" path
      in
        case mimeType fileName of
          Nothing -> pure Nothing
          Just mime -> do
            result <- attempt $ FS.readTextFile UTF8 (staticRoot <> "/" <> fileName)
            pure case result of
              Left _ -> Nothing
              Right content -> Just $ fileResponse mime content

-- ============================================================================
-- Server
-- ============================================================================

-- | Start the Bun.serve server. The handler runs in Aff; all errors are
-- | caught by `attempt` and mapped to `internalError`. The FFI callback
-- | bridge uses EffectFn2 — the FFI calls our callback with the untyped request
-- | and a respond function; we run the handler and call respond with the
-- | PS response converted to a JS object.
serve :: Int -> String -> (Request -> Aff Response) -> Effect Unit
serve port staticRoot handler = do
  counter <- Ref.new 0
  let
    callback :: EffectFn2 JsRequest (EffectFn1 JsResponse Unit) Unit
    callback = mkEffectFn2 \rawReq respond -> do
      rid <- nextRequestId counter
      nonce <- generateNonce
      let
        request =
          { id: rid
          , ip: rawReq.ip
          , method: parseMethod rawReq.method
          , path: parsePath rawReq.path
          , headers: headersToMap rawReq.headers
          , body: pure rawReq.body
          , query: parseQuery rawReq.query
          , nonce
          }
      AppLog.log Info "request" [ Tuple "rid" rid, Tuple "method" (show request.method), Tuple "path" rawReq.path, Tuple "ip" request.ip ]
      launchAff_ do
        result <- attempt (handler request)
        response <- case result of
          Left err -> do
            liftEffect $ AppLog.log Err "request-error" [ Tuple "rid" rid, Tuple "error" (show err) ]
            pure internalError
          Right r -> pure r
        liftEffect $ AppLog.log Info "response" [ Tuple "rid" rid, Tuple "status" (show response.status) ]
        let
          finalResponse = withRequestId rid (withCsp nonce response)
          rawResp =
            let
              bodyData = case finalResponse.body of
                StringBody s -> { bodyValue: s, bodyTag: "StringBody", bodyStream: unsafeToForeign (Nothing :: Maybe Unit) }
                StreamBody stream -> { bodyValue: "", bodyTag: "StreamBody", bodyStream: unsafeToForeign stream }
            in
              { status: finalResponse.status
              , headers: finalResponse.headers
              , bodyValue: bodyData.bodyValue
              , bodyTag: bodyData.bodyTag
              , bodyStream: bodyData.bodyStream
              }
        liftEffect $ runEffectFn1 respond rawResp
  serveImpl port staticRoot callback
  AppLog.log Info "server-started" [ Tuple "port" (show port) ]

-- | Monotonic request id — correlates every log line and the x-request-id
-- | response header for a request.
nextRequestId :: Ref.Ref Int -> Effect String
nextRequestId counter = do
  n <- Ref.modify (_ + 1) counter
  pure ("req-" <> show n)

-- ============================================================================
-- Internals — request parsing (FFI passes untyped strings, PS parses)
-- ============================================================================

parseMethod :: String -> Method
parseMethod method = case toLower method of
  "get" -> GET
  "head" -> HEAD
  "post" -> POST
  _ -> MethodOther method

-- | Split path on "/" — empty segments collapse (/en//about ≡ /en/about).
-- | The FFI passes url.pathname (e.g. "/en/posts"), no query string.
parsePath :: String -> Array String
parsePath pathname =
  filter (not <<< eq "") $ S.split (Pattern "/") pathname

-- | Parse query string (e.g. "?_frag=1") into a Map. The FFI passes
-- | url.search which starts with "?" or is empty.
parseQuery :: String -> Map String String
parseQuery queryString =
  case S.split (Pattern "?") queryString of
    [ _ ] -> Map.empty
    parts ->
      let
        qs = intercalate "?" (fromMaybe [] (tail parts))
      in
        case decode qs of
          Just form ->
            Map.fromFoldable (mapMaybe (\(Tuple k mv) -> Tuple k <$> mv) (FormURLEncoded.toArray form))
          Nothing -> Map.empty

headersToMap :: Object String -> Map String String
headersToMap obj = Map.fromFoldable (Object.toUnfoldable obj :: Array (Tuple String String))

-- ============================================================================
-- Utility functions for testing
-- ============================================================================

-- | Reject traversal: ".." segments or anything containing / or \ as a
-- | segment. Kept for ServerSpec tests; not on the production hot path
-- | (Bun's `{ dir }` routes use kernel-level path safety).
isUnsafePath :: Array String -> Boolean
isUnsafePath path = any isUnsafe path
  where
  isUnsafe segment = segment == ".." || segment == "\\"
