# Testing recipes — canonical skeletons

## Unit tests (`test/*Spec.purs`)

Use **purescript-spec**. Test seams are pure functions; extract a pure seam
before exercising I/O.

- `test/RateLimitSpec.purs` extracts the pure `shouldAllow` seam — currently
  the only coverage `App.RateLimit` has. No route calls it right now (the
  clean-sheet rebuild removed the last mutating route), so there's no
  integration-level burst test either; add one back alongside whichever
  mutating route wires `App.RateLimit` in again.
- `test/LoggerSpec.purs` extracts the pure `renderLogLine` seam.

When a feature needs I/O, extract a pure seam first and test that seam.

Tests run under **Bun** (`make test` runs `bun -e`, not `spago test`) —
matching the production runtime and enabling Bun native APIs in tests.

**Verify**: `make test`

## Integration tests (Venom YAML + fixtures)

Files live in `venom/*.yml`; a local fixture service (`venom/fixtures/posts-server.js`)
runs via `docker-compose.test.yml`.

Route all external calls to a fixture. Skip the test if a fixture is not
available — hit the network only in production.

- POST assertions carry `no_follow_redirect: true`. Redirect tests assert on
  the `Location` header, not by following it. No current Venom file exercises
  a mutating route — the clean-sheet rebuild removed the last one
  (`/api/contact`/`/api/newsletter`, see `App.Main`'s entry-point comment) —
  so there's no example to point at until a mutating route returns.
- Quote YAML scalars starting with special characters (e.g. `"Disallow: /"`).
- Adding a data-backed page → add a Venom file; extend the fixture route if
  a new upstream is required.

**Verify**: `make test/integration`

## End-to-end tests (Playwright)

Files under `e2e/*.spec.js`. Chromium runs the `no-js` variant
(`nojs.spec.js` pattern in `playwright.config.js`). The `webServer` config
sets `RATE_LIMIT_MAX=0`.

Assert on user-visible state: URL, banner text, `data-page-title`. Asserting
on implementation-only classes or IDs couples the test to structure.

Tests compile cleanly when `bun x playwright test --list` succeeds.

**Verify**: `make test/e2e`
