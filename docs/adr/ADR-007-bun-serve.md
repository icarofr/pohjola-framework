# ADR-007: Bun.serve migration

**Status:** Accepted
**Date:** 2026-08

## Context

The project originally decided to use the `node:http` API surface (implemented by Bun) to maintain portability and avoid the drift of maintaining two backend implementations. This decision was correct at the time: it provided a stable, well-understood interface while allowing us to run on Bun.

However, several factors changed:
1. **Bun 100% Commitment**: The project has committed fully to the Bun runtime, removing the need for Node.js portability.
2. **Streaming SSR**: Lessons from Next.js and production deployments (spurs.icaro.fr) showed that streaming SSR is critical for perceived performance. `Bun.serve` provides native `ReadableStream` support, allowing the shell to arrive in ~5ms while data-backed content streams in.
3. **Prefetching & Caching**: The `Vary` header approach for fragments proved fragile. Moving to `?_frag=1` URL-based fragments gives fragments their own cache key, independent of `Vary`.

   *Amended:* this originally also claimed `?_frag=1` "enables reliable browser-native prefetching". It does not, and cannot with the current `spaLink` design — see "Fragment prefetching (amended)" under Consequences.
4. **Elysia Patterns**: Study of Elysia.js revealed idiomatic Bun patterns (e.g., `server.reload()`, zero-copy static serving) that are inaccessible via `node:http`.

## Decision

Migrate the server boundary from `node:http` to `Bun.serve` via a single, tamed FFI module (`App.ServerBun.js` / `App.ServerBun.purs`).

