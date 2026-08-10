-- | HTTP server boundary — Bun.serve via tamed FFI (ADR-003, ADR-007).
-- |
-- | Effects in the type (Aff for async), errors as values. The PS side owns
-- | all routing, security headers, and error containment. The JS side
-- | (App.ServerBun.js) is plumbing only — no app logic.
module App.Server where

import Prelude

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

ok :: String -> Response
ok body = okWith [] body

okWith :: Array (Tuple String String) -> String -> Response
okWith hdrs body =
  { status: 200
  , headers: securityHeaders <> [ Tuple "Content-Type" "text/html; charset=utf-8" ] <> hdrs
  , body: StringBody body
  }

okText :: String -> String -> Response
okText contentType body =
  { status: 200, headers: securityHeaders <> [ Tuple "Content-Type" contentType ], body: StringBody body }

-- | HTML response with custom status and extra headers.
htmlResponse :: String -> Array (Tuple String String) -> Int -> Response
htmlResponse body extraHeaders status =
  { status
  , headers: securityHeaders <> [ Tuple "Content-Type" "text/html; charset=utf-8" ] <> extraHeaders
  , body: StringBody body
  }

notFound :: Response
notFound =
  { status: 404, headers: securityHeaders <> [ Tuple "Content-Type" "text/plain; charset=utf-8" ], body: StringBody "Not Found" }

methodNotAllowed :: Response
methodNotAllowed =
  { status: 405, headers: securityHeaders <> [ Tuple "Content-Type" "text/plain; charset=utf-8" ], body: StringBody "Method Not Allowed" }

internalError :: Response
internalError =
  { status: 500, headers: securityHeaders <> [ Tuple "Content-Type" "text/plain; charset=utf-8" ], body: StringBody "Internal Server Error" }

redirect :: Int -> String -> Response
redirect status location = redirectVary status location []

redirectVary :: Int -> String -> Array (Tuple String String) -> Response
redirectVary status location extraHeaders =
  { status
  , headers: securityHeaders <> [ Tuple "Location" location ] <> extraHeaders
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
-- | The ReadableStream is created by App.ServerBun.createStreamImpl and
-- | populated by App.Main.streamResponse. Status is always 200 (the shell
-- | is already sent before content resolves; we can't change it mid-stream).
streamResponse :: ReadableStream -> Response
streamResponse stream =
  { status: 200
  , headers: securityHeaders <> [ Tuple "Content-Type" "text/html; charset=utf-8" ]
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
