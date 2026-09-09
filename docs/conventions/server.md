# Server — App.Server invariants

`src/App/Server.purs` — a thin, auditable wrapper over `Bun.serve`. Every
invariant here is enforced by gate, ContractSpec, or Venom.

## Request handling

- **Body cap** 64KB via Bun's `maxRequestBodySize` — requests exceeding the
  cap are rejected by the runtime before the handler sees them.
- **`attempt`+500 containment** — a handler exception is logged and answered
  with `internalError`. JS-side throws in the FFI are caught in `makeFetch`
  and answered with a 500 carrying security headers.
- **No hung requests** — `idleTimeout: 30` closes idle connections. The FFI's
  `makeFetch` guards against handler throws that would leave the Promise
  unresolved.
- **HEAD body-strip** — HEAD routes share GET handlers; the response body is
  not read (Bun handles HEAD semantics).

## Static files

Production and local dev: Bun's `routes: { dir }` in `App.ServerBun.js` serves
`/assets/*`, `/css/*`, `/images/*`, and `/favicon.svg` from `staticRoot` with
`Cache-Control: public, max-age=31536000` on directory routes. ETag /
`Last-Modified` still come from Bun for revalidation. The `STATIC_ROOT` env var
flows from `Config` → `serve` → `serveImpl` → Bun routes. Route path safety is
verified via `isUnsafePath` (exact `..` / `\` segments rejected).

## Security headers

All Response constructors carry security headers, asserted by ContractSpec.
`script-src` is **nonce-based**: `'nonce-<random>' 'self' 'unsafe-eval'
'strict-dynamic'`. There is no `unsafe-inline` in `script-src` — the two inline
head scripts and the JSON-LD block carry a per-request nonce instead (`style-src`
does still allow `'unsafe-inline'`). `'unsafe-eval'` remains because Datastar
evaluates attribute expressions via `new Function()`; see ADR-000
for the threat-model argument. ContractSpec pins the exact CSP string —
widening it fails a test that demands justification.

There are **two** HTML cache policies, not one. An earlier version of this
section claimed a single policy covering every nonce-bearing response, which
stopped being true once errors split off — and error pages are nonce-bearing
HTML, so the claim was false in exactly the case it was broadest about.

| Responses | Policy | Constructor |
|---|---|---|
| Successful full pages, incl. streamed | `private, max-age=10` | `okWith`, `ok`, `streamResponse` (`htmlCacheControl`) |
| Datastar SSE patches (success) | `private, max-age=180` + ETag (`wyhash`); `If-None-Match` → 304 | `sseEventResponse` / `sseEventResponseMatching` (`patchCacheControl`) |
| Datastar SSE patches (error) | `no-store` (still HTTP 200 — ADR-015) | `sseErrorEventResponse` |
| Errors (4xx/5xx full documents) | `no-store` | `htmlErrorResponse`, `notFound`, `methodNotAllowed`, `internalError`, `tooManyRequests` (`errorCacheControl`) |
| Redirects | `RedirectKind` derives `public, max-age=3600` for 301/308 and `no-store` for 302/303/307 | `redirect`, `redirectVary` |
| robots.txt, sitemap.xml | `public, max-age=86400` | `okTextPublic` in `Main.purs` |
| healthz | none — no nonce, genuinely public | `okText` |
| Static files (Bun `routes: { dir }`) | `public, max-age=31536000` | `App.ServerBun.js` |
| Static files (`fileResponse`, tests) | `public, max-age=31536000` | `fileResponse` |

The `RedirectKind` type enforces the status/policy pairing. For 301/308,
callers must still supply a request-independent location; that semantic property
is not representable by an arbitrary `String`.

`private` on full pages because each embeds a per-request CSP nonce and a
shared cache would replay one visitor's nonce to everyone else; `max-age`
because without a freshness lifetime the response is never reusable, which makes
hover prefetch pure overhead. Both halves are pinned by the response contracts
and `e2e/prefetch-cache.spec.js`.

**Fragments share the policy for a different reason.** `renderFragment` emits no
`<script>` tags and therefore carries no nonce at all — verified, a fragment
response contains zero `nonce=` attributes. `private` there is a conservative
default, not a requirement. The earlier wording ("every nonce-bearing HTML
response") implied one justification covering both, which was false for half of
`okWith`'s callers. ContractSpec now pins both facts — pages carry a nonce,
fragments do not — so the justification cannot quietly stop matching the code.

The policy header is emitted **last** in `okWith` too. It previously came first
and was overridable by a caller-supplied `Cache-Control`, which was the same
defect fixed for the error and redirect constructors and left behind on the
success path.

`no-store` on errors because a transient 5xx must never answer a retry from
cache. Redirects require an explicit choice at the call site, so a future
permanently-cacheable 301 cannot silently inherit the transient policy.

The policy header is emitted **last** in every constructor: the Bun bridge
applies headers with `Headers.set` in iteration order, so a caller-supplied
`Cache-Control` in `extraHeaders` cannot replace it.

## Streaming & fragments

- **Streaming**: Buffered SSR is the default. The `StreamBody` path is disabled
  experimental opt-in; when enabled, a route using it sends the HTML shell
  immediately via `ReadableStream`.
  `controller.close()` is guaranteed via `try/finally` even on enqueue
  failure. Status is always 200 (committed at shell time).
- **Datastar patches**: the server detects a Datastar action via a single
  signal — the `datastar-request` header (`isDatastarRequest`), sent
  automatically by every `@get`/`@post` call. Unlike the Alpine-based
  transport this superseded (ADR-011), there is no header-free query-param
  fallback: Datastar's own protocol has no such convention, and replicating
  one would be inventing behavior beyond what the library does. A header-free
  patch request (curl, a non-Datastar client) is not currently supported —
  send the `datastar-request: true` header, or request the full page. Patch
  responses carry `Vary: datastar-request`. Patches never stream (small,
  already fast).
- **Static routes** (`Home`, `About`, `Guarantees`, `Docs`) use
  `StringBody` — no streaming. A data-backed route (can 404) would use it
  too; none currently exists in the tree.

The data layer uses Bun's native `fetch` (`App.FetchBun`) — `Affjax.Node`'s
`node:http` compat layer hangs in forked fibers on Bun.

## Error pages

`renderErrorPage` (in `App.Layout.Page`) — branded 404/500 with full layout,
not plain text. `htmlErrorResponse` — HTML error response with a bounded
4xx/5xx status and `no-store` policy.

## Logging

`App.Logger` provides `logErr`, `logWarn`, `logInfo` writing JSON lines to
stdout with fields `{ts, level, msg, ...}`. Errors use `error`, degradations
`warn`, startup `info`. Logs are best-effort on EPIPE — they never crash the
process.

## Runtime

Production and CI run **Bun** (committed 100%). The server is implemented
using `Bun.serve` via a tamed FFI boundary (`App.ServerBun`), as recorded in
ADR-007.

## Graceful shutdown

`SIGTERM` (docker stop) and `SIGINT` (Ctrl-C) trigger a graceful drain in
`App.ServerBun.js`:

1. `server.stop()` (graceful) closes the listener — no new connections.
2. In-flight requests finish; idle keep-alive connections close immediately.
3. The Promise from `server.stop()` resolves when `pendingRequests === 0`.
4. A 30s backstop calls `server.stop(true)` (force) if a request hangs.
5. A second signal force-exits immediately.

Verified from Bun source (`src/runtime/server/mod.rs:1674-1683`): a graceful
stop with work in flight keeps the event-loop ref until the drain completes.

**Docker**: the `Dockerfile` uses `ENTRYPOINT ["bun", "/app/server.js"]` — Bun
is PID 1 and receives signals directly. No `--init` wrapper needed.
