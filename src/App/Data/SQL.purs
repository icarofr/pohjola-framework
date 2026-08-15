-- | FFI bindings to Bun.SQL — the tamed database boundary (ADR-009).
-- |
-- | This module owns the `foreign import` declarations. The JS side
-- | (App.Data.SQL.js) is plumbing only — no app logic. All SQL logic
-- | lives in PureScript (App.Migration, feature Service modules).
-- |
-- | Safety: parameterized queries use `sql.unsafe(sql, params)` — Bun
-- | binds parameters separately via the extended wire protocol, so
-- | user input cannot reach the SQL parser. Multi-statement execution
-- | (`execMulti`) accepts no parameters and is reserved for trusted
-- | migration SQL only. See ADR-009.
-- |
-- | Transactions: managed explicitly via `execute` with BEGIN/COMMIT/
-- | ROLLBACK statements — keeps all transaction logic in PureScript,
-- | the JS side stays pure plumbing. See App.Migration.
module App.Data.SQL where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable, null, toMaybe)
import Effect (Effect)
import Effect.Aff (Aff, makeAff)
import Foreign (Foreign, unsafeToForeign)

-- | Opaque SQL client — wraps Bun.SQL (auto-pooling, lazy connect).
-- | Created by `connect`, closed by `close`. Passed to query/execute.
foreign import data SQL :: Type

-- | Row from a query — opaque Foreign; callers decode via Argonaut or
-- | field accessors. Kept as Foreign to avoid a schema-coupled FFI.
-- | Named `DbRow` to avoid shadowing the built-in `Prim.Row` kind.
type DbRow = Foreign

-- | SQL errors — structured, not stringly-typed.
data SQLError
  = ConnectionError String
  | QueryError String
  | ExecuteError String

derive instance eqSQLError :: Eq SQLError
derive instance ordSQLError :: Ord SQLError

instance showSQLError :: Show SQLError where
  show = case _ of
    ConnectionError msg -> "ConnectionError: " <> msg
    QueryError msg -> "QueryError: " <> msg
    ExecuteError msg -> "ExecuteError: " <> msg

-- | Typed SQL parameter values. The PS-side boundary for query parameters.
-- | Prevents accidental passing of records, functions, or other non-SQL values.
-- | The JS side converts these to the appropriate wire-protocol types.
data SqlValue
  = SqlString String
  | SqlInt Int
  | SqlNumber Number
  | SqlBool Boolean
  | SqlNull

derive instance eqSqlValue :: Eq SqlValue
derive instance ordSqlValue :: Ord SqlValue

-- | Type class for values that can be converted to SQL parameters.
-- | Idiomatic PS pattern (matches purescript-postgresql, purescript-pg, etc.).
class ToSQLValue a where
  toSQLValue :: a -> SqlValue

instance ToSQLValue String where
  toSQLValue = SqlString

instance ToSQLValue Int where
  toSQLValue = SqlInt

instance ToSQLValue Number where
  toSQLValue = SqlNumber

instance ToSQLValue Boolean where
  toSQLValue = SqlBool

instance ToSQLValue a => ToSQLValue (Maybe a) where
  toSQLValue Nothing = SqlNull
  toSQLValue (Just a) = toSQLValue a

-- | Convert SqlValue to Foreign for the FFI. Single unsafe chokepoint.
toForeignValue :: SqlValue -> Foreign
toForeignValue = case _ of
  SqlString s -> unsafeToForeign s
  SqlInt n -> unsafeToForeign n
  SqlNumber n -> unsafeToForeign n
  SqlBool b -> unsafeToForeign b
  SqlNull -> unsafeToForeign null

-- | Create a Bun.SQL client. Connection is lazy — no network I/O
-- | happens until the first query. Auto-pools connections.
-- | connectionString: postgres://user:pass@host:port/db
foreign import connectImpl :: String -> Effect SQL

