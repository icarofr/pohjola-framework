# ADR-007: Bun.serve migration

**Status:** Accepted (supersedes the "Decided: node:http" row in IMPROVEMENTS.md)
**Date:** 2026-08

## Context

The project originally decided to use the `node:http` API surface (implemented by Bun) to maintain portability and avoid the drift of maintaining two backend implementations. This decision was correct at the time: it provided a stable, well-understood interface while allowing us to run on Bun.

However, several factors changed:
1. **Bun 100% Commitment**: The project has committed fully to the Bun runtime, removing the need for Node.js portability.
2. **Streaming SSR**: Lessons from Next.js and production deployments (spurs.icaro.fr) showed that streaming SSR is critical for perceived performance. `Bun.serve` provides native `ReadableStream` support, allowing the shell to arrive in ~5ms while data-backed content streams in.
3. **Prefetching & Caching**: The `Vary` header approach for fragments proved fragile. Moving to `?_frag=1` URL-based fragments simplifies caching and enables reliable browser-native prefetching.
4. **Elysia Patterns**: Study of Elysia.js revealed idiomatic Bun patterns (e.g., `server.reload()`, zero-copy static serving) that are inaccessible via `node:http`.

## Decision

Migrate the server boundary from `node:http` to `Bun.serve` via a single, tamed FFI module (`App.ServerBun.js` / `App.ServerBun.purs`).

### Key Implementation Details:
- **Tamed FFI**: All `Bun.serve` interactions are isolated in `App.ServerBun`. The FFI is thin (~100 lines), allowlisted in the Makefile, and documented.
- **Streaming SSR**: `PostList` streams the HTML shell immediately via `StreamBody`, with content streaming as data resolves. The data layer uses Bun's native `fetch` (`App.FetchBun`) instead of `Affjax.Node` — `Affjax.Node`'s `node:http` compat layer hangs in forked fibers on Bun, preventing streaming.
- **Fragment Detection**: Use `?_frag=1` query parameters and the `x-alpine-request` header to detect fragment requests, avoiding the `Vary` header bug.
- **Type-Safe Prefetching**: 
    - `prefetchFor :: Route -> Array Route` provides a compile-time exhaustive list of routes to prefetch for any given page.
    - `renderPrefetch` emits `<link rel="prefetch">` tags for these routes.
    - `spaLink` includes an `@mouseenter="fetch(this.href)"` attribute for aggressive hover-prefetching.
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

### Risks:
- **FFI Surface**: New security-critical code in the FFI layer. Mitigated by keeping the FFI minimal and subject to the `make gate` allowlist.
- **Streaming Errors**: Once the shell is streamed (200 OK), the status code cannot be changed if a downstream data fetch fails. Mitigated by `renderErrorFragment` which replaces the loading state with an error UI.
- **API Stability**: `Bun.serve` is more volatile than `node:http`. Mitigated by the thin FFI wrapper.

## Elysia Lessons Adopted
- **No `error` option**: Avoided the `error` callback in `Bun.serve` to keep error handling within the PureScript `Either` flow.
- **`idleTimeout`**: Adopted from Elysia defaults for connection safety.
- **Stream Handling**: Avoided `server.timeout(req, 0)` for streams. The `ReadableStream` is streamed via `ReadableStream` with an `async start(controller)` callback; `controller.close()` is guaranteed via `try/finally` even on enqueue failure. The data layer uses Bun's native `fetch` (`App.FetchBun`) — `Affjax.Node`'s `node:http` compat layer hangs in forked fibers on Bun.
