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

Production: Bun's `routes: { dir }` serves `/assets/*`, `/css/*`, `/images/*`,
and `/favicon.svg` from the `staticRoot` (passed through `serveImpl`) with
kernel-level path safety. The `STATIC_ROOT` env var flows from `Config` →
`serve` → `serveImpl` → Bun routes.

`serveStatic` is test-only — kept for ContractSpec and ServerSpec. Path
safety via `isUnsafePath` (exact `..` / `\` segments rejected).

## Security headers

All Response constructors carry security headers, asserted by ContractSpec.
CSP allows `'unsafe-inline'` + `'unsafe-eval'` only for script-src (Alpine's
build needs eval; inline head scripts need inline). ContractSpec pins the
exact CSP string — widening it fails a test that demands justification.

## Streaming & fragments

- **Streaming**: `PostList` sends the HTML shell immediately via `StreamBody`
  (a `ReadableStream`). Page content streams as it resolves.
  `controller.close()` is guaranteed via `try/finally` even on enqueue
  failure. Status is always 200 (committed at shell time).
- **Fragments**: The server detects fragment requests via `?_frag=1` query
  parameter AND the `x-alpine-request` header. Fragment responses carry
  `Vary: x-alpine-request`. Fragments never stream (small, already fast).
- **Static routes** (`Home`, `About`, `Contact`, `Legal`) and `PostDetail`
  (can 404) use `StringBody` — no streaming.

The data layer uses Bun's native `fetch` (`App.FetchBun`) — `Affjax.Node`'s
`node:http` compat layer hangs in forked fibers on Bun.

## Error pages

`renderErrorPage` (in `App.Layout.Page`) — branded 404/500 with full layout,
not plain text. `htmlResponse` — HTML response with custom status.

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