-- | Close all pooled connections. Awaits in-flight queries.
-- | Callback pattern (like fetchImpl) so PS wraps via makeAff.
foreign import closeImpl :: SQL -> (Effect Unit -> Effect Unit) -> Effect Unit

-- | Parameterized query — `sql.unsafe(sql, params)`.
-- | Bun binds params separately (extended protocol): injection-safe.
-- | Returns rows as an Array of Foreign objects.
-- | Callback pattern: onSuccess(rows), onError(message).
foreign import queryImpl
  :: SQL
  -> String
  -> Array Foreign
  -> (Array DbRow -> Effect Unit)
  -> (String -> Effect Unit)
  -> Effect Unit

-- | Parameterized execute — same as query but discards rows.
-- | For INSERT/UPDATE/DELETE and transaction control (BEGIN/COMMIT/
-- | ROLLBACK). Callback pattern: onSuccess(unit), onError(message).
foreign import executeImpl
  :: SQL
  -> String
  -> Array Foreign
  -> (Effect Unit -> Effect Unit)
  -> (String -> Effect Unit)
  -> Effect Unit

-- | Multi-statement execution — `sql.unsafe(sql)` with no params.
-- | Allows multiple statements in one call (for migration SQL).
-- | NO parameters: trusted SQL only, never user input. See ADR-009.
-- | Callback pattern: onSuccess(unit), onError(message).
foreign import execMultiImpl
  :: SQL
  -> String
  -> (Effect Unit -> Effect Unit)
  -> (String -> Effect Unit)
  -> Effect Unit

-- | Read a string field from a query row. Returns null if the field is
-- | missing or not a string. Plumbing for decoding query results.
foreign import readStringFieldImpl :: DbRow -> String -> Nullable String

-- | Read an integer field from a query row. Returns null if the field is
-- | missing or not an integer. Plumbing for decoding query results.
foreign import readIntFieldImpl :: DbRow -> String -> Nullable Int

-- | Create a Bun.SQL client. Lazy connect — no I/O until first query.
connect :: String -> Effect SQL
connect = connectImpl

-- | Close all pooled connections. Awaits in-flight queries.
close :: SQL -> Aff Unit
close sql = makeAff \callback -> do
  closeImpl sql (\_ -> callback (pure unit))
  pure mempty

-- | Parameterized query — injection-safe (Bun extended protocol).
-- | Returns rows as Foreign objects for caller-side decoding.
query :: SQL -> String -> Array SqlValue -> Aff (Either SQLError (Array DbRow))
query sql stmt params = makeAff \callback -> do
  queryImpl sql stmt (map toForeignValue params)
    (\rows -> callback (pure (Right rows)))
    (\msg -> callback (pure (Left (QueryError msg))))
  pure mempty

-- | Parameterized execute — discards rows. For INSERT/UPDATE/DELETE
-- | and transaction control (BEGIN/COMMIT/ROLLBACK).
execute :: SQL -> String -> Array SqlValue -> Aff (Either SQLError Unit)
execute sql stmt params = makeAff \callback -> do
  executeImpl sql stmt (map toForeignValue params)
    (\_ -> callback (pure (Right unit)))
    (\msg -> callback (pure (Left (ExecuteError msg))))
  pure mempty

-- | Multi-statement execution — trusted SQL only, no parameters.
-- | Used by the migration runner for .sql file contents. See ADR-009.
execMulti :: SQL -> String -> Aff (Either SQLError Unit)
execMulti sql stmt = makeAff \callback -> do
  execMultiImpl sql stmt
    (\_ -> callback (pure (Right unit)))
    (\msg -> callback (pure (Left (ExecuteError msg))))
  pure mempty

-- | Read a string field from a query row. Nothing if missing/non-string.
-- | Used to decode `schema_migrations` rows in App.Migration.
readStringField :: DbRow -> String -> Maybe String
readStringField = map toMaybe <<< readStringFieldImpl

-- | Read an integer field from a query row. Nothing if missing/non-integer.
readIntField :: DbRow -> String -> Maybe Int
readIntField = map toMaybe <<< readIntFieldImpl
