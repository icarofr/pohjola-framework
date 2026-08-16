-- | Migration runner — idiomatic Haskell/PS approach to schema migrations.
-- |
-- | Numbered `.sql` files in `migrations/` (e.g. `001_create_users.sql`).
-- | A `schema_migrations` table tracks applied migrations with SHA-256
-- | checksums. No down-migrations (YAGNI — see ADR-009).
-- |
-- | All logic lives here in PureScript. The FFI modules (App.Data.SQL,
-- | App.Bun) are plumbing only. Transactions are managed explicitly via
-- | BEGIN/COMMIT/ROLLBACK so the JS side stays pure plumbing.
-- |
-- | Safety: migration SQL is trusted (checked into the repo), so it runs
-- | via `execMulti` (multi-statement, no params). Application queries
-- | use parameterized `query`/`execute` — injection-safe. See ADR-009.
module App.Migration
  ( Migration(..)
  , MigrationError(..)
  , AppliedMigration
  , loadMigrations
  , getAppliedMigrations
  , runMigrations
  , migrate
  , renderMigrationError
  ) where

import Prelude

import App.Bun (glob, readTextFile, sha256Hex)
import App.Data.SQL (SQL, SQLError, close, connect, execMulti, execute, query, readStringField, SqlValue(..))
import Data.Array (filter, find, length, mapMaybe, null, sortWith, uncons)
import Data.Either (Either(..), either)
import Data.Foldable (elem, traverse_)
import Data.Int (fromString) as Int
import Data.Maybe (Maybe(..))
import Data.String.Common (split)
import Data.String.Pattern (Pattern(..))
import Data.Traversable (for, sequence)
import Effect.Aff (Aff, bracket)
import Effect.Class (liftEffect)
import Control.Monad.Except (ExceptT, runExceptT, throwError, catchError)
import Control.Monad.Trans.Class (lift)

-- ============================================================================
-- Types
-- ============================================================================

-- | A migration discovered on disk: filename + SQL content + checksum.
type Migration =
  { filename :: String
  , content :: String
  , checksum :: String
  }

-- | An applied migration recorded in `schema_migrations`.
type AppliedMigration =
  { filename :: String
  , checksum :: String
  }

-- | Migration runner errors — values, not exceptions (App.Error pattern).
data MigrationError
  = MigrationReadError String
  | MigrationQueryError String
  | MigrationChecksumMismatch String
  | MigrationExecutionError String

instance showMigrationError :: Show MigrationError where
  show = case _ of
    MigrationReadError f -> "MigrationReadError: " <> f
    MigrationQueryError msg -> "MigrationQueryError: " <> msg
    MigrationChecksumMismatch f -> "ChecksumMismatch: " <> f
    MigrationExecutionError msg -> "ExecutionError: " <> msg

-- | Human-readable error for CLI output.
renderMigrationError :: MigrationError -> String
renderMigrationError = case _ of
  MigrationReadError f -> "Failed to read migration: " <> f
    <> " (file missing or unreadable)"
  MigrationQueryError msg -> "Database error: " <> msg
  MigrationChecksumMismatch f -> "Checksum mismatch for " <> f
    <> " (file changed since last run?)"
  MigrationExecutionError msg -> "Migration failed: " <> msg

-- ============================================================================
-- Migration discovery
-- ============================================================================

-- | Extract the numeric prefix from a migration filename.
-- | `001_create_users.sql` → 1. Non-numeric prefixes sort last (0).
migrationOrder :: String -> Int
migrationOrder filename =
  case uncons (split (Pattern "_") filename) of
    Nothing -> 0
    Just { head: prefix } -> case Int.fromString prefix of
      Just n -> n
      Nothing -> 0

-- | Load all migrations from `migrations/*.sql`, sorted by numeric prefix.
-- | Each migration gets a SHA-256 checksum of its content.
-- | Returns Left if any file can't be read.
loadMigrations :: Aff (Either MigrationError (Array Migration))
loadMigrations = do
  files <- liftEffect $ glob "migrations/*.sql"
  if null files then
    pure (Right [])
  else do
    let sorted = sortWith migrationOrder files
    results <- for sorted \filename -> do
      content <- readTextFile filename
      case content of
        Left err -> pure (Left (MigrationReadError (filename <> ": " <> err)))
        Right c -> do
          checksum <- liftEffect $ sha256Hex c
          pure (Right { filename, content: c, checksum })
    pure (sequence results)

-- | Collect an array of Eithers into an Either of an array (short-circuit
-- | on first error). Standard pattern — keeps the runner linear.

-- ============================================================================
-- Applied migrations
-- ============================================================================

