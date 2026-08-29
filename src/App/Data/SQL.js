// App.Data.SQL.js
// Bun.SQL bindings — the tamed database boundary (ADR-009).
// Plumbing only, no app logic. All SQL logic lives in PureScript.
//
// Safety: parameterized queries use sql.unsafe(sql, params) — Bun binds
// params separately via the extended wire protocol (injection-safe).
// execMulti uses sql.unsafe(sql) with NO params — trusted SQL only.
//
// PS FFI calls are curried. Callback pattern (like fetchImpl):
//   onSuccess(result) returns a thunk; onSuccess(result)() executes it.
//   onError(message) likewise. PS wraps via makeAff.

// connectImpl :: String -> Effect SQL
// Bun.SQL auto-pools, lazy-connects (no I/O until first query).
export function connectImpl(connectionString) {
  return function () {
    return new Bun.SQL(connectionString);
  };
}

// closeImpl :: SQL -> (Effect Unit -> Effect Unit) -> Effect Unit
// Awaits in-flight queries, then closes all pooled connections.
export function closeImpl(sql) {
  return function (onComplete) {
      return function () {
        sql.close().then(function () { onComplete()(); });
      };
  };
}

// reserveImpl :: SQL -> (SQL -> Effect Unit) -> (String -> Effect Unit) -> Effect Unit
// Takes one pooled connection via Bun.SQL.reserve(). The returned handle
// supports the same unsafe() API as the pool and must be released.
export function reserveImpl(sql) {
  return function (onSuccess) {
    return function (onError) {
      return function () {
        sql.reserve()
          .then(function (reserved) { onSuccess(reserved)(); })
          .catch(function (err) { onError(err.message || String(err))(); });
      };
    };
  };
}

// releaseImpl :: SQL -> Effect Unit
// Returns a reserved connection to the pool. No-op if already released.
export function releaseImpl(reserved) {
  return function () {
    reserved.release();
  };
}

// queryImpl :: SQL -> String -> Array Foreign
//          -> (Array Row -> Effect Unit) -> (String -> Effect Unit)
//          -> Effect Unit
// Parameterized query via sql.unsafe(sql, params). Injection-safe.
export function queryImpl(sql) {
  return function (stmt) {
    return function (params) {
      return function (onSuccess) {
        return function (onError) {
          return function () {
            sql.unsafe(stmt, params)
              .then(function (rows) { onSuccess(rows)(); })
              .catch(function (err) { onError(err.message || String(err))(); });
          };
        };
      };
    };
  };
}

// executeImpl :: SQL -> String -> Array Foreign
//           -> (Effect Unit -> Effect Unit) -> (String -> Effect Unit)
//           -> Effect Unit
// Same as queryImpl but discards rows. For INSERT/UPDATE/DELETE and
// transaction control (BEGIN/COMMIT/ROLLBACK).
export function executeImpl(sql) {
  return function (stmt) {
    return function (params) {
      return function (onSuccess) {
        return function (onError) {
          return function () {
            sql.unsafe(stmt, params)
              .then(function () { onSuccess()(); })
              .catch(function (err) { onError(err.message || String(err))(); });
          };
        };
      };
    };
  };
}

// execMultiImpl :: SQL -> String
//             -> (Effect Unit -> Effect Unit) -> (String -> Effect Unit)
//             -> Effect Unit
// Multi-statement execution via sql.unsafe(sql) — NO params.
// Trusted SQL only (migration files). Never user input. See ADR-009.
export function execMultiImpl(sql) {
  return function (stmt) {
    return function (onSuccess) {
      return function (onError) {
        return function () {
          sql.unsafe(stmt)
            .then(function () { onSuccess()(); })
            .catch(function (err) { onError(err.message || String(err))(); });
        };
      };
    };
  };
}

// readStringFieldImpl :: Row -> String -> Nullable String
// Read a string field from a query row (plain JS object). Null if
// missing or not a string. Plumbing for decoding query results.
export function readStringFieldImpl(row) {
  return function (field) {
    var v = row[field];
    return typeof v === "string" ? v : null;
  };
}

// readIntFieldImpl :: Row -> String -> Nullable Int
export function readIntFieldImpl(row) {
  return function (field) {
    var v = row[field];
    return typeof v === "number" && Number.isInteger(v) ? v : null;
  };
}
