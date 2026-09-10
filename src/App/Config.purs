-- | Static configuration — port, static root, MIME types.
-- |
-- | Configuration is in code (compiler-checked) or environment variables.
-- | No JSON/YAML config files.
module App.Config where

import Prelude

import App.Env (getEnvDefault, getEnvMaybe)
import Data.Array (last, tail)
import Data.Int as Int
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (stripSuffix) as S
import Data.String.Common (split, toLower)
import Data.String.Pattern (Pattern(..))
import Data.Tuple (Tuple(..))
import Data.Email (EmailAddress, defaultEmailAddress, mkEmailAddress)
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
  -- | Secure by default (true). __Host- prefixed session cookies (ADR-002)
  -- | require Secure + HTTPS; a browser silently refuses to send them back
  -- | over plain http://localhost, breaking `make dev`'s login flow. Set
  -- | DEV_ALLOW_INSECURE_COOKIES=true locally to test login without HTTPS.
  -- | Never set in production — this is an explicit opt-OUT of the safe
  -- | default, not the other way around.
  , secureCookies :: Boolean
  }

-- | Load configuration from environment variables.
loadConfig :: Effect Config
loadConfig = do
  portStr <- getEnvDefault "PORT" "3000"
  port' <- parseIntConfig "PORT" portStr 3000

  staticRoot <- getEnvDefault "STATIC_ROOT" "dist"
  -- dist/ is self-contained after `make build`; Docker sets STATIC_ROOT=.
  baseUrlStr <- getEnvDefault "BASE_URL" "https://example.com"
  resendApiKey <- getEnvMaybe "RESEND_API_KEY"

  emailFromStr <- getEnvDefault "EMAIL_FROM" "noreply@example.com"
  emailFrom <- parseEmailConfig "EMAIL_FROM" emailFromStr "noreply@example.com"

  emailToStr <- getEnvDefault "EMAIL_TO" "contact@example.com"
  emailTo <- parseEmailConfig "EMAIL_TO" emailToStr "contact@example.com"

  postsApiBase <- getEnvDefault "POSTS_API_BASE" ""
  rateLimitMaxStr <- getEnvDefault "RATE_LIMIT_MAX" "20"
  -- 0 disables rate limiting (local dev, integration tests).
  rateLimitMax <- parseIntConfig "RATE_LIMIT_MAX" rateLimitMaxStr 20

  rateLimitWindowStr <- getEnvDefault "RATE_LIMIT_WINDOW_MS" "60000"
  rateLimitWindowMsInt <- parseIntConfig "RATE_LIMIT_WINDOW_MS" rateLimitWindowStr 60000
  let rateLimitWindowMs = Int.toNumber rateLimitWindowMsInt

  databaseUrl <- getEnvMaybe "DATABASE_URL"
  insecureCookiesStr <- getEnvDefault "DEV_ALLOW_INSECURE_COOKIES" "false"

  pure
    { port: port'
    , staticRoot
    , baseUrl: stripTrailingSlash baseUrlStr
    , resendApiKey
    , emailFrom
    , emailTo
    , postsApiBase
    , rateLimitMax
    , rateLimitWindowMs
    , databaseUrl
    , secureCookies: insecureCookiesStr /= "true"
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
      pure (defaultEmailAddress fallback)

-- | Parse an env var as an Int, falling back (with a warning) when the value
-- | fails to parse — the same "parse or warn-and-fallback" shape as
-- | parseEmailConfig, so PORT/RATE_LIMIT_MAX/RATE_LIMIT_WINDOW_MS share one
-- | rule instead of three hand-rolled copies. Reads via getEnvDefault, so an
-- | unset var already equals the fallback's own string and parses straight
-- | back to it without ever warning.
parseIntConfig :: String -> String -> Int -> Effect Int
parseIntConfig label value fallback =
  case Int.fromString value of
    Just n -> pure n
    Nothing -> do
      log ("Warning: Invalid " <> label <> " env var, falling back to " <> show fallback)
      pure fallback

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
