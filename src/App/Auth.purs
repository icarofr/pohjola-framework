-- | Real session authentication (ADR-002, amended 2026-09-08 to adopt
-- | Lucia's session pattern in full: id/secret token split, sliding
-- | 10-day renewal, no compromises). Replaces the legacy
-- | App.Auth.Scaffold, now deleted.
-- |
-- | Full pattern reference, Bun-native mapping, and rationale:
-- | docs/conventions/auth-lucia-arctic.md
-- |
-- | Out of scope here (see ADR-002 and .scratch/founding-premise/ ticket
-- | 08): this module owns session lifecycle only. It does not define a
-- | users table, registration, or login-form handling — callers obtain a
-- | UserId however their application does (password check against a users
-- | table, OAuth via Arctic's pattern, etc.) and pass it to createSession.
-- |
-- | No in-memory fallback when DATABASE_URL is unset — ADR-002 explicitly
-- | rejects that (breaks silently in production). Auth fails closed
-- | instead.
module App.Auth
  ( UserId(..)
  , SessionId(..)
  , SessionToken
  , Session(..)
  , SessionCheck(..)
  , SessionRow
  , notConfigured
  , requireDb
  , liftSql
  , sessionCookieName
  , parseSessionCookie
  , formatSessionCookie
  , formatClearSessionCookie
  , splitToken
  , checkSession
  , createSession
  , requireAuth
  , destroySession
  ) where

import Prelude

import App.Bun (randomBase64, randomLuciaId, sha256Hex)
import App.Config (Config)
import App.Data.SQL as SQL
import App.Error (AppError(..))
import Control.Monad.Except (ExceptT, except, lift, runExceptT, throwError)
import Data.Array (findMap, head)
import Data.Either (Either, either, note)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.String (Pattern(..), stripPrefix)
import Data.String.Common (split, trim)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)

-- | Opaque reference to whatever the application's user identifier is.
-- | This module does not define what a user is (see module header).
newtype UserId = UserId String

derive instance newtypeUserId :: Newtype UserId _
derive newtype instance eqUserId :: Eq UserId
derive newtype instance ordUserId :: Ord UserId
derive newtype instance showUserId :: Show UserId

