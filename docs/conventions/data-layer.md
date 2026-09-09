# Data layer — async page rendering

Pages are **not** pure. `pageRenderer :: Route -> Lang -> Aff (Either AppError Html)`
in `Main.purs` is async. Static pages use the `staticPage` smart constructor
from `App.Layout.Page` (signature `staticPage :: Html -> Aff (Either AppError Html)`).
Data-backed pages fetch and may return `Left AppError`.

## The two feature templates

- **STATIC** (Home, About, Guarantees, Docs — every feature currently in
  the tree): `Page.purs` + `View.purs`
- **DATA-BACKED**: `Types.purs` + `Service.purs` + `Page.purs` + `View.purs`

ContractSpec enforces: every feature has `Page.purs` with a `render*` entry;
a feature with `Service.purs` implies the full `Types/Service/Page/View`
split; features stay isolated from siblings.

## The data-backed pattern

No data-backed feature currently exists in the tree — the clean-sheet
rebuild removed the last one (`Posts`, an HTTP-fetched JSONPlaceholder
demo). Grep git history (`git log --all --diff-filter=D -- 'src/App/Features/Posts/*'`)
for a worked example if you want prior art; the pattern itself:

1. **Types** (`Types.purs`) — domain newtype + `DecodeJson` instance
2. **Service** (`Service.purs`) — `fetchX :: Aff (Either AppError (Array X))`.
   Errors are values (AppError), not exceptions.
3. **Page** (`Page.purs`) — `renderList :: Lang -> Aff (Either AppError Html)`.
   Fetches, pattern-matches: `Right` → render view, `Left` → propagate.
4. **View** (`View.purs`) — pure rendering from pre-fetched data.
5. **Router** (`Main.purs`) — maps `Left AppError` to HTTP status
   (NotFound → 404, _ → 500) via `renderErrorPage`.

**Done when**: `make check` passes and the page renders data from the
fixture, returns 404 for missing resources, and 500 on upstream failure.

## Fetching — App.Data.Fetch

All HTTP fetching goes through `App.Data.Fetch.fetchJson`. Feature modules
import from shared modules only — importing a sibling feature fails
ContractSpec.

## Database — App.Data.SQL (ADR-009)

For PostgreSQL-backed features, use `App.Data.SQL` (Bun.SQL bindings)
instead of HTTP fetching. The same `Aff (Either AppError a)` pattern
applies — map SQL errors to `AppError` at the feature boundary.
`App.Data.SQL`, `App.Migration`, and `make migrate` are implemented (ADR-009
Phase 3A). What remains pending is the application-lifetime connection pool
(Phase 3B) and production auth/session wiring — not the SQL module itself.

### Connection

`App.Data.SQL.connect :: String -> Effect SQL` creates a pooled client
(Bun.SQL auto-pools, lazy-connect). One handle per app lifetime; `close`
on shutdown. Connection string from `Config.databaseUrl` (env: `DATABASE_URL`).

### Querying — injection-safe

```purs
-- Parameterized (safe — Bun extended protocol binds params separately)
query  :: SQL -> String -> Array Foreign -> Aff (Either String (Array Row))
execute :: SQL -> String -> Array Foreign -> Aff (Either String Unit)
```

Always use `$1`, `$2` placeholders with params. Never string-interpolate
user input into the SQL string.

### Migrations — App.Migration

Numbered `.sql` files in `migrations/` (e.g. `001_create_users.sql`).
No down-migrations (YAGNI — forward-only). SHA-256 checksums detect
tampering. Each migration runs in a transaction with the
`schema_migrations` insert — atomic.

```bash
make migrate                      # run pending migrations
make migrate-create NAME=foo      # scaffold migrations/NNN_foo.sql
```

`MIGRATE_ONLY=1` env var makes the server bundle run migrations and exit
(no HTTP serve) — used by `make migrate` and CI/deploy scripts.

### Safety rules (enforced by design)

- `execMulti` (multi-statement, no params) is for **trusted migration
  SQL only** — never user input. The type signature makes "no params"
  visible at the call site.
- `query`/`execute` are parameterized — injection-safe by construction.
- All migration logic (ordering, checksums, transactions) lives in
  PureScript. The JS FFI is plumbing only (ADR-003/007/009).
