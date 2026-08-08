-- | Static configuration — port, static root, MIME types.
-- |
-- | Configuration is in code (compiler-checked) or environment variables.
-- | No JSON/YAML config files.
module App.Config where

import Prelude

import App.Env (getEnv, getEnvDefault, getEnvMaybe)
import Data.Array (last, tail)
import Data.Int as Int
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe, fromMaybe)
import Data.String (stripSuffix) as S
import Data.String.Common (split, toLower)
import Data.String.Pattern (Pattern(..))
import Data.Tuple (Tuple(..))
import Effect (Effect)

-- ============================================================================
-- Server configuration
-- ============================================================================

type Config =
  { port :: Int
  , staticRoot :: String
  , baseUrl :: String
  , resendApiKey :: Maybe String
  , emailFrom :: String
  , emailTo :: String
  , postsApiBase :: String
  , rateLimitMax :: Int
  , rateLimitWindowMs :: Number
  }

-- | Load configuration from environment variables.
loadConfig :: Effect Config
loadConfig = do
  portStr <- getEnv "PORT"
  let port' = fromMaybe 3001 (Int.fromString portStr)

  staticRoot <- getEnvDefault "STATIC_ROOT" "dist"
  -- dist/ is self-contained after `make build`; Docker sets STATIC_ROOT=.
  baseUrlStr <- getEnvDefault "BASE_URL" "https://example.com"
  resendApiKey <- getEnvMaybe "RESEND_API_KEY"
  emailFrom <- getEnvDefault "EMAIL_FROM" "noreply@example.com"
  emailTo <- getEnvDefault "EMAIL_TO" "contact@example.com"
  postsApiBase <- getEnvDefault "POSTS_API_BASE" "https://jsonplaceholder.typicode.com"
  rateLimitMaxStr <- getEnvDefault "RATE_LIMIT_MAX" "20"
  rateLimitWindowStr <- getEnvDefault "RATE_LIMIT_WINDOW_MS" "60000"

  let rateLimitWindowMs = Int.toNumber (fromMaybe 60000 (Int.fromString rateLimitWindowStr))
  pure
    { port: port'
    , staticRoot
    , baseUrl: stripTrailingSlash baseUrlStr
    , resendApiKey
    , emailFrom
    , emailTo
    , postsApiBase
    -- 0 disables rate limiting (local dev, integration tests).
    , rateLimitMax: fromMaybe 20 (Int.fromString rateLimitMaxStr)
    , rateLimitWindowMs
    }

-- | Remove trailing slash from URL so `baseUrl <> routeUrl ...` never doubles it.
stripTrailingSlash :: String -> String
stripTrailingSlash str = fromMaybe str (S.stripSuffix (Pattern "/") str)

-- ============================================================================
-- MIME type whitelist
-- ============================================================================

mimeTypes :: Map String String
mimeTypes = Map.fromFoldable
  [ Tuple "js" "application/javascript"
  , Tuple "css" "text/css"
  , Tuple "html" "text/html"
  , Tuple "ico" "image/x-icon"
  , Tuple "jpg" "image/jpeg"
  , Tuple "jpeg" "image/jpeg"
  , Tuple "png" "image/png"
  , Tuple "svg" "image/svg+xml"
  , Tuple "webp" "image/webp"
  , Tuple "avif" "image/avif"
  , Tuple "woff" "font/woff"
  , Tuple "woff2" "font/woff2"
  , Tuple "txt" "text/plain"
  , Tuple "xml" "application/xml"
  ]

-- | Look up MIME type by file extension. Returns Nothing for unknown types.
mimeType :: String -> Maybe String
mimeType fileName = do
  ext <- last =<< tail (split (Pattern ".") fileName)
  Map.lookup (toLower ext) mimeTypes
