# ADR-009: Bun.sql data layer with hand-rolled migrations

## Status

Accepted (Phase 3A: reserved-connection migration affinity implemented)

## Context

The starter needs a PostgreSQL data layer for data-backed features. The
existing data layer (`App.Data.Fetch`) only handles HTTP fetching via
Bun's native fetch. Adding database support requires three decisions:

1. **Driver**: Bun ships a native `Bun.SQL` client (PostgreSQL, MySQL,
   SQLite) with connection pooling, parameterized queries, and tagged
   template literal injection safety. No npm dependency needed.

2. **Migrations**: No PureScript migration library exists. Options were
   (a) shell out to an external tool (`golang-migrate`, `dbmate`), (b)
   use `node-pg-migrate` via FFI, or (c) hand-roll a small runner in PS.
   The project's philosophy is "idiomatic Haskell/PS, minimal JS
   plumbing" — option (c) fits. The Haskell ecosystem uses plain SQL
   files + a small runner (e.g. `postgresql-simple-migration`); we
   follow that pattern.

3. **FFI boundary**: Per ADR-003, FFI is restricted to allowlisted
   modules. `App.Data.SQL` joins the allowlist (4 modules now). The JS
   side is plumbing only — all SQL logic (transactions, checksums,
   ordering) lives in PureScript.

## Decision

### Driver: `Bun.SQL` via `App.Data.SQL`

- `App.Data.SQL` wraps `Bun.SQL` with typed FFI: `connect`, `close`,
  `reserve`, `release`, `query`, `execute`, `execMulti`.
- **Injection safety**: `query`/`execute` use `sql.unsafe(sql, params)`
  — Bun binds parameters separately via the PostgreSQL extended wire
  protocol. User input never reaches the SQL parser.
- **Multi-statement**: `execMulti` uses `sql.unsafe(sql)` with NO
  parameters. Reserved for trusted migration SQL only. The PS type
  signature (`String -> Aff (Either String Unit)`) makes the "no
  params" constraint visible at the call site.
- **Transactions**: managed explicitly via `execute` with `BEGIN`/
  `COMMIT`/`ROLLBACK`. Keeps all transaction logic in PureScript — the
  JS side stays pure plumbing (no `sql.begin` callback bridge needed).
  If `COMMIT` fails, the runner issues `ROLLBACK` before surfacing the
  error.
- **Connection affinity**: `Bun.SQL` pools connections; separate pool
  calls do not guarantee the same physical connection. Migrations use
  `sql.reserve()` to pin one connection for the whole run, acquire a
  session-level `pg_advisory_lock`, and `release()` it in a bracketed
  cleanup path. Application request handling still uses the shared pool
  handle; only the migration runner reserves.
- **Connection pooling and lifecycle**: `Bun.SQL` auto-pools (lazy connect,
  default 10 connections). The application creates one `SQL` handle after
  synchronous startup migrations complete, reuses it for the app lifetime,
  and closes it during shutdown.

### Migrations: hand-rolled runner in `App.Migration`

- Numbered `.sql` files in `migrations/` (e.g. `001_create_users.sql`).
- `schema_migrations` table tracks applied migrations with SHA-256
  checksums (via `Bun.SHA256.hash`).
- **No down-migrations** (YAGNI). Schema is forward-only.
- **Checksum verification**: on each run, applied migrations are
  checked against current file checksums. Mismatch fails the run —
  detects tampering or accidental edits.
- **Transaction per migration**: each pending migration runs in
  `BEGIN`/`COMMIT` with `ROLLBACK` on body or commit failure. The
  `schema_migrations` insert is in the same transaction as the migration
  SQL — atomic.
- **Reserved connection**: `migrateOnPool` reserves one pooled connection,
  acquires a session advisory lock, runs pending migrations on that handle,
  then unlocks and releases. `migrate` connects, delegates to
  `migrateOnPool`, and closes the pool.
- **Discovery**: `Bun.Glob.scanSync("migrations/*.sql")` — no `node:fs`.
  Sorted by numeric prefix.
- **File reading**: `Bun.file(path).text()` — no `node:fs`.

### File/hash helpers in `App.Bun`

`readTextFile`, `glob`, `sha256Hex` added to `App.Bun` (already
allowlisted) — keeps the FFI allowlist at 4 modules instead of adding
a fifth for file operations.

The same approved Bun boundary is the default boundary for auth/session
cryptographic primitives: secure random generation, SHA-256 token hashing,
and password operations. The opaque session bearer token does not require an
HMAC boundary. If the eventual implementation needs a new module, it must be
added to the FFI allowlist with explicit justification; this ADR does not
claim that auth/session implementation is complete.

### CLI integration

`MIGRATE_ONLY=1` env var makes the server bundle run migrations and
exit (no HTTP serve). Makefile targets:
- `make migrate` — bundle + run with `MIGRATE_ONLY=1`
- `make migrate-create NAME=foo` — scaffold a new migration file

## Consequences

### Positive

- **No external migration tool** — one less binary dependency in CI
  and Docker.
- **All migration logic in PS** — type-checked, testable, no shell
  scripts.
- **Injection-safe by construction** — `execMulti` takes no params
  (trusted SQL only); `query`/`execute` are parameterized.
- **No `node:fs`** — Bun-native file/glob/hash APIs throughout.
- **Forward-only** — simpler model, no down-migration bugs.
- **Startup ordering** — migrations complete on a reserved, locked
  connection before the long-lived SQL handle serves request traffic.
  Application-lifetime pool wiring remains Phase 3B.

### Negative

- **~150 lines of PS for the runner** — but this is the idiomatic
  Haskell approach and avoids a dependency.
- **No down-migrations** — schema changes that need rollback require
  manual SQL. Acceptable for a starter template.
- **`execMulti` is a sharp tool** — it runs arbitrary SQL with no
  parameters. Mitigated by: (a) type signature makes "no params"
  visible, (b) only called from `App.Migration` with file contents,
  (c) ContractSpec could enforce call-site restrictions if needed.

## Alternatives considered

1. **`golang-migrate`** (external CLI): adds a binary dependency,
  shell-out in Makefile, no PS type safety. Rejected.
2. **`node-pg-migrate`**: npm dependency, JS-centric API, doesn't fit
   the "PS logic, JS plumbing" pattern. Rejected.
3. **`Bun.sql.begin()` callback bridge**: would require a complex
   JS↔Aff bridge (launchAff_ inside Effect, or Promise-based
   handshake). Explicit BEGIN/COMMIT via `execute` is simpler and
   keeps logic in PS. Rejected.
4. **Pooled BEGIN/COMMIT without `reserve()`**: unsafe because pool
   calls may hop connections, breaking transactions and session locks.
   Rejected in Phase 3A.
5. **`node:fs` for file reading**: user explicitly said "no node fs".
   `Bun.file` + `Bun.Glob` are Bun-native. Rejected.

## References

- ADR-003: FFI taming (allowlist pattern)
- ADR-007: Bun.serve (FFI plumbing pattern)
- `docs/conventions/data-layer.md` (updated)
- Bun.sql docs: https://bun.com/docs/api/sql
