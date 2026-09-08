-- Migration: create_users_and_oauth
-- User accounts and linked OAuth identities for App.Auth/App.Users
-- (ADR-002). See docs/conventions/auth-lucia-arctic.md.
--
-- id: a random opaque string (App.Bun.randomLuciaId), matching
--   sessions.id/App.Auth.UserId -- not a sequential integer, so user
--   counts and identities aren't enumerable from IDs alone.
-- password_hash: nullable -- an OAuth-only account (no password ever
--   set) is valid. Argon2id via Bun.password, tuned to Lucia's own
--   stated minimum (auth.pilcrowonpaper.com/passwords): >=16 MiB
--   memory, 3 iterations (see App.Bun.hashPasswordImpl).
--
-- oauth_accounts is a separate table, not columns on users, so multiple
-- providers can link to one account without a schema change per
-- provider -- provider choice is not yet decided (see
-- .scratch/founding-premise/ ticket 09), and this table doesn't need to
-- know it. provider_user_id is the account id the provider issues
-- (e.g. a Google "sub" claim), never a secret.
--
-- posts.user_id (migration 001, INTEGER) is a pre-existing, unrelated
-- placeholder column with no FK anywhere -- deliberately not touched
-- or retrofitted here; out of scope for this migration.

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT,
  email_verified BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS oauth_accounts (
  provider TEXT NOT NULL,
  provider_user_id TEXT NOT NULL,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (provider, provider_user_id)
);

-- sessions.user_id (migration 002) predates this table; give it real
-- referential integrity now that users exists. Deleting a user cascades
-- to their sessions -- logging them out everywhere, which is correct.
-- Safe to add now: no database has ever run these migrations (none
-- available in this environment), so no existing session row can
-- violate it.
ALTER TABLE sessions
  ADD CONSTRAINT sessions_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
