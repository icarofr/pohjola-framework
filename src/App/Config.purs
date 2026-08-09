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
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (stripSuffix) as S
import Data.String.Common (split, toLower)
import Data.String.Pattern (Pattern(..))
import Data.Tuple (Tuple(..))
import Data.Email (EmailAddress(..), mkEmailAddress)
import Effect (Effect)
import Effect.Console (log)

-- ============================================================================
-- Server configuration
-- ============================================================================

type Config =
  { port :: Int
  , staticRoot :: String
  , baseUrl :: String
  , resendApiKey :: Maybe String
  , emailFrom :: EmailAddress
  , emailTo :: EmailAddress
  , postsApiBase :: String
  , rateLimitMax :: Int
  , rateLimitWindowMs :: Number
  , databaseUrl :: Maybe String
  }

-- | Load configuration from environment variables.
loadConfig :: Effect Config
loadConfig = do
  portStr <- getEnv "PORT"
  let
    port' = case Int.fromString portStr of
      Just p -> p
      Nothing -> 3001
  if portStr /= "" && Int.fromString portStr == Nothing then log "Warning: Invalid PORT env var, falling back to 3001" else pure unit

  staticRoot <- getEnvDefault "STATIC_ROOT" "dist"
  -- dist/ is self-contained after `make build`; Docker sets STATIC_ROOT=.
  baseUrlStr <- getEnvDefault "BASE_URL" "https://example.com"
  resendApiKey <- getEnvMaybe "RESEND_API_KEY"

  emailFromStr <- getEnvDefault "EMAIL_FROM" "noreply@example.com"
  emailFrom <- parseEmailConfig "EMAIL_FROM" emailFromStr "noreply@example.com"

  emailToStr <- getEnvDefault "EMAIL_TO" "contact@example.com"
  emailTo <- parseEmailConfig "EMAIL_TO" emailToStr "contact@example.com"

  postsApiBase <- getEnvDefault "POSTS_API_BASE" "https://jsonplaceholder.typicode.com"
  rateLimitMaxStr <- getEnvDefault "RATE_LIMIT_MAX" "20"
  rateLimitWindowStr <- getEnvDefault "RATE_LIMIT_WINDOW_MS" "60000"
  databaseUrl <- getEnvMaybe "DATABASE_URL"

  let
    rateLimitWindowMs = case Int.fromString rateLimitWindowStr of
      Just w -> Int.toNumber w
      Nothing -> 60000.0
  if rateLimitWindowStr /= "60000" && Int.fromString rateLimitWindowStr == Nothing then log "Warning: Invalid RATE_LIMIT_WINDOW_MS env var, falling back to 60000" else pure unit
  pure
    { port: port'
    , staticRoot
    , baseUrl: stripTrailingSlash baseUrlStr
    , resendApiKey
    , emailFrom
    , emailTo
    , postsApiBase
    -- 0 disables rate limiting (local dev, integration tests).
    , rateLimitMax: case Int.fromString rateLimitMaxStr of
        Just m -> m
        Nothing -> 20
    , rateLimitWindowMs
    , databaseUrl
    }

-- | Parse an env var as an EmailAddress, falling back to a known-valid default
-- | (with a warning) when the value is invalid. The defaults are hardcoded
-- | literals verified at compile time — `mkEmailAddress` always succeeds on them.
parseEmailConfig :: String -> String -> String -> Effect EmailAddress
parseEmailConfig label value fallback =
  case mkEmailAddress value of
    Just e -> pure e
    Nothing -> do
      log ("Warning: Invalid " <> label <> " env var, falling back to " <> fallback)
      case mkEmailAddress fallback of
        Just e -> pure e
        Nothing -> pure (EmailAddress "fallback@example.com") -- unreachable: fallback is always valid

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