-- | The public half of a session token (Lucia's "id"). Safe to log or show
-- | in a future admin revocation UI — it is never enough by itself to
-- | authenticate (the secret half is required and never stored).
newtype SessionId = SessionId String

derive instance newtypeSessionId :: Newtype SessionId _
derive newtype instance eqSessionId :: Eq SessionId
derive newtype instance ordSessionId :: Ord SessionId
derive newtype instance showSessionId :: Show SessionId

-- | The full "id.secret" cookie value — the actual bearer credential.
-- | Constructor deliberately unexported: callers receive one only from
-- | `createSession` or `parseSessionCookie` and can only ever pass it back
-- | into `formatSessionCookie`/`splitToken`, never inspect or log it.
newtype SessionToken = SessionToken String

newtype Session = Session
  { userId :: UserId
  , sessionId :: SessionId
  }

derive instance newtypeSession :: Newtype Session _
derive newtype instance eqSession :: Eq Session
derive newtype instance showSession :: Show Session

-- | The pure decision a fetched session row reduces to — see `checkSession`.
data SessionCheck
  = SessionExpired
  | SessionSecretMismatch
  | SessionValid UserId

derive instance eqSessionCheck :: Eq SessionCheck

instance showSessionCheck :: Show SessionCheck where
  show = case _ of
    SessionExpired -> "SessionExpired"
    SessionSecretMismatch -> "SessionSecretMismatch"
    SessionValid (UserId uid) -> "SessionValid " <> uid

-- | Cookie name: `__Host-` prefixed cookies require Secure + Path=/ + no
-- | Domain attribute, so the name itself (not just the flags) must change
-- | between secure and insecure-dev contexts — a browser silently drops a
-- | `__Host-` cookie that doesn't meet those requirements. See
-- | `Config.secureCookies`'s doc comment for why this exists, and
-- | docs/conventions/auth-lucia-arctic.md's "Dev cookie name" note for why
-- | this isn't a deviation from the pattern doc (it documents this now).
sessionCookieName :: Boolean -> String
sessionCookieName secure = if secure then "__Host-ps_session" else "ps_session"

-- | Parse the session token from a `Cookie` request-header string.
parseSessionCookie :: Boolean -> String -> Maybe SessionToken
parseSessionCookie secure cookieHeader =
  let
    prefix = sessionCookieName secure <> "="
    pairs = map trim (split (Pattern ";") cookieHeader)
  in
    findMap (stripPrefix (Pattern prefix) >>> map SessionToken) pairs

-- | Format a Set-Cookie header value. Max-Age is fixed at 10 days from
-- | issuance and this function is never called again to refresh it — the
-- | cookie's own client-side lifetime is therefore NOT sliding, even
-- | though server-side validity is (see `checkSession`/`requireAuth`'s
-- | renewal). Known limitation, not a documented simplification (an
-- | earlier version of this comment claimed otherwise — it was wrong):
-- | see docs/conventions/auth-lucia-arctic.md's "Known limitation: cookie
-- | lifetime vs. server-side sliding validity" section for the honest
-- | account and the real fix (re-issue Set-Cookie on renewal), which
-- | needs a protected-route caller to exist before it can be wired in.
formatSessionCookie :: Boolean -> SessionToken -> String
formatSessionCookie secure (SessionToken token) =
  sessionCookieName secure <> "=" <> token
    <> "; Path=/; HttpOnly; SameSite=Lax; Max-Age=864000"
    <> (if secure then "; Secure" else "")

-- | Format a Set-Cookie header value that immediately invalidates the
-- | session cookie (logout).
formatClearSessionCookie :: Boolean -> String
formatClearSessionCookie secure =
  sessionCookieName secure
    <> "=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT"
    <> (if secure then "; Secure" else "")

-- | Split a token into its id/secret halves. Malformed tokens (zero or
-- | more than one ".") are rejected — a well-formed token from
-- | `createSession` always splits into exactly two parts, since neither
-- | half's alphabet contains ".".
splitToken :: SessionToken -> Maybe { id :: String, secret :: String }
splitToken (SessionToken token) = case split (Pattern ".") token of
  [ id, secret ] -> Just { id, secret }
  _ -> Nothing

-- | The fields `checkSession` needs from a fetched session row, bundled
-- | as one type since they always travel together (one row, one
-- | decision) — not three positional args that could be passed in the
-- | wrong order at a call site.
type SessionRow =
  { expired :: Boolean
  , storedHash :: Maybe String
  , userId :: Maybe String
  }

-- | Pure decision from a fetched session row — directly testable without
-- | a live DB (mirrors `postFromRows`'s "decode-only decision" pattern in
-- | App.Features.Posts.Service). `computedHash` is the SHA-256 of the
-- | secret half the caller presented.
checkSession :: SessionRow -> String -> SessionCheck
checkSession row computedHash =
  case row.expired, row.storedHash, row.userId of
    true, _, _ ->
      SessionExpired
    _, Just hash, Just uid | hash == computedHash ->
      SessionValid (UserId uid)
    _, _, _ ->
      SessionSecretMismatch

-- | Error returned by every App.Auth/App.Users function when
-- | DATABASE_URL is unset. No in-memory fallback (ADR-002 explicitly
-- | rejects one — it breaks silently in production). Exported so
-- | App.Users (which needs the identical guard) reuses this value
-- | instead of defining its own copy.
notConfigured :: AppError
notConfigured = FfiError
  "Auth requires DATABASE_URL to be configured (ADR-002); there is no in-memory fallback."

-- | Extract `databaseUrl` from Config inside an ExceptT block, or fail
-- | closed with `notConfigured`. The one line every DB-requiring
-- | App.Auth/App.Users function starts with — exported so App.Users
-- | shares it instead of re-deriving the same guard per function.
requireDb :: forall m. Applicative m => Config -> ExceptT AppError m String
requireDb cfg = except (note notConfigured cfg.databaseUrl)

-- | Lift an `App.Data.SQL` result into `ExceptT AppError`, mapping any
-- | `SQLError` to `FfiError`. Matches this repo's own `ExceptT`/`liftSql`
-- | idiom (see `App.Migration.liftSql`) instead of a `case ... of Left ->
-- | pure (Left ...); Right -> ...` staircase.
liftSql :: forall a. Aff (Either SQL.SQLError a) -> ExceptT AppError Aff a
liftSql m = lift m >>= either (throwError <<< FfiError <<< show) pure

-- | Create a new session for an authenticated user. The caller is
-- | responsible for authenticating the user by whatever means (password
-- | check, OAuth) before calling this — see the module header.
createSession :: Config -> UserId -> Aff (Either AppError SessionToken)
createSession cfg (UserId uid) = runExceptT do
  dbUrl <- requireDb cfg
  sql <- lift $ liftEffect $ SQL.connect dbUrl
  sid <- lift $ liftEffect $ randomLuciaId 16
  secret <- lift $ liftEffect $ randomBase64 32
  secretHash <- lift $ liftEffect $ sha256Hex secret
  _ <- liftSql $ SQL.execute sql
    "INSERT INTO sessions (id, user_id, secret_hash) VALUES ($1, $2, $3)"
    [ SQL.SqlString sid, SQL.SqlString uid, SQL.SqlString secretHash ]
  pure (SessionToken (sid <> "." <> secret))

-- | Resolve a session from a `Cookie` request-header value. Left
-- | Unauthorized covers "no cookie", "malformed token", "no such session",
-- | "wrong secret", and "expired" uniformly — the caller cannot
-- | distinguish which, by design (avoids leaking which part of a forged
-- | token was wrong). Per ADR-002's Consequences section, authentication
-- | failures map to 401 (Unauthorized); NotFound (404) is reserved for
-- | missing resources — a distinct concern this function never returns.
requireAuth :: Config -> Maybe String -> Aff (Either AppError Session)
requireAuth cfg mCookieHeader = runExceptT do
  dbUrl <- requireDb cfg
  parts <- except (note Unauthorized (mCookieHeader >>= parseSessionCookie cfg.secureCookies >>= splitToken))
  sql <- lift $ liftEffect $ SQL.connect dbUrl
  computedHash <- lift $ liftEffect $ sha256Hex parts.secret
  rows <- liftSql $ SQL.query sql
    """SELECT user_id, secret_hash,
         (NOW() - token_last_verified_at > INTERVAL '10 days') AS expired
       FROM sessions WHERE id = $1"""
    [ SQL.SqlString parts.id ]
  row <- except (note Unauthorized (head rows))
  let
    sessionRow :: SessionRow
    sessionRow =
      { expired: SQL.readBoolField row "expired" == Just true
      , storedHash: SQL.readStringField row "secret_hash"
      , userId: SQL.readStringField row "user_id"
      }
  case checkSession sessionRow computedHash of
    SessionExpired -> do
      _ <- liftSql $ SQL.execute sql "DELETE FROM sessions WHERE id = $1" [ SQL.SqlString parts.id ]
      throwError Unauthorized
    SessionSecretMismatch ->
      throwError Unauthorized
    SessionValid uid -> do
      _ <- liftSql $ SQL.execute sql
        """UPDATE sessions SET token_last_verified_at = NOW()
           WHERE id = $1 AND NOW() - token_last_verified_at >= INTERVAL '1 hour'"""
        [ SQL.SqlString parts.id ]
      pure (Session { userId: uid, sessionId: SessionId parts.id })

-- | Destroy an active session (logout). Takes just the id half — by the
-- | time a caller wants to log out, `requireAuth` has already resolved a
-- | `Session` carrying its `SessionId`, so the secret is never needed here.
destroySession :: Config -> SessionId -> Aff (Either AppError Unit)
destroySession cfg (SessionId sid) = runExceptT do
  dbUrl <- requireDb cfg
  sql <- lift $ liftEffect $ SQL.connect dbUrl
  liftSql $ SQL.execute sql "DELETE FROM sessions WHERE id = $1" [ SQL.SqlString sid ]