-- | SQL to create the `schema_migrations` table if it doesn't exist.
-- | Idempotent — safe to run on every migration invocation.
createSchemaMigrationsSql :: String
createSchemaMigrationsSql =
  """CREATE TABLE IF NOT EXISTS schema_migrations (
    filename TEXT PRIMARY KEY,
    checksum TEXT NOT NULL,
    applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  );"""

-- | Query applied migrations from the database, ordered by filename.
-- | Ensures the tracking table exists first (idempotent).
getAppliedMigrations :: SQL -> Aff (Either MigrationError (Array AppliedMigration))
getAppliedMigrations sql = do
  createResult <- execMulti sql createSchemaMigrationsSql
  case createResult of
    Left err -> pure (Left (MigrationQueryError (show err)))
    Right _ -> do
      queryResult <- query sql "SELECT filename, checksum FROM schema_migrations ORDER BY filename" []
      case queryResult of
        Left err -> pure (Left (MigrationQueryError (show err)))
        Right rows -> pure (Right (mapMaybe rowToApplied rows))
  where
  rowToApplied row = do
    filename <- readStringField row "filename"
    checksum <- readStringField row "checksum"
    pure { filename, checksum }

-- ============================================================================
-- Migration execution
-- ============================================================================

-- | Run a single migration in a transaction. On any error, ROLLBACK.
-- | Records the migration in `schema_migrations` on success.
runSingleMigration :: SQL -> Migration -> ExceptT MigrationError Aff Unit
runSingleMigration sql migration =
  withTx sql do
    -- Run the migration SQL (multi-statement, trusted — no params).
    liftSql (execMulti sql migration.content)
    -- Record in schema_migrations (parameterized — injection-safe).
    let stmt = "INSERT INTO schema_migrations (filename, checksum) VALUES ($1, $2)"
    liftSql (execute sql stmt [ SqlString migration.filename, SqlString migration.checksum ])

-- | Run an action in a transaction. ROLLBACK on error, COMMIT on success.
withTx :: forall a. SQL -> ExceptT MigrationError Aff a -> ExceptT MigrationError Aff a
withTx sql body = do
  _ <- liftSql (execute sql "BEGIN" [])
  res <- catchError body \err -> do
    _ <- liftSql (execute sql "ROLLBACK" [])
    throwError err
  _ <- liftSql (execute sql "COMMIT" [])
  pure res

-- | Helper to lift SQL operations into the Migration runner's ExceptT.
liftSql :: forall a. Aff (Either SQLError a) -> ExceptT MigrationError Aff a
liftSql m = lift m >>= either (throwError <<< MigrationExecutionError <<< show) pure

-- | Helper to lift migration-specific Eithers into the runner's ExceptT.
liftEither :: forall a. Aff (Either MigrationError a) -> ExceptT MigrationError Aff a
liftEither m = lift m >>= either throwError pure

-- | Run all pending migrations. Checks checksums of already-applied
-- | migrations (fails on mismatch — detects tampering). Runs pending
-- | migrations in order, each in its own transaction.
runMigrations :: SQL -> Array Migration -> Array AppliedMigration -> ExceptT MigrationError Aff Int
runMigrations sql migrations applied = do
  -- Verify checksums of already-applied migrations.
  case verifyChecksums migrations applied of
    Left err -> throwError err
    Right _ -> pure unit
  -- Run pending migrations.
  let
    appliedNames = map (_.filename) applied
    pending = filter (\m -> not (m.filename `elem` appliedNames)) migrations
  traverse_ (runSingleMigration sql) pending
  pure (length pending)

-- | Verify that applied migrations haven't been modified since last run.
-- | Fails on checksum mismatch — detects tampering or accidental edits.
-- | Missing files are skipped (no down-migrations — see ADR-009).
verifyChecksums :: Array Migration -> Array AppliedMigration -> Either MigrationError Unit
verifyChecksums migrations applied = traverse_ checkOne applied
  where
  checkOne a = case find (\m -> m.filename == a.filename) migrations of
    Nothing -> Right unit -- file removed; skip
    Just m ->
      if m.checksum == a.checksum then Right unit
      else Left (MigrationChecksumMismatch a.filename)

-- ============================================================================
-- Top-level entry point
-- ============================================================================

-- | Full migration flow: load from disk, connect, ensure tracking table,
-- | verify checksums, run pending migrations. Closes the connection.
-- | Returns the number of pending migrations that were applied
-- | (0 = already up to date).
migrate :: String -> Aff (Either MigrationError Int)
migrate connectionString = runExceptT do
  migrations <- liftEither loadMigrations
  liftEither $ bracket
    (liftEffect $ connect connectionString)
    close
    \db -> runExceptT do
      applied <- liftEither (getAppliedMigrations db)
      runMigrations db migrations applied
