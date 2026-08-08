-- | Authentication and session management — the ONLY module for auth flows.
-- |
-- | Contract: no inline session checks in App.Main or feature modules.
-- | All cookie → Session resolution goes through `requireAuth`.
-- |
-- | STATUS: STUB. Types and signatures are the contract. Implementation shape
-- | is decided in docs/adr/ADR-002.md (PS-first assembly: session store via
-- | yoga-postgres / bun:sqlite / Bun.sql, hashing via Bun.password or
-- | node:crypto scrypt, HMAC-signed cookies, uuidv4 + now). Stub bodies treat
-- | every request as unauthenticated.
module App.Auth
  ( UserId(..)
  , SessionId(..)
  , Session(..)
  , requireAuth
  , createSession
  , destroySession
  ) where

import Prelude

import App.Error (AppError(..))
import Data.Either (Either(..))
import Data.Maybe (Maybe)
import Effect.Aff (Aff)

newtype UserId = UserId String

newtype SessionId = SessionId String

data Session = Session
  { userId :: UserId
  , sessionId :: SessionId
  }

-- | Resolve a session from the Cookie header value.
-- | Left NotFound when the cookie is absent, invalid, or expired.
-- | (The router will map this to a 401/redirect per ADR-002.)
requireAuth :: Maybe String -> Aff (Either AppError Session)
requireAuth _ = pure (Left NotFound)

-- | Create a session for an authenticated user. Stub: always fails.
createSession :: UserId -> Aff (Either AppError SessionId)
createSession _ = pure (Left NotFound)

-- | Destroy a session (logout). Stub: always fails.
destroySession :: SessionId -> Aff (Either AppError Unit)
destroySession _ = pure (Left NotFound)
