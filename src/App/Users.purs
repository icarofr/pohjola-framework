-- | User accounts: password registration/login and OAuth account linking.
-- | Separate from App.Auth on purpose — App.Auth owns session lifecycle
-- | only (its own module header says so explicitly); this module owns
-- | who a user *is*, App.Auth owns proving *this request* is them.
-- |
-- | Password side follows Lucia's own stated guidance
-- | (auth.pilcrowonpaper.com/passwords) via App.Bun.hashPassword/
-- | verifyPassword (Argon2id, >=16 MiB memory, 3 iterations). OAuth side
-- | follows Arctic's pattern (docs/conventions/auth-lucia-arctic.md):
-- | this module resolves a UserId from a provider identity; the OAuth
-- | token-exchange flow itself (Arctic's reference code) is not built
-- | here — see .scratch/founding-premise/ ticket 09.
-- |
-- | No HTTP routes/forms here — no registration or login page exists yet.
-- | A future login handler calling `verifyUserPassword` should
-- | rate-limit attempts via the existing `App.RateLimit` (Lucia's own
-- | guidance: ~1 attempt/minute/user via a token-bucket-shaped limiter,
-- | not IP-based, not exponential lockout — `App.RateLimit.shouldAllow`
-- | already implements the equivalent fixed-window shape).
-- |
-- | No in-memory fallback when DATABASE_URL is unset, matching App.Auth
-- | (shares its `notConfigured`/`requireDb`/`liftSql` rather than
-- | redefining them).
module App.Users
  ( LoginCandidate
  , decodeLoginCandidate
  , createUser
  , findUserByEmail
  , verifyUserPassword
  , linkOAuthAccount
  , findUserByOAuthAccount
  ) where

import Prelude

import App.Auth (UserId(..), liftSql, requireDb)
import App.Bun (hashPassword, randomLuciaId, verifyPassword)
import App.Config (Config)
import App.Data.SQL as SQL
import App.Error (AppError(..))
import Control.Monad.Except (except, lift, runExceptT)
import Data.Array (head)
import Data.Bifunctor (lmap)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Effect.Aff (Aff)
import Effect.Class (liftEffect)

-- | A user resolved from `users` with a password set — the shape a login
-- | check needs. Distinct from a bare `UserId` because an OAuth-only
-- | account (no `password_hash`) is not a valid password-login target.
type LoginCandidate = { userId :: UserId, passwordHash :: String }

-- | Decode a `users` row's id/password_hash fields into a login
-- | candidate. Pure, directly testable without a DB — mirrors
-- | App.Features.Posts.Service's row-decode pattern. Nothing when the
-- | row has no password set (OAuth-only account) or, defensively, if
-- | `id` is somehow absent from a row that was returned at all.
decodeLoginCandidate :: Maybe String -> Maybe String -> Maybe LoginCandidate
decodeLoginCandidate mUid mHash = case mUid, mHash of
  Just uid, Just hash -> Just { userId: UserId uid, passwordHash: hash }
  _, _ -> Nothing

-- | Register a new user with a password (Lucia's password-auth pattern).
-- | Hashes via Argon2id before it ever reaches SQL (App.Bun.hashPassword).
-- | A duplicate email surfaces as `FfiError` carrying Postgres's unique-
-- | constraint violation text — relying on the DB's own constraint
-- | rather than a check-then-insert, which would have a race condition
-- | the constraint doesn't.
createUser :: Config -> String -> String -> Aff (Either AppError UserId)
createUser cfg email password = runExceptT do
  dbUrl <- requireDb cfg
  hashResult <- lift $ hashPassword password
  hash <- except (lmap FfiError hashResult)
  sql <- lift $ liftEffect $ SQL.connect dbUrl
  uid <- lift $ liftEffect $ randomLuciaId 16
  _ <- liftSql $ SQL.execute sql
    "INSERT INTO users (id, email, password_hash) VALUES ($1, $2, $3)"
    [ SQL.SqlString uid, SQL.SqlString email, SQL.SqlString hash ]
  pure (UserId uid)

-- | Look up a login candidate by email. `Right Nothing` covers both "no
-- | such user" and "user exists but has no password set" uniformly —
-- | neither is a valid password-login target, and a caller building a
-- | login handler should not distinguish them in its response (same
-- | principle as App.Auth.requireAuth's uniform Unauthorized).
findUserByEmail :: Config -> String -> Aff (Either AppError (Maybe LoginCandidate))
findUserByEmail cfg email = runExceptT do
  dbUrl <- requireDb cfg
  sql <- lift $ liftEffect $ SQL.connect dbUrl
  rows <- liftSql $ SQL.query sql
    "SELECT id, password_hash FROM users WHERE email = $1"
    [ SQL.SqlString email ]
  pure case head rows of
    Nothing -> Nothing
    Just row -> decodeLoginCandidate (SQL.readStringField row "id") (SQL.readStringField row "password_hash")

-- | Verify a login attempt end to end: look up by email, then check the
-- | password against the stored hash (Bun.password.verify — constant-
-- | time by construction, per Lucia's own guidance on this point).
-- | `Right Nothing` covers "no such user", "no password set", and
-- | "wrong password" uniformly — callers must not distinguish which in
-- | their response. Rate-limit calls to this — see module header.
verifyUserPassword :: Config -> String -> String -> Aff (Either AppError (Maybe UserId))
verifyUserPassword cfg email password = do
  found <- findUserByEmail cfg email
  case found of
    Left err -> pure (Left err)
    Right Nothing -> pure (Right Nothing)
    Right (Just candidate) -> do
      verifyResult <- verifyPassword password candidate.passwordHash
      pure case verifyResult of
        Left err -> Left (FfiError err)
        Right true -> Right (Just candidate.userId)
        Right false -> Right Nothing

-- | Link an OAuth provider identity to a user account (Arctic's
-- | callback seam — see docs/conventions/auth-lucia-arctic.md). Pass a
-- | freshly-created user's id for a first-time OAuth signup, or an
-- | existing user's id to link an additional provider. Idempotent:
-- | re-linking the same provider+provider_user_id is a no-op.
linkOAuthAccount :: Config -> String -> String -> UserId -> Aff (Either AppError Unit)
linkOAuthAccount cfg provider providerUserId (UserId uid) = runExceptT do
  dbUrl <- requireDb cfg
  sql <- lift $ liftEffect $ SQL.connect dbUrl
  liftSql $ SQL.execute sql
    """INSERT INTO oauth_accounts (provider, provider_user_id, user_id)
       VALUES ($1, $2, $3)
       ON CONFLICT (provider, provider_user_id) DO NOTHING"""
    [ SQL.SqlString provider, SQL.SqlString providerUserId, SQL.SqlString uid ]

-- | Resolve a user id from a previously-linked OAuth identity. Nothing
-- | if this provider+provider_user_id combination has never been
-- | linked — the caller (an OAuth callback handler) decides whether to
-- | create a new user via `createUser`-adjacent logic or reject.
findUserByOAuthAccount :: Config -> String -> String -> Aff (Either AppError (Maybe UserId))
findUserByOAuthAccount cfg provider providerUserId = runExceptT do
  dbUrl <- requireDb cfg
  sql <- lift $ liftEffect $ SQL.connect dbUrl
  rows <- liftSql $ SQL.query sql
    "SELECT user_id FROM oauth_accounts WHERE provider = $1 AND provider_user_id = $2"
    [ SQL.SqlString provider, SQL.SqlString providerUserId ]
  pure case head rows >>= \row -> SQL.readStringField row "user_id" of
    Nothing -> Nothing
    Just uid -> Just (UserId uid)