### Key Implementation Details:
- **Tamed FFI**: All `Bun.serve` interactions are isolated in `App.ServerBun`. The FFI is thin (~100 lines), allowlisted in the Makefile, and documented.
- **Streaming SSR**: `PostList` streams the HTML shell immediately via `StreamBody`, with content streaming as data resolves. The data layer uses Bun's native `fetch` (`App.FetchBun`) instead of `Affjax.Node` — `Affjax.Node`'s `node:http` compat layer hangs in forked fibers on Bun, preventing streaming.
- **Fragment Detection**: A request is a fragment request when **either** `?_frag=1` is present **or** the `x-alpine-request` header is — `App.Main.isFragmentRequest` is a boolean OR. (Amended: this originally read "avoiding the `Vary` header bug". W6 added `Vary: x-alpine-request` to every HTML response including the streamed one, so fragment detection no longer avoids `Vary` — it complements it. `?_frag=1` still earns its place as a header-free way to request a fragment.)
- **Type-Safe Prefetching**: 
    - `prefetchFor :: Route -> Array Route` provides a compile-time exhaustive list of routes to prefetch for any given page.
    - `renderPrefetch` emits `<link rel="prefetch">` tags for these routes.
    - `spaLink` includes an `@mouseenter="fetch($el.href, …)"` attribute for aggressive hover-prefetching, sending the `x-alpine-request` header so the response is a fragment. (Amended: this originally documented `fetch(this.href)`. `$el` is Alpine's element reference and is correct inside attribute expressions; `this` is not reliable there. `test/ContractSpec.purs` asserts `$el.href` and explicitly asserts the absence of `this.href`, so the ADR as originally written described something the test suite forbids.)
- **Structured Data**: `renderJsonLd` provides XSS-safe JSON-LD for data-backed routes to improve SEO and social sharing.
- **Zero-Copy Statics**: Use `Bun.file()` and the `routes: { dir }` configuration for kernel-level static file serving.
- **View Transitions**: Enabled via a single CSS rule: `@view-transition { navigation: auto; }`.

## Consequences

### Gains:
- **Performance**: Near-instant Time to First Byte (TTFB) via streaming; zero-copy static serving via Bun's `routes: { dir }`.
- **UX**: Perceived instant page loads via hover-prefetching and View Transitions.
- **SEO**: Better structured data via JSON-LD.
- **Simplicity**: A cleaner boundary between PureScript and the Bun runtime.

### Losses:
- **Node Portability**: The app can no longer run on standard Node.js (already an accepted trade-off).

### Fragment prefetching (amended)

The Context section originally claimed `?_frag=1` "enables reliable
browser-native prefetching". That is not achievable with the current design.

`spaLink` navigation fetches the anchor's `href` **with the
`x-alpine-request` header** — never the `?_frag=1` URL. A prefetched
`?_frag=1` entry can therefore never be hit by a click. Making the click fetch
`?_frag=1` would push that query string into the history entry, because
`x-target.push` uses the href for both the fetch and the pushed state.

`renderPrefetch` correctly emits the full `routeUrl`, and the comment above it
identified this before the ADR was amended — a code comment silently overruling
an accepted decision, which is its own problem.

`?_frag=1` keeps its place for the reasons that do hold: header-free fragment
requests for `curl`, integration tests, non-header clients, and a fragment cache
key that does not depend on `Vary`.

**Measured, and it is not what the headers suggest.** No HTML response carries
a freshness directive or a validator, yet `<link rel="prefetch">` still
populates Chromium's prefetch cache, and the *hover* fetch is served from it.
The hover is therefore nearly free.

What is not free is the click. Measured against a programmatic click that never
moves the pointer: a bare navigation is 1 request, hovering first makes it 2,
and a real hover-then-click makes it 3. The third is redundant — after the swap
re-renders the header, the new link sits under the stationary cursor,
`mouseenter` fires again, and it prefetches the route just navigated to.

The redundant third request is **fixed**: `App.Alpine.navLink` omits hover
prefetch when the link's target is the route already shown, and every nav-shaped
link (header nav, footer nav, logo) now uses it. Re-measured, a click costs one
request. The hover prefetch remains, and is served from the prefetch cache.

**Resolved (W6).** Successful full-page HTML responses carry
`Cache-Control: private, max-age=10`; AJAX fragments use the same conservative
browser-cache policy without carrying a nonce; error responses carry `no-store`.
`private` is required for full pages because each embeds a per-request CSP nonce
and a shared cache would replay one visitor's nonce to everyone else. The
`max-age` makes successful responses reusable by that visitor's browser, so the
click is served from cache rather than the network. Errors are excluded because
a transient 5xx must never be answered from cache on retry.

That policy was arrived at by measurement, not reasoning: `private` alone made
things worse (explicit but never fresh, nothing to revalidate against, so
nothing reused). Full measurement in `RECONCILIATION.md` "W6 outcome";
`e2e/prefetch-cache.spec.js` pins the behavior so it cannot change silently.

### Risks:
- **FFI Surface**: New security-critical code in the FFI layer. Mitigated by keeping the FFI minimal and subject to the `make gate` allowlist.
- **Streaming Errors**: Once the shell is streamed (200 OK), the status code cannot be changed if a downstream data fetch fails. Mitigated by rendering a fragment-shaped error into the stream body: `App.Features.Posts.Page.renderListContent` returns the feature's error view (`renderPostsError`) for non-2xx, decode failure, and network error alike, injected between the shell halves.

  *Amended:* this originally named a function `renderErrorFragment`, which has never existed in the repository. The behavior it describes is real and works; only the name was wrong. Anyone reading the original text would reasonably conclude the mitigation was missing and build a duplicate.

  **Now applied on every path.** `App.Main.handleFragment` answers a failed Alpine AJAX fragment request with `renderErrorFragment` (W1, `df7c1040`), and the route-miss 404 does the same when a fragment is requested — that path runs before any `Route` exists, so W1 did not originally reach it. A fragment request is never answered with a full document.
- **API Stability**: `Bun.serve` is more volatile than `node:http`. Mitigated by the thin FFI wrapper.

## Elysia Lessons Adopted
- **No `error` option**: Avoided the `error` callback in `Bun.serve` to keep error handling within the PureScript `Either` flow.
- **`idleTimeout`**: Adopted from Elysia defaults for connection safety.
- **Stream Handling**: Avoided `server.timeout(req, 0)` for streams. The `ReadableStream` is streamed via `ReadableStream` with an `async start(controller)` callback; `controller.close()` is guaranteed via `try/finally` even on enqueue failure. The data layer uses Bun's native `fetch` (`App.FetchBun`) — `Affjax.Node`'s `node:http` compat layer hangs in forked fibers on Bun.
