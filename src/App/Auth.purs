-- | Authentication and session management — the single boundary for auth flows.
-- |
-- | Contract: no inline session checks in App.Main or feature modules.
-- | All cookie -> Session resolution goes through `requireAuth`.
-- |
-- | Follows ADR-002 (Auth shape), ADR-004 (Sessions), and ADR-005 (CSRF).
module App.Auth
  ( UserId(..)
  , SessionId(..)
  , Session(..)
  , SessionStore
  , mkSessionStore
  , requireAuth
  , createSession
  , destroySession
  , parseSessionCookie
  , formatSessionCookie
  , formatClearSessionCookie
  ) where

import Prelude

import App.Error (AppError(..))
import Data.Array (findMap)
import Data.Either (Either(..))
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.String (Pattern(..), stripPrefix)
import Data.String.Common (split, trim)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Ref (Ref)
import Effect.Ref as Ref

newtype UserId = UserId String

derive instance newtypeUserId :: Newtype UserId _
derive newtype instance eqUserId :: Eq UserId
derive newtype instance ordUserId :: Ord UserId
derive newtype instance showUserId :: Show UserId

newtype SessionId = SessionId String

derive instance newtypeSessionId :: Newtype SessionId _
derive newtype instance eqSessionId :: Eq SessionId
derive newtype instance ordSessionId :: Ord SessionId
derive newtype instance showSessionId :: Show SessionId

newtype Session = Session
  { userId :: UserId
  , sessionId :: SessionId
  }

derive instance newtypeSession :: Newtype Session _
derive newtype instance eqSession :: Eq Session
derive newtype instance showSession :: Show Session

-- | Thread-safe in-memory session store (Ref of Map).
-- | For production clustering, swap internal storage with SQLite/Postgres.
type SessionStore = Ref (Map String Session)

-- | Initialize a new session store.
mkSessionStore :: Effect SessionStore
mkSessionStore = Ref.new Map.empty

-- | Parse the `session_id` token from a standard `Cookie` header string.
parseSessionCookie :: String -> Maybe SessionId
parseSessionCookie cookieHeader =
  let
    pairs = map trim (split (Pattern ";") cookieHeader)
  in
    findMap (stripPrefix (Pattern "session_id=") >>> map SessionId) pairs

-- | Format a Set-Cookie header value with security hardening flags (ADR-004).
formatSessionCookie :: SessionId -> Int -> String
formatSessionCookie (SessionId token) maxAgeSec =
  "session_id=" <> token <> "; Path=/; HttpOnly; SameSite=Lax; Max-Age=" <> show maxAgeSec

-- | Format a Set-Cookie header value that immediately invalidates the cookie.
formatClearSessionCookie :: String
formatClearSessionCookie =
  "session_id=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT"

-- | Resolve a session from the Cookie header value using the SessionStore.
-- | Left NotFound when the cookie is absent, invalid, or expired.
requireAuth :: SessionStore -> Maybe String -> Aff (Either AppError Session)
requireAuth store mCookie = do
  case mCookie >>= parseSessionCookie of
    Nothing -> pure (Left NotFound)
    Just (SessionId token) -> do
      sessions <- liftEffect $ Ref.read store
      pure case Map.lookup token sessions of
        Just session -> Right session
        Nothing -> Left NotFound

-- | Create a new session in the SessionStore for an authenticated user.
createSession :: SessionStore -> UserId -> String -> Aff (Either AppError SessionId)
createSession store uid token = do
  let sid = SessionId token
  let session = Session { userId: uid, sessionId: sid }
  liftEffect $ Ref.modify_ (Map.insert token session) store
  pure (Right sid)

-- | Destroy an active session in the SessionStore (logout).
destroySession :: SessionStore -> SessionId -> Aff (Either AppError Unit)
destroySession store (SessionId token) = do
  liftEffect $ Ref.modify_ (Map.delete token) store
  pure (Right unit)
