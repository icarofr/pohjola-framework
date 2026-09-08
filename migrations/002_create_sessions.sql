-- Migration: create_sessions
-- Session storage for App.Auth (ADR-002, amended 2026-09-08 to adopt
-- Lucia's session pattern in full: id/secret token split, sliding
-- renewal). See docs/conventions/auth-lucia-arctic.md.
--
-- id: the public half of the token (16 random bytes, base64) -- safe to
--   log or show in a future admin revocation UI. Primary key: lookup is an
--   indexed equality check, not a full-table scan compared byte-by-byte,
--   which is why no app-level constant-time comparison is needed here
--   (see ADR-002's Amendment section).
-- secret_hash: SHA-256 hash (hex) of the token's secret half. The secret
--   itself is never stored.
-- user_id: opaque reference to whatever the application's user identifier
--   is -- this migration does not define a users table (out of ADR-002's
--   scope; see ticket 08 in .scratch/founding-premise/).
-- token_last_verified_at: bumped on use (at most once per hour) to drive
--   the sliding 10-day expiry window. A session is expired once
--   NOW() - token_last_verified_at exceeds 10 days.

CREATE TABLE IF NOT EXISTS sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  secret_hash TEXT NOT NULL,
  token_last_verified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
