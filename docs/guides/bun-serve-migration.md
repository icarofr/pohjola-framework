# Implementation Guide: Idiomatic Bun Server + Type-Safe Prefetching

> Status: **Proposal for ADR-007** — this guide is the design; an ADR should
> land alongside the implementation. It reverses the "Decided / won't do"
> row in `docs/IMPROVEMENTS.md` that committed to `node:http` over
> `Bun.serve`. Read that row, then read this, then decide.

## Why this, why now

Three things changed since the `node:http` decision was written:

1. **We committed 100% to Bun** (Aug 2026). The original decision's first
   justification was "two-backend drift" — i.e. `node:http` keeps the code
   portable if someone later runs on Node. That justification no longer
   applies. What remains is "rewriting on Bun.serve = new security-critical
   code." That's real, but it's a one-time cost, and the payoff is large.

2. **We studied Next.js's SPA-on-server perf work** (cloned `next.js/`). The
   headline lesson: the biggest SSR perf win is **start the fetch early,
   stream the shell, don't block the whole response on data.** Our current
   server blocks: `attempt (handler request)` awaits the entire page render
   (including data fetchs) before sending a single byte. `Bun.serve`'s
   `Response` accepts a `ReadableStream` body natively, which makes streaming
   SSR a first-class pattern instead of a fight against `node:http`'s
   callback-shaped `ServerResponse`.

3. **We studied spurs.icaro.fr** (a production beta built on an earlier
   version of this starter). It has hover prefetch on nav links — but the
   prefetch is silently broken (warms the wrong cache entry due to the
   `Vary: x-alpine-request` header), and it's inconsistently applied (header
   links have it, buttons/pagination/footer don't). This confirmed two things:
   the pattern works and is ADR-000-compatible (plain `@mouseenter` Alpine
   attribute, no custom JS), and it must be centralized in `spaLink` with
   URL-based fragments or it drifts and fails silently.

The fourth reason, smaller but real: `Bun.serve` is ~2.5x faster than Node's
`http` on Linux (Bun's own benchmark, but directionally correct — uWebSockets
vs Node's `http`). We're paying the compat-layer tax for nothing in return.

## What we keep

The decision got two things right that this guide preserves:

- **Invariants are explicit, not framework magic.** Body cap, security
  headers, path safety, request-id correlation, rate limiting, body-read
  timeout, exception containment at the boundary. These are PS-level
  concerns and they move with us.
- **The PS-side `Request`/`Response` ADT stays.** The router in
  `App.Main.purs` is runtime-agnostic. Only `App.Server.purs` (the boundary
  module) changes.

## The shape of the change

One module is replaced (`App.Server.purs`), one FFI file is added
(`App.ServerBun.js`), the Makefile allowlist gains one entry, and one ADR
records the reversal. Three PS modules gain prefetch/fragment logic
(`App.Alpine`, `Data.Route`, `App.Layout.Page`). Everything above
`App.Server` in the dependency graph is unchanged.

```
src/App/Server.purs      ← rewritten (PS types + Aff boundary; no node-http)
src/App/ServerBun.js     ← new (FFI: Bun.serve → callback; Response → stream; routes for static)
src/App/Main.purs        ← serveStatic fallback removed; streaming branch; ?_frag=1 parsing
src/App/Alpine.purs      ← spaLink gains @mouseenter prefetch; fragment URL helper
src/Data/Route.purs      ← routeFragmentUrl + prefetchFor (exhaustive on Route)
src/App/Layout/Page.purs ← renderShell + renderLoading + renderErrorFragment + renderPrefetch
src/App/Layout/Head.purs ← renderJsonLd (exhaustive on Route, XSS-escaped)
css/input.css            ← @view-transition { navigation: auto; }
Makefile                 ← FFI_ALLOWLIST_GREP gains ^src/App/ServerBun\.js
docs/adr/ADR-007-bun-serve.md  ← new (reverses the node:http decision)
```

`App.RateLimit.purs`, `App.Form.purs`, all features, all tests, all
ContractSpec assertions — unchanged. The `Server.Request` and
`Server.Response` records keep the same fields. The router doesn't know
what's underneath. `serveStatic` is removed (Bun's `{ dir }` routes replace
it); `isUnsafePath` stays as a tested function but is no longer on the hot
path.

## The FFI boundary (follows ADR-003)

`docs/ffi-taming-guide.md` is the recipe; this is its application to
`Bun.serve`.

### `.purs` side — the contract

`App.Server.purs` keeps the existing `Request` and `Response` records, adds
one new constructor for streaming, and exposes `serve`:

```purs
data ResponseBody
  = StringBody String
  | BinaryBody Buffer
  | StreamBody (ReadableStream ())   -- NEW: chunks yielded over time

type Response =
  { status :: Int
  , headers :: Array (Tuple String String)
  , body :: ResponseBody
  }

serve :: Int -> (Request -> Aff Response) -> Effect Unit
```

The `Request` record gains a `cookies` field (from Bun's `CookieMap`):
`{ id, ip, method, path, headers, cookies, body, query }`.
`body :: Aff String` stays — the FFI reads the body into a string before
invoking the handler, same as today. (Streaming *request* bodies are out of
scope; forms don't need them, and the body-read timeout invariant depends on
consuming the body.)

### `.js` side — the binding

`App.ServerBun.js` does four things and nothing else:

1. Calls `Bun.serve({ port, routes, fetch(req, server) { ... } })`.
2. Adapts the Web `Request` to the PS `Request` record (reads body, parses
   URL, extracts IP via `server.requestIP(req)`, passes cookies through).
3. Adapts the PS `Response` record back to a Web `Response` (status, headers,
   body — including `ReadableStream` passthrough).
4. Exposes `server.reload(options)` so PS can hot-swap the handler without
   dropping connections (see "server.reload — the Bun-native hot reload"
   below).

**No `error` option.** Elysia (studied at `elysia/src/adapter/bun/index.ts`)
deliberately omits `Bun.serve`'s `error(err)` callback and handles all
errors inside `fetch`, returning `Response` objects. This avoids Bun's dev
error pages leaking stack traces and keeps error handling in application
code. We do the same: the PS-side `attempt` boundary catches PS errors and
returns a proper `Response`; the FFI's `fetch` callback wraps `onRequest`
in `.catch(() => new Response("Internal Server Error", { status: 500 }))`
as a last-resort containment for JS-side throws (in `toPsRequest`, etc.).
No `error` option means no second error path to reason about.

**No app logic.** No routing, no rate limiting, no security headers, no
error handling. The PS side owns all of that. The JS file is plumbing.

Sketch (the real file is longer but this is the whole shape):

```js
// App.ServerBun.js
// Bun.serve binding. No app logic — see ADR-003 and ADR-007.

export function serveImpl(port, onRequest) {
  const server = Bun.serve({
    port,
    development: process.env.NODE_ENV !== "production",
    reusePort: true,          // Elysia default; kernel load-balances
    idleTimeout: 30,          // PS-side bodyReadTimeout is the inner bound
    maxRequestBodySize: 64 * 1024,  // mirrors App.Server.maxBodyChars
    routes: {
      // Static files — zero-copy, kernel-level path safety (see Bun.file section)
      "/assets/*": { dir: "./dist/assets" },
      "/css/*":    { dir: "./dist/css" },
      "/images/*": { dir: "./dist/images" },
      "/favicon.svg": Bun.file("./dist/favicon.svg"),
    },
    fetch(req, server) {
      // Everything else → PS router (pages, API, robots, sitemap, healthz).
      // No `error` option on Bun.serve — last-resort containment is here.
      return onRequest(toPsRequest(req, server)).then(
        psResp => toWebResponse(psResp),
        () => new Response("Internal Server Error", { status: 500 })
      );
    },
    // Note: no `error(err)` option. Elysia omits it (confirmed in
    // elysia/src/adapter/bun/index.ts:349-379); we do too. The .catch
    // above is the only JS-side error path.
  });
  return server;
}

// Hot-swap the handler without dropping connections (see server.reload section)
export function reloadImpl(server, onRequest) {
  server.reload({ fetch(req, srv) {
    return onRequest(toPsRequest(req, srv)).then(
      psResp => toWebResponse(psResp),
      () => new Response("Internal Server Error", { status: 500 })
    );
  }});
}

function toPsRequest(req, server) {
  // Returns the fields App.Server.Request expects. Body read happens here
  // (await req.text()) so the PS side gets `Aff String` that's already
  // resolved. URL parsing (path/query split) stays in PS — pass req.url raw.
  const url = new URL(req.url);
  const ip = server.requestIP(req)?.address ?? "unknown";
  // BunRequest has a built-in CookieMap — pass it through for auth (ADR-002).
  // PS side reads cookies from the map; no manual Cookie header parsing.
  const cookies = {};
  if (req.cookies) for (const [k, v] of req.cookies) cookies[k] = v;
  return {
    method: req.method,
    url: req.url,
    path: url.pathname,
    query: url.search,
    headers: Object.fromEntries(req.headers),
    cookies,
    ip,
    // body: Promise<string> — PS side awaits via makeAff
    bodyPromise: req.text(),
  };
}

function toWebResponse(psResp) {
  const headers = new Headers();
  for (const [k, v] of psResp.headers) headers.set(k, v);
  const body = psResp.body;  // StringBody | BinaryBody | StreamBody
  if (body._tag === "StreamBody") {
    return new Response(body.stream, { status: psResp.status, headers });
  }
  // StringBody / BinaryBody — Bun accepts string, Buffer, ArrayBuffer
  return new Response(body.value, { status: psResp.status, headers });
}
```

The PS side calls `serveImpl` via `foreign import`, wraps the
`onRequest` callback in a `makeAff`, and the existing `attempt` boundary in
`serve` stays exactly where it is.

The FFI also exposes `reloadImpl(server, onRequest)` — a thin wrapper around
`server.reload({ fetch })` that hot-swaps the request handler without
dropping connections. See "server.reload — the Bun-native hot reload" below.

### Why this is ADR-003-compliant

- **Target priority:** Bun-native (`Bun.serve`) — tier 3 in the guide. We
  deploy 100% Bun; no `typeof Bun` dispatch needed.
- **No app logic in JS:** the JS file maps types and calls `Bun.serve`. All
  decisions (routing, headers, status, error containment) are in PS.
- **Decode at the boundary:** the PS `Request` record is the decoded form;
  the JS side produces it directly from Web API primitives. No `Foreign`
  decoding needed because we control the JS side — it returns a plain object
  with the exact field names PS expects. (This is the "JS returning
  primitives → import directly" case from the guide, not the "JS returning
  objects → Foreign decode" case.)
- **Never throw across the boundary:** the FFI's `fetch` callback wraps
  `onRequest` in `.then(ok, err)` — JS-side throws become a 500 `Response`;
  PS-side throws are caught by `attempt` and returned as a proper `Response`.
  No `error` option on `Bun.serve` (Elysia pattern) — one error path, not two.
- **Allowlist + ADR:** `FFI_ALLOWLIST_GREP` gains `^src/App/ServerBun\.js`;
  ADR-007 records the decision.

## Streaming SSR — the actual perf win

This is the lesson from Next.js, applied. Today:

```
request → handler → pageRenderer (fetch + render) → sendResponse → done
                       ↑ blocks here ~200-2000ms ↑
```

With streaming:

```
request → handler → send <head> + layout shell immediately
                → start data fetch
                → stream <body> when fetch resolves
                → done
```

The user sees the shell in ~5ms instead of ~500ms. The data still takes the
same time to fetch; the *perceived* load is dramatically faster, and the
browser can start parsing CSS/HTML while the data is in flight.

### How it works with our Html ADT

`App.Html.render :: Html -> String` is pure and synchronous. Today
`renderPage` produces the full page string, then `sendResponse` sends it.
Streaming splits that into two renders:

1. **Shell render** — `renderShell lang route` produces `<!doctype><html>
   <head>…</head><body><div id="content">` and a closing `</div></body></html>`.
   This is pure, fast, and has no data dependency.
2. **Content render** — `pageRenderer cfg route lang` produces the page
   body. This may fetch data.

The `StreamBody` constructor takes a `ReadableStream`. The PS side creates
the stream, writes the shell, awaits the content, writes the content, closes
the stream. Bun sends bytes as they're written.

### What changes in `App.Main.purs`

`handleRoute` gains a streaming branch for data-backed routes. Static pages
(still the majority) keep the fast path: render the whole thing, return
`StringBody`, done. Only `PostList` and `PostDetail` (the data-backed
routes) stream.

```purs
handleRoute :: Config -> Lang -> Route -> Map String String -> Map String String -> Aff Server.Response
handleRoute cfg lang route headers query =
  case route of
    -- Static pages: render whole, return StringBody (fast path, no stream)
    Home -> staticResponse cfg lang route query
    About -> staticResponse cfg lang route query
    Contact -> staticResponse cfg lang route query
    Legal -> staticResponse cfg lang route query
    -- Data-backed: stream shell, then content
    PostList -> streamResponse cfg lang route headers query
    PostDetail id -> streamResponse cfg lang route headers query
```

`streamResponse` builds a `ReadableStream` that:
1. Yields `renderShell cfg.baseUrl lang route` with `renderLoading lang route`
   inside `#content` (pure, immediate — the user sees a skeleton instantly).
2. Awaits `pageRenderer cfg route lang`.
3. Yields the rendered content (or `renderErrorFragment lang route err` on
   `Left` — the user sees a graceful error in-place, not a blank 500).
4. Closes. The `request.signal` 'abort' event (client disconnect) is wired
   to `controller.close()` so the stream stops cleanly.

**No `server.timeout(req, 0)` call.** Elysia (studied at
`elysia/src/adapter/utils.ts:246-409`) does **not** disable the idle timeout
for streams — it relies on chunked transfer-encoding and the abort signal
for stream lifecycle. We follow the same pattern: the shell yields
immediately (resetting the idle timer), and subsequent chunks yield as data
resolves. If a data fetch exceeds `idleTimeout: 30`, the stream closes and
the error fragment yields — which is the correct behaviour (a 30s data fetch
is a failure, not a slow success). This drops the `disableTimeout` FFI
export entirely — one less FFI surface.

The PS-side `bodyReadTimeout` (30s) still bounds the *request body* read;
this only affects the *response* streaming.

The `Vary: alpine-request` header is **removed**. Fragment detection moves
to the URL (`?_frag=1`), which makes fragments prefetchable (see
"Type-safe prefetching" below). The streaming response sets no Vary header —
the URL is the cache key.

### What about the alpine fragment path?

When the URL contains `?_frag=1`, the client wants a fragment, not a full
page. Streaming a fragment is pointless (it's small, already fast). The
fragment path keeps `StringBody` — only full-page data-backed responses
stream.

### Per-route loading states (Next.js's `loading.tsx` convention)

Next.js has a file convention: `loading.tsx` renders a skeleton while the
page's data resolves. The user sees *something* immediately instead of a
blank page. This is the single biggest UX win from streaming — the shell
arrives in ~5ms, but without a loading state, `#content` is empty. A
skeleton tells the user "content is coming" and shapes the layout so it
doesn't jump when the data arrives.

Our version is a type-safe PS function, exhaustive on `Route`:

```purs
-- App.Layout.Page.purs (new)
-- | Per-route loading skeleton. Exhaustive on Route — adding a data-backed
-- | route forces a loading state here. Static routes return empty (they
-- | don't stream, so they never show a loading state).
renderLoading :: Lang -> Route -> Html
renderLoading lang PostList =
  el "div" [ class_ "space-y-4 animate-pulse" ]
    [ el "div" [ class_ "h-8 bg-slate-200 dark:bg-slate-800 rounded" ] []
    , el "div" [ class_ "h-8 bg-slate-200 dark:bg-slate-800 rounded" ] []
    , el "div" [ class_ "h-8 bg-slate-200 dark:bg-slate-800 rounded" ] []
    ]
renderLoading lang (PostDetail _) =
  el "div" [ class_ "space-y-4 animate-pulse" ]
    [ el "div" [ class_ "h-12 bg-slate-200 dark:bg-slate-800 rounded w-3/4" ] []
    , el "div" [ class_ "h-4 bg-slate-200 dark:bg-slate-800 rounded" ] []
    , el "div" [ class_ "h-4 bg-slate-200 dark:bg-slate-800 rounded" ] []
    ]
renderLoading _ _ = el "div" [] []  -- static routes: no skeleton
```

The `animate-pulse` Tailwind class gives a subtle shimmer — the standard
skeleton pattern. No JS, no Alpine, pure CSS animation.

`renderShell` calls `renderLoading` to fill `#content` before the stream
starts. When the data resolves, the streamed content replaces the skeleton
in-place. The browser swaps the DOM node; no layout jump.

### Per-route error boundaries (Next.js's `error.tsx` convention)

Next.js has `error.tsx` — a per-route error UI that catches errors *within*
that route's render, without replacing the whole page. The layout stays;
only the erroring section swaps.

Today, a `Left AppError` from `pageRenderer` produces a full-page error
(404 or 500) via `renderErrorPage`. The layout, nav, footer — all replaced.
For streaming routes, we can't even change the status code after the shell
is sent.

The fix: a `renderErrorFragment` that streams into `#content` on failure:

```purs
-- App.Layout.Page.purs (new)
-- | Per-route error fragment for streaming routes. The shell (nav, footer,
-- | layout) stays intact; only #content swaps to the error. Exhaustive on
-- | Route — every data-backed route gets an error UI.
renderErrorFragment :: Lang -> Route -> AppError -> Html
renderErrorFragment lang route err =
  el "div" [ class_ "mx-auto max-w-3xl px-4 py-16 text-center" ]
    [ el "h2" [ class_ "text-2xl font-bold text-slate-900 dark:text-white" ]
        [ text (errorTitle lang err) ]
    , el "p" [ class_ "mt-4 text-slate-600 dark:text-slate-300" ]
        [ text (errorMessage lang err) ]
    , el "a"
        [ href (routeUrl lang Home)
        , class_ "mt-6 inline-block text-blue-600 dark:text-blue-400 hover:underline"
        ]
        [ text (dict lang).common.backHome ]
    ]
```

For streaming routes, `streamResponse` yields this fragment on `Left`. The
status code is 200 (already sent with the shell); the user sees a graceful
error in the content area, not a blank 500 page. This is honest — the
*document* loaded successfully; a *section* failed.

For non-streaming routes (static pages, fragment requests), the existing
full-page error path (`renderErrorPage` with proper 4xx/5xx status codes)
stays. Streaming errors are opt-in per route, same as streaming itself.

### What about errors mid-stream?

If the data fetch fails *after* the shell is already streamed, we can't
change the status code (it's already 200, already sent). This is the
fundamental tradeoff of streaming SSR — Next.js makes it too.

The `renderErrorFragment` above is the mitigation. The shell includes
`renderLoading` (a skeleton). On stream error, the skeleton is replaced by
`renderErrorFragment` (a graceful error). The status code is 200; the user
sees a clear error message in the content area, with the nav and footer
intact. This is the same pattern Next.js uses: the document loaded
successfully, a section failed.

For non-streaming routes (the majority), errors still produce proper
4xx/5xx status codes. Streaming is opt-in per route, only for data-backed
pages, and only when the shell is genuinely independent of the data.

## Type-safe prefetching — the spurs.icaro.fr lessons

This is the other half of the perf story. Streaming SSR speeds up the first
load; prefetching speeds up navigation. Together they're the MPA equivalent
of what Next.js does with Suspense + `<Link prefetch>`.

### Lesson 1: `?_frag=1` URL-based fragments (fixes the Vary bug)

Today, the server distinguishes full-page requests from fragment requests
via the `x-alpine-request` header. The response carries `Vary:
x-alpine-request` so the browser caches them separately.

**This breaks prefetch.** `fetch(this.href)` (hover prefetch) does a plain
GET without the header. The server responds with a full page. The browser
caches it. Then on click, Alpine AJAX sends `x-alpine-request: true` — a
different cache entry. The prefetch was wasted. This was confirmed in
production on spurs.icaro.fr: the hover prefetch exists but doesn't help.

The fix: move fragment detection from a header to the URL.

```purs
-- Data/Route.purs (new)
routeFragmentUrl :: Lang -> Route -> String
routeFragmentUrl lang route = routeUrl lang route <> "?_frag=1"
```

The server checks `Map.lookup "_frag" query` instead of
`Map.lookup alpineRequestHeader headers`. The `Vary: alpine-request` header
is removed — the URL is the cache key. Now `fetch("/en/posts?_frag=1")`
(hover) and Alpine AJAX's `fetch("/en/posts?_frag=1")` (click) hit the same
cache entry. Prefetch works.

`routeFragmentUrl` is total and exhaustive — it's built from `routeUrl`,
which is derived from the `routing-duplex` codec. No string concatenation in
JS, no URL construction in the browser.

### Lesson 2: `@mouseenter` prefetch in `spaLink` (centralized, no custom JS)

The spurs.icaro.fr beta has hover prefetch on header nav links via a plain
Alpine attribute:

```html
<a href="/en/posts" x-target.push="content" @mouseenter="fetch(this.href)">
```

No custom JS. No plugin. Just an Alpine `@mouseenter` expression calling
`fetch()`. This is ADR-000-compatible — same category as `@click="open = !open"`.

But on spurs.icaro.fr, only the header has it. Buttons, pagination, and
footer links don't — because there's no `spaLink` helper; each call site
inlines Alpine attributes manually. One agent added it to the header; no
subsequent agent knew to add it elsewhere. This is the drift problem.

The fix: bake `@mouseenter` prefetch into `spaLink` in `App.Alpine.purs`.

```purs
-- App.Alpine.purs (revised)
spaLink :: Lang -> Route -> Array Attr -> Array Html -> Html
spaLink lang route extraAttrs children =
  el "a"
    ( [ href (routeUrl lang route)
      , attr "x-target.push" contentTarget
      , attr "@mouseenter" ("fetch('" <> routeFragmentUrl lang route <> "')")
      ] <> extraAttrs
    )
    children
```

One line. Every `spaLink` call site gets hover prefetch for free. The
fragment URL is type-safe (from `routeFragmentUrl`). The drift is
structurally impossible — you can't use `spaLink` without getting prefetch.

### Lesson 3: `prefetchFor` — compile-time route enumeration

This is something Next.js **can't do**. Their routes are file-system
conventions, not a sum type. Our `Route` ADT lets us enumerate prefetch
targets at compile time, with exhaustiveness checking.

```purs
-- Data/Route.purs (new)
-- | Which routes should be prefetched when rendering a given route.
-- | Exhaustive on Route — adding a constructor forces a decision here.
prefetchFor :: Route -> Array Route
prefetchFor Home = [PostList, About, Contact]
prefetchFor PostList = [PostDetail 1, PostDetail 2, PostDetail 3]
prefetchFor (PostDetail n) = [PostList, PostDetail (n + 1)]
prefetchFor About = [Home, Contact]
prefetchFor Contact = [Home, About]
prefetchFor Legal = [Home]
```

Adding a `Route` constructor without adding a `prefetchFor` case is a
compile error. The compiler enforces that every route has a prefetch
decision. This is the type-safety win that makes our prefetching stronger
than Next.js's.

### Lesson 4: `<link rel="prefetch">` from `prefetchFor` (browser-native)

`prefetchFor` feeds two prefetch mechanisms:

1. **`@mouseenter` on `spaLink`** — hover prefetch, instant, per-link.
2. **`<link rel="prefetch">` in `<head>`** — viewport prefetch, browser-native,
   no JS at all. The browser fetches likely-next routes idle.

```purs
-- App.Layout.Page.purs (new)
renderPrefetch :: Lang -> Array Route -> Html
renderPrefetch lang routes =
  -- One <link rel="prefetch" href="/en/posts?_frag=1"> per route
  foldMap (\route ->
    el "link" [ attr "rel" "prefetch", href (routeFragmentUrl lang route) ] []
  ) routes
```

`renderPage` calls `renderPrefetch lang (prefetchFor route)` in the `<head>`.
The browser prefetches fragment URLs for likely-next navigations. When the
user clicks, the fragment is already in the HTTP cache. No client JS needed
for this — it's a standard HTML tag.

### What we do NOT need: a custom router plugin

An earlier version of this guide proposed writing a custom `router.min.js`
(~150 lines) to replace Alpine AJAX. That was over-engineering. The spurs
beta proved that:

- **Hover prefetch** is a one-line Alpine attribute, not a plugin.
- **Persistent cache** is the browser HTTP cache (with `?_frag=1` URLs).
- **Streaming swap** saves ~10ms on fragments that are a few KB — not worth
  150 lines of custom JS.
- **Loading state** is Alpine `x-data` + `@ajax:send`/`@ajax:after` events.

We keep Alpine AJAX (9KB, pinned, self-hosted, works), add one `@mouseenter`
attribute to `spaLink`, switch from header-based to URL-based fragments, and
get type-safe prefetching. No custom JS. No gate safeguards for a plugin we
don't write. Less code, less risk, same result.

### The Alpine AJAX maintainer's position

The maintainer explicitly says Alpine AJAX is not designed for page-to-page
navigation and recommends browser-native APIs (Speculation Rules, View
Transitions) for that. We're using Alpine AJAX's `x-target.push` for
navigation — it works, but it's off-label. The `?_frag=1` + `@mouseenter`
approach aligns with the maintainer's recommendation: we use browser-native
`fetch()` for prefetch and Alpine AJAX for the swap. If we later adopt
Speculation Rules (declarative prerender, no JS), it's an additive `<script
type="speculationrules">` block — not a replacement of Alpine AJAX.

## JSON-LD structured data — type-safe, exhaustive on Route

Next.js has a guide for JSON-LD — structured data for search engines and
AI. They note the XSS risk (`JSON.stringify` doesn't escape `<`) and
recommend replacing `<` with `\u003c`. Our `Html` ADT already has a `Raw`
constructor with a comment mentioning JSON-LD, but we don't render any.

This is a SEO + AI win that's free (no JS, no FFI, no perf cost) and
type-safe (exhaustive on `Route`).

### The pattern

```purs
-- App.Layout.Head.purs (new)
-- | JSON-LD structured data for a route. Exhaustive on Route — each route
-- | type has its own schema. Returns Maybe because not every route has
-- | structured data (e.g., error pages don't).
renderJsonLd :: String -> Lang -> Route -> Maybe Html
renderJsonLd baseUrl lang route = case route of
  Home -> Just $ jsonLdScript
    [ Tuple "@context" "https://schema.org"
    , Tuple "@type" "WebSite"
    , Tuple "name" siteInfo.title
    , Tuple "url" baseUrl
    , Tuple "inLanguage" (langTag lang)
    ]
  PostList -> Just $ jsonLdScript
    [ Tuple "@context" "https://schema.org"
    , Tuple "@type" "Blog"
    , Tuple "name" siteInfo.title
    , Tuple "url" (baseUrl <> routeUrl lang PostList)
    ]
  PostDetail _ -> Just $ jsonLdScript
    -- In practice, this would take the post data and render BlogPosting
    -- with title, date, author. For the starter, a placeholder schema.
    [ Tuple "@context" "https://schema.org"
    , Tuple "@type" "BlogPosting"
    , Tuple "headline" "Blog Post"
    ]
  _ -> Nothing  -- About, Contact, Legal: no structured data

-- | Render a JSON-LD <script> tag with XSS-safe escaping.
-- | Replaces < with \u003c to prevent </script> injection.
jsonLdScript :: Array (Tuple String String) -> Html
jsonLdScript pairs =
  let
    json = "{"
      <> intercalate "," (map (\(Tuple k v) ->
          "\"" <> k <> "\":\"" <> escapeJson v <> "\"") pairs)
      <> "}"
  in
    el "script" [ attr "type" "application/ld+json" ] [ raw json ]

-- | Escape < as \u003c (the JSON-LD XSS fix from Next.js's guide).
-- | Also escapes " and \ for valid JSON strings.
escapeJson :: String -> String
escapeJson = replaceAll (Pattern "<") (Replacement "\\u003c")
  >>> replaceAll (Pattern "\"") (Replacement "\\\"")
  >>> replaceAll (Pattern "\\") (Replacement "\\\\")
```

`renderJsonLd` is called from `renderHead` — the structured data lands in
`<head>` on every page that has it. The `Raw` constructor is the escape
hatch; the `escapeJson` function is the XSS guard. No JS, no FFI, no
client-side rendering — the structured data is in the HTML source for
crawlers and AI agents to read.

### Why exhaustive on Route matters

Adding a `Route` constructor (e.g., `Team`) without adding a `renderJsonLd`
case is a compile error — *if* we don't use a wildcard catch-all. The
catch-all (`_ -> Nothing`) is intentional for routes that genuinely have no
structured data (About, Contact, Legal). But data-backed routes (PostList,
PostDetail) must have schemas. ContractSpec can assert this:

```purs
-- ContractSpec: data-backed routes have JSON-LD
test "PostList has JSON-LD" do
  let html = renderJsonLd "https://example.com" En PostList
  expect(html).toBeDefined()
```

## View Transitions — one CSS rule, no JS

Next.js has a full guide on View Transitions. The key insight for us:
`@view-transition { navigation: auto; }` is pure CSS — no JS. The browser
animates between page loads automatically.

Alpine AJAX already calls `document.startViewTransition` when available (I
verified this in the source). We just need to enable the CSS rule:

```css
/* css/input.css — one line */
@view-transition { navigation: auto; }
```

That's it. The browser handles the rest. For Alpine AJAX navigations
(fragment swaps), the transition is automatic. For full page loads, it
works in Chrome 126+ and Safari 18+. Firefox support is in progress.

No JS, no FFI, no ADR-000 conflict, no ContractSpec change. The biggest
free UX win in the guide.

## Invariants — what stays, what changes

| Invariant | Today (node:http) | After (Bun.serve) | Notes |
|---|---|---|---|
| Security headers on every response | `securityHeaders` in PS | `securityHeaders` in PS | Unchanged — PS sets them on the `Response` record |
| CSP byte-exact | ContractSpec assertion | ContractSpec assertion | Unchanged |
| Body cap (64KB) | `maxBodyChars` in PS + stream drop | `maxRequestBodySize` in Bun.serve + PS check | **Double defense** — Bun rejects oversize bodies before PS sees them |
| Body-read timeout (30s) | `raceTimeout` on `readBodyRaw` | `idleTimeout: 30` in Bun.serve + PS `raceTimeout` | **Double defense** — Bun kills idle conns at 30s; PS `raceTimeout` is the inner bound for active-but-stalled reads |
| Streaming timeout | N/A | Abort signal + chunked encoding (no `server.timeout`) | **Elysia pattern** — shell yields immediately (resets idle timer); abort signal closes stream on client disconnect. No per-request FFI call. |
| Cookie parsing | Manual `Cookie` header parsing | `req.cookies` (CookieMap) passed through FFI | **Ready for auth** — ADR-002 session cookies go through Bun's built-in CookieMap |
| Request-id correlation | `Ref` counter + `x-request-id` header | `Ref` counter + `x-request-id` header | Unchanged — PS owns the counter |
| Exception containment | `attempt` (handler) + `try` (sendResponse) | `attempt` (handler) + `.catch` in FFI `fetch` | **One error path** — no `error` option on Bun.serve (Elysia pattern); JS-side throws become a 500 Response |
| Path safety | `isUnsafePath` in PS | `openat2(RESOLVE_IN_ROOT)` on Linux via `{ dir }` routes | **Stronger** — kernel-level, not regex. `isUnsafePath` stays as defense-in-depth |
| Rate limiting | `App.RateLimit` in PS | `App.RateLimit` in PS | Unchanged |
| No FFI outside allowlist | Gate (empty allowlist) | Gate (`^src/App/ServerBun\.js` added) | **One allowlist entry** — the first real FFI in `src/` |
| Errors as values | `Either AppError` everywhere | `Either AppError` everywhere | Unchanged |
| Static file serving | `FS.readFile` per request (allocates Buffer, copies) | `Bun.file()` / `{ dir }` routes (zero-copy, kernel-level path safety) | **Major win** — closes deferred item #31 |
| Fragment detection | `x-alpine-request` header + `Vary` header | `?_frag=1` URL parameter | **Fixes prefetch** — same URL for hover and click |
| Hover prefetch | None (or manual, inconsistent) | `@mouseenter` in `spaLink` (centralized) | **Proven on spurs.icaro.fr** — one line, ADR-000-compatible |
| Viewport prefetch | None | `<link rel="prefetch">` from `prefetchFor` | **Type-safe** — exhaustive on `Route` ADT |
| HTTP/3 | N/A (node:http) | `http3: true` in Bun.serve (requires TLS) | **Free perf** on mobile (QUIC) — production feature |
| Compression | None | Gzip via `bun:zlib` (manual in FFI) | **Bandwidth win** — 70-80% size reduction for HTML. Brotli not available in `bun:zlib` |
| Loading states | None (blank `#content` while waiting) | `renderLoading` per route (exhaustive on `Route`) | **UX win** — skeleton appears instantly in the streaming shell |
| Error boundaries | Full-page error (layout replaced) | `renderErrorFragment` per route (layout stays) | **UX win** — streaming errors show in-place, not a blank 500 |
| Structured data | None | `renderJsonLd` per route (exhaustive on `Route`) | **SEO + AI win** — JSON-LD in `<head>`, XSS-escaped |
| View Transitions | None | `@view-transition { navigation: auto; }` (one CSS rule) | **UX win** — animated page transitions, no JS |

## ContractSpec updates

`test/ContractSpec.purs` currently asserts invariants by constructing
`Response` values and checking headers. Those assertions are unchanged —
they test the PS `Response` record, not the wire format.

Add seven new assertions:

1. **`ServerBun.js` is the only FFI module** — grep `src/` for `foreign
   import`, assert the only match is `App.Server.purs` importing from
   `App.ServerBun`. This makes the allowlist's "one entry" a test invariant,
   not just a Makefile check.

2. **Streaming responses have no `Vary` header** — with `?_frag=1` URL-based
   fragments, the Vary header is gone. Assert `StreamBody` responses don't
   carry `Vary`. (If someone reintroduces it, that's a bug.)

3. **Static pages never use `StreamBody`** — assert that `handleRoute` for
   `Home`/`About`/`Contact`/`Legal` returns `StringBody`. Streaming is for
   data-backed routes only; a static page that streams is a bug.

4. **`spaLink` includes `@mouseenter` prefetch** — grep `App.Alpine.purs`
   for `@mouseenter` in `spaLink`. If someone removes it, every navigation
   link loses hover prefetch.

5. **`prefetchFor` is exhaustive** — assert that `prefetchFor` has a case
   for every `Route` constructor. This is already a compile-time guarantee,
   but the test documents the intent and catches wildcard matches that
   would silently bypass the exhaustiveness check.

6. **Fragment URLs use `?_frag=1`** — assert `routeFragmentUrl` produces
   URLs ending in `?_frag=1`. If someone changes the convention, the
   server's fragment detection and the client's prefetch must change
   together — this test forces the coupling to be visible.

7. **`renderPrefetch` emits `<link rel="prefetch">`** — assert the HTML
   output contains `rel="prefetch"` tags with fragment URLs. If
   `renderPrefetch` is removed or broken, viewport prefetch silently
   disappears.

8. **`renderLoading` is exhaustive on data-backed routes** — assert that
   `PostList` and `PostDetail` produce non-empty loading skeletons. A
   data-backed route without a loading state means the user sees a blank
   `#content` while the stream is in flight.

9. **`renderErrorFragment` is exhaustive on data-backed routes** — assert
   that `PostList` and `PostDetail` produce non-empty error fragments. A
   data-backed route without an error fragment means a failed fetch shows
   nothing (the skeleton stays forever).

10. **JSON-LD is present on data-backed routes** — assert `renderJsonLd`
    returns `Just` for `PostList` and `PostDetail`. Structured data is
    part of the route's contract, not an afterthought.

### Error messages that teach the fix (the Next.js lesson)

Next.js's most impressive feature isn't a code feature — it's their error
*content design*. Their dev error messages include the exact fix, the
trade-offs between fixes, and a `Learn more` link to a per-error page
written *for agents to read*. The error message *is* the documentation.

Our ContractSpec assertions should do the same. A test failure should tell
the agent what to do, not just what's wrong. Examples:

```purs
-- Bad: "StreamBody without Vary header"
-- Good: teaches the fix
test "StreamBody responses must not carry Vary" do
  let msg = "StreamBody responses must not carry a Vary header. "
         <> "Fragment detection uses ?_frag=1 URLs (see ADR-007). "
         <> "If you reintroduced the header, remove it — the URL is the cache key."
  assertNoVaryOnStreamBody msg

-- Bad: "spaLink missing @mouseenter"
-- Good: teaches why it matters
test "spaLink includes hover prefetch" do
  let msg = "spaLink must include @mouseenter prefetch. "
         <> "Without it, every navigation link loses hover prefetch — "
         <> "the spurs.icaro.fr beta had this drift (header had it, "
         <> "buttons/pagination/footer didn't). See ADR-007."
  assertMouseEnterInSpaLink msg
```

The pattern: every ContractSpec assertion that can fail includes a message
that explains *why* the invariant exists and *how* to fix the violation.
The test failure is the documentation. An agent that breaks the test reads
the fix in the error output — no context switch, no doc lookup.

## Migration path

This is a single-PR migration. The blast radius is one server module + one
FFI file + PS modules for prefetch/fragments/loading/error/JSON-LD + one
ADR + ten ContractSpec assertions. No feature code changes. No route code
changes beyond the `?_frag=1` parsing. No test code changes (beyond
ContractSpec additions).

### Step 1 — Write the FFI binding + static file serving (no streaming yet)

`App.ServerBun.js` with `serveImpl` that:
- Calls `Bun.serve` with `routes` for static files (`/assets/*`, `/css/*`,
  `/images/*`, `/favicon.svg` via `Bun.file()` / `{ dir }`).
- Uses `fetch(req, server)` for everything else → PS router.

`App.Server.purs` rewrites `serve` to call `serveImpl` via `foreign import`.
`serveStatic` and `isUnsafePath` are removed from the hot path (kept for
ContractSpec). `App.Main.handleGet` drops its `serveStatic` fallback branch.
`StreamBody` doesn't exist yet — all responses are `StringBody`/`BinaryBody`.

**Verify:** `make check` passes. `make test/integration` passes (Venom
hits the same endpoints). `make test/e2e` passes (Playwright sees the same
HTML). `curl http://localhost:3001/css/styles.css` returns the CSS with
correct `Content-Type` and `ETag`. The server is functionally identical,
just on `Bun.serve` with zero-copy static serving.

### Step 2 — Switch to `?_frag=1` URL-based fragments

Add `routeFragmentUrl` to `Data/Route.purs`. Change `App.Main.handleRoute`
to check `Map.lookup "_frag" query` instead of
`Map.lookup alpineRequestHeader headers`. Remove the `Vary: alpine-request`
header from responses. Update `App.Alpine.spaLink` to use
`routeFragmentUrl` in `@mouseenter` prefetch.

**Verify:** `make check` passes. `make test/e2e` passes (Alpine AJAX
navigation still works — it now requests `?_frag=1` URLs). `curl
http://localhost:3001/en/posts?_frag=1` returns a fragment (no `<html>`,
no `<head>`). `curl http://localhost:3001/en/posts` returns a full page.

### Step 3 — Add `StreamBody` + loading states + error boundaries

Add the `StreamBody` constructor. Add `renderShell`, `renderLoading`, and
`renderErrorFragment` to `App.Layout.Page.purs` (all exhaustive on `Route`).
Add `streamResponse` to `App.Main.purs` for `PostList`/`PostDetail`. Static
pages stay on `StringBody`.

**Verify:** `make check` passes. Venom 04 (posts fixture) passes. Playwright
sees the same final HTML (streaming is transparent to the client). Manually
verify with `curl --no-buffer http://localhost:3001/en/posts` that the shell
+ skeleton arrives before the content. Manually verify that a failed fetch
(disconnect the API) shows the error fragment, not a blank page.

### Step 4 — Add `prefetchFor` + `<link rel="prefetch">`

Add `prefetchFor :: Route -> Array Route` to `Data/Route.purs` (exhaustive).
Add `renderPrefetch` to `App.Layout.Page.purs`. Call it from `renderPage` in
the `<head>`.

**Verify:** `make check` passes (exhaustiveness is a compile error if
missed). `curl http://localhost:3001/en` shows `<link rel="prefetch"
href="/en/posts?_frag=1">` in the `<head>`. DevTools Network tab shows
prefetch requests on page load.

### Step 5 — Add JSON-LD + View Transitions

Add `renderJsonLd` to `App.Layout.Head.purs` (exhaustive on `Route`,
XSS-escaped). Call it from `renderHead`. Add `@view-transition { navigation:
auto; }` to `css/input.css`.

**Verify:** `make check` passes. `curl http://localhost:3001/en/posts`
shows `<script type="application/ld+json">` in the `<head>`. `curl
http://localhost:3001/en` shows JSON-LD with `@type: WebSite`. View
Transitions work in Chrome (visual verification — page navigations animate).

### Step 6 — ContractSpec assertions + ADR-007

Add the ten new ContractSpec assertions (with error messages that teach
the fix). Write `ADR-007-bun-serve.md` recording the reversal: why the
`node:http` decision was right at the time, what changed (Bun commitment +
streaming SSR lesson + spurs.icaro.fr prefetch lessons + Next.js
loading/error/JSON-LD patterns), what we keep (invariants), what we gain
(streaming, prefetch, loading states, error boundaries, structured data,
view transitions, perf, simpler boundary).

**Verify:** `make check` passes. `make eval EVAL=04-add-ffi --check` passes
(the FFI eval now has a real FFI module to find).

### Step 7 — Update docs

- `docs/IMPROVEMENTS.md`: mark #31 (`Bun.file()` static serving) done —
  it's part of this migration. Mark #33 (`yoga-bun-yoga` evaluation)
  rejected — we're hand-rolling the one FFI file, not adopting a binding
  library. Mark the "Decided / won't do" `node:http` row as superseded by
  ADR-007.
- `docs/GUARANTEES.md`: clause 3 (FFI boundary) now has a real example
  instead of "empty allowlist by default."
- `AGENTS.md`: Safety Floor gains "FFI via `App.ServerBun.js` (allowlisted,
  ADR-007)".
- `docs/conventions/server.md`: update to reflect `Bun.serve` boundary +
  streaming pattern + `?_frag=1` fragments.
- `docs/conventions/alpine-contracts.md`: update to reflect `@mouseenter`
  prefetch in `spaLink` + `prefetchFor` exhaustiveness.

## `Bun.file()` static serving — included, not deferred

The original guide deferred this to #31. That was wrong. `Bun.file()` is the
single biggest static-serving win available, and it's a natural part of the
`Bun.serve` migration — not a separate effort.

### Why it's a clear win

Today `serveStatic` does `FS.readFile` per request: allocate a `Buffer`, read
the entire file into memory, copy it to the response. Every CSS, JS, image,
favicon — full read into memory, full copy.

`Bun.file()` is zero-copy: Bun serves directly from the file descriptor,
never materializing the file in JS memory. The `routes: { "/static/*": { dir } }`
option goes further — on Linux it uses `openat2(RESOLVE_IN_ROOT)` for
**kernel-level path safety**: symlinks that would escape `dir` are clamped by
the kernel, not by our `isUnsafePath` regex. That's a stronger guarantee than
we have today.

### How it fits the migration

The `routes` config in `Bun.serve` is a static route table declared at
server start. We use it for exactly one thing: static file serving. Not for
page routes, not for API endpoints — those stay in the PS router where
they're type-safe and tested.

```js
// App.ServerBun.js — routes for static files only
Bun.serve({
  port,
  routes: {
    "/assets/*": { dir: "./dist/assets" },
    "/css/*":    { dir: "./dist/css" },
    "/images/*": { dir: "./dist/images" },
    "/favicon.svg": Bun.file("./dist/favicon.svg"),
  },
  fetch(req, server) {
    // Everything else → PS router (pages, API, robots, sitemap, healthz)
    return onRequest(toPsRequest(req, server)).then(toWebResponse);
  },
  // ...
});
```

The PS `serveStatic` function and `isUnsafePath` are removed. Static file
serving is now Bun's job, with kernel-level path safety on Linux and
zero-copy serving everywhere. The PS router's `handleGet` drops its
`serveStatic` fallback branch — static files never reach `fetch`.

### What about `isUnsafePath`?

It stays as a ContractSpec assertion (the function exists, is tested) but is
no longer on the hot path. Defense in depth: Bun's `openat2` is the outer
wall, `isUnsafePath` is available if we ever need it for a non-Bun path.

### What about `Cache-Control` / `ETag` / `Last-Modified`?

`Bun.file()` and `{ dir }` routes set `Content-Type` (from extension),
`Last-Modified`, weak `ETag`, and support `Range` requests automatically.
Our current `fileResponse` sets `Cache-Control: public, max-age=3600` — that
header isn't set by Bun's static serving, so we add it via a small `fetch`
wrapper or accept the default (no `Cache-Control`, which means
`no-cache` heuristics). For a starter, the default is fine; fingerprinted
assets with long `max-age` is a future optimization.

## `routes:` — used for static, not for pages

`Bun.serve`'s `routes` can hold handler functions, not just static values.
We could put `/healthz`, `/robots.txt`, `/sitemap.xml` there. We don't, for
one reason: those endpoints are dynamic (`robots.txt` and `sitemap.xml`
depend on `cfg.baseUrl`), and putting them in `routes` means either
hardcoding `cfg.baseUrl` at server start (fragile) or writing handler logic
in JS (app logic in JS, banned by ADR-003). The PS router handles them in
three lines each, type-safely. Not worth the split.

The line is: `routes` for **static files** (no app logic, just file
serving), `fetch` for **everything else** (PS router, type-safe, tested).

## WebSocket — blocked by ADR-000, SSE is the path forward

`Bun.serve` supports WebSocket natively (`server.upgrade`, `websocket:
{ open, message, close }`). We don't use it. The reason is specific and
worth understanding, because it's not "we don't need it" — it's a
constraint that streaming SSR partially relaxes.

### Why WebSocket is blocked

ADR-000 bans custom browser JS. WebSocket requires a client-side
constructor (`new WebSocket(url)`) and event handlers (`onmessage`,
`onopen`). There's no Alpine attribute for that. Adding one means either:
- A new Alpine plugin (`alpine-websocket`) — a new `<script src>`, widening
  the CSP, adding a dependency. Possible but requires revisiting ADR-000.
- Inline JS — directly banned by ADR-000 and CSP.

So WebSocket is blocked at the ADR level, not the technical level. If
real-time features land (notifications, live updates, collaborative
editing), the first step is an ADR-000 revision, not a WebSocket
implementation.

### Why SSE is the compatible alternative

Server-Sent Events are HTTP responses with `Content-Type: text/event-stream`
and a streaming body. The browser API is `new EventSource(url)` — which is
also client JS, also blocked by ADR-000. BUT: SSE can be consumed by
Alpine via `x-data` + `fetch` + `ReadableStream` reading, or more simply,
the server can stream HTML fragments (our existing Alpine fragment pattern)
that swap into the DOM. That's not SSE per se — it's **streaming HTML**,
which is exactly what `StreamBody` gives us.

The path: streaming SSR (this guide) → streaming HTML fragments for
progressive enhancement → if true push is needed, revisit ADR-000 for
`EventSource` (simpler than WebSocket, unidirectional, fits MPA).

### What this means for the FFI

The `Bun.serve` options object in `App.ServerBun.js` does NOT include a
`websocket` handler. If we add one later, it's a new ADR (ADR-008 or
similar) that revisits ADR-000. The FFI file is structured so adding
`websocket` is a one-block addition, not a rewrite — but it's not there
today and shouldn't be.

## Tamed perf capabilities — what Bun.serve gives us for free

These are wins from `Bun.serve` that require minimal FFI work. Some are
one-liners; some need a few lines in the `toWebResponse` function.

### HTTP/3 (QUIC)

```js
// App.ServerBun.js — add to Bun.serve options (requires TLS)
Bun.serve({
  port,
  tls: { key: Bun.file("./key.pem"), cert: Bun.file("./cert.pem") },
  http3: true,
  // ...
});
```

HTTP/3 eliminates head-of-line blocking — a lost packet doesn't stall
subsequent requests on the same connection. On mobile (high packet loss),
this is a measurable win. Requires TLS certs, so it's a production feature,
not dev. The `http1: false` option can serve HTTP/3 only, but we keep
HTTP/1.1 as a fallback.

### Response compression (manual, not automatic)

Bun.serve does **not** auto-compress HTTP responses. The `compress` option
in the WebSocket config is for WebSocket messages, not HTTP. To compress
HTML responses, the FFI must do it explicitly in `toWebResponse`:

```js
import { gzipSync } from "bun:zlib";

function toWebResponse(psResp, acceptEncoding) {
  const headers = new Headers();
  for (const [k, v] of psResp.headers) headers.set(k, v);
  let body = psResp.body.value;  // StringBody / BinaryBody
  if (acceptEncoding?.includes("gzip") && typeof body === "string") {
    body = gzipSync(Buffer.from(body));
    headers.set("Content-Encoding", "gzip");
    headers.delete("Content-Length");  // recompute after compression
  }
  return new Response(body, { status: psResp.status, headers });
}
```

This is ~10 lines, not a one-liner. Worth it for HTML responses (70-80%
size reduction), but it's a conscious addition, not a free config flag.
Brotli would be even better but Bun doesn't expose `brotliCompressSync` in
`bun:zlib` — gzip is the available option. For a starter, gzip is fine.

### `server.pendingRequests` — free healthz metric

```js
// In the FFI, expose pendingRequests for the PS healthz handler
export function getPendingRequests(server) {
  return server.pendingRequests;
}
```

The PS `/healthz` handler can return `{"status":"ok","pending":N}` instead
of plain `"ok"`. Free operational visibility, no extra dependencies.

### `req.cookies` (CookieMap) — ready for auth

Bun's `BunRequest` has a built-in `CookieMap` with `.get(name)`,
`.set(name, value)`, `.toSetCookieHeaders()`. The FFI passes cookies through
to PS (see `toPsRequest` above). When auth lands (ADR-002), session cookie
reading and writing goes through this — no manual `Cookie` header parsing.
The `CookieMap` is iterable, so the FFI converts it to a plain object that
PS reads as `Map String String`.

**Elysia's choice, noted:** Elysia (`elysia/src/cookies.ts`) ignores
Bun's `req.cookies` and rolls its own cookie parser using the `cookie` npm
package. This suggests `CookieMap` may have limitations for complex use
cases (signed cookies, key rotation, custom serialization). For our simple
session-cookie use case (HMAC-signed, single value), `req.cookies` is
sufficient — we parse the raw value in PS and verify the HMAC there. If we
later need key rotation (see "Elysia lessons" below), we may revisit.

### `development` mode — dev-only error pages

```js
Bun.serve({
  development: process.env.NODE_ENV !== "production",
  // ...
});
```

In dev, Bun renders error pages with stack traces for uncaught throws. Our
`attempt` containment means this only fires for JS-side throws (in the FFI
itself), not PS-side errors. Still useful for debugging the FFI binding
during development. In production, it's off — our PS error pages handle
user-facing errors.

**Elysia's default:** Elysia sets `development: !isProduction`
(`elysia/src/adapter/bun/index.ts:362`) — same pattern. Confirmed as the
conventional default.

### `unix` socket — production behind a reverse proxy

```js
Bun.serve({
  unix: "/tmp/app.sock",
  // ...
});
```

Unix domain sockets are faster than TCP for localhost communication (no
TCP overhead, no port allocation). Useful when running behind nginx/Caddy
on the same host. Not relevant for dev, but worth documenting for
production deployment.

### `reusePort` — multi-process load balancing

```js
Bun.serve({
  reusePort: true,
  // ...
});
```

Allows multiple Bun processes to bind the same port. The kernel load-
balances across them. Elysia hardcodes this to `true`
(`elysia/src/adapter/bun/index.ts:364`); we do the same. Not relevant for a
starter (single process), but documented for future horizontal scaling.

### `server.reload()` — the Bun-native hot reload

Elysia (studied at `elysia/src/index.ts:8108-8112`) uses `server.reload()`
to hot-swap the request handler without dropping connections:

```js
server.reload({ ...serveOptions, fetch: newFetch });
```

The server stays up; only the `fetch` handler is replaced. This is the
Bun-native alternative to the `make dev-fast` wrapper script (which restarts
the process). After this migration lands, `make dev-fast` can use
`reloadImpl` instead of killing and restarting Bun — the HTTP server stays
alive, connections don't drop, and the reload is near-instant.

**Dev-loop shape (post-migration):**

```
spago build --watch  →  output/*.js changes
                     →  dev watcher detects change
                     →  calls reloadImpl(server, newOnRequest)
                     →  server picks up new handler, no restart
```

This is a future improvement to `make dev-fast` (#45), not part of the
migration itself. The migration adds the `reloadImpl` FFI export; the
dev-loop script wires it up separately.

### What is NOT available

- **No 103 Early Hints** — Bun.serve does not support sending preload hints
  before the response body. If we want this, it's a separate FFI effort
  (and may not be exposed in Bun's API at all). Removed from the earlier
  Tier 3 list.
- **No automatic Brotli** — `bun:zlib` exposes `gzipSync` but not
  `brotliCompressSync`. Gzip is the available compression.

## Elysia lessons — recorded for future work

Elysia (`elysia/`, v1.4.29, 48k LOC) was studied for Bun.serve patterns
(used in this guide above) and for framework-level patterns that inform
future work. The patterns below are **not part of this migration** — they're
cherry-pickable improvements tracked as backlog items. Recorded here so the
analysis isn't lost.

### What we adopted in this guide (already applied above)

- **No `error` option on `Bun.serve`.** Elysia catches inside `fetch`
  (`elysia/src/adapter/bun/index.ts:349-379`); we do the same.
- **`development: !isProduction`, `reusePort: true`, `idleTimeout: 30`.**
  Elysia's hardcoded defaults; we adopt them.
- **`server.reload()` for hot-swapping handlers.** Elysia pattern
  (`elysia/src/index.ts:8108-8112`); we expose `reloadImpl` in the FFI.
- **No `server.timeout(req, 0)` for streams.** Elysia relies on the abort
  signal + chunked encoding (`elysia/src/adapter/utils.ts:246-409`); we
  follow the same pattern, dropping the `disableTimeout` FFI export.

### What we did NOT adopt (TS/framework-specific)

- **AOT code-string compilation** (`elysia/src/compose.ts`, 2804 lines):
  Elysia compiles handler chains into strings and `new Function()`s them at
  runtime. Fundamentally incompatible with ADR-000 (no custom JS).
- **Template-literal path inference** (`elysia/src/types.ts`): TS type-level
  string parsing. We use `routing-duplex` at the value level — correct for PS.
- **TypeBox schema-as-values**: the concept is portable (validators as
  first-class values), but the library and TS type inference are not.
- **`sucrose.ts` static analysis**: infers which context fields a handler
  reads, for tree-shaking. Not applicable to PS.
- **WebSocket support**: blocked by ADR-000 (no custom browser JS).
- **Throw/catch error flow**: Elysia throws `NotFoundError`,
  `ValidationError`, etc. Our errors-as-values (`Either`) approach is safer
  and already in place. Elysia's error *shape* is useful (see below); its
  *control flow* is not.

### Cherry-pickable later (backlog items)

**HMAC cookie key rotation** (from `elysia/src/utils.ts:656-717`):
Elysia's cookie signing accepts `secrets: string[]` — an array of HMAC keys.
On verify, it tries each key in order (newest first). On sign, it uses the
first. This enables rotating session keys without invalidating all existing
sessions: add the new key at position 0, keep the old key at position 1,
remove the old key after all sessions have naturally expired. Our `App.Auth`
currently uses a single key. Adding `secrets :: Array String` (or `Maybe
(Array String)`) is a clean improvement. **Backlog: #55.**

**Separate `Parse` from `Validation` in `App.Error`** (from
`elysia/src/error.ts:26`): Elysia distinguishes `ParseError` (400 —
malformed input, bad JSON, unparseable body) from `ValidationError` (422 —
well-formed input that fails schema constraints). Our `App.Error` should
ensure the same separation: "your JSON was malformed" vs "your email is
invalid" are different error states with different status codes. **Backlog:
to verify in `App.Error` and add the distinction if missing.**

**Collect-all validation errors** (from `elysia/src/error.ts:490-531`):
Elysia's `ValidationError.all` gathers every field error and returns them
together — each with `path`, `message`, `summary`. This is better UX than
failing on the first field error: users see all problems at once. Our
`App.Form` should return `Either (NonEmptyList FieldError) Result` rather
than `Either String Result`. **Backlog: #54.**

**Production-safe error stripping** (from `elysia/src/error.ts:24`):
Elysia strips detailed error messages in production unless
`allowUnsafeValidationDetails` is true. Our `App.Error` renderer should do
the same: full detail in dev, generic messages in prod. **Backlog: to
verify in `App.Error` and add if missing.**

**Prototype pollution guards in form parsing** (from
`elysia/test/validator/body.test.ts:1617-1693`): Elysia explicitly strips
`__proto__` and `constructor` from nested multipart keys. If our form parser
builds objects from flat key names (e.g., `user.name` → `{ user: { name } }`),
we need the same guard. **Backlog: #56.**

**Direct handler testing** (from `elysia/test/utils.ts:1-67`): Elysia tests
use `app.handle(new Request(...))` without starting a server — faster than
Playwright for validation logic. Our PS tests can do the same: build a
`Request`, run it through the router handler, assert on the `Response`. This
complements (doesn't replace) our e2e tests. **Backlog: #57.**

## What this guide does NOT do

- **No `routes:` for page/API endpoints.** `routes` is for static files
  only. Page routes, API endpoints, i18n routing, rate limiting, form
  decoding — all stay in the PS router. Splitting routing across Bun's
  `routes` and PS's `router` would be the "two places" anti-pattern.
- **No custom router.min.js.** An earlier version of this guide proposed
  a ~150-line custom router plugin. The spurs.icaro.fr analysis proved it
  was over-engineering: `@mouseenter` prefetch is a one-line Alpine
  attribute, persistent cache is the browser HTTP cache (with `?_frag=1`
  URLs), and streaming swap saves ~10ms on fragments that are a few KB.
  We keep Alpine AJAX (9KB, pinned) and add one attribute to `spaLink`.
- **No WebSocket.** Blocked by ADR-000 (no custom browser JS). SSE /
  streaming HTML is the compatible path; WebSocket needs an ADR-000
  revision first.
- **No HTML imports / bundler integration.** `Bun.serve` can serve bundled
  HTML/JS/CSS via `import index from "./index.html"`. We have Spago +
  Tailwind for that. Not relevant to an SSR MPA.
- **No Speculation Rules API (yet).** `<script type="speculationrules">`
  is declarative (JSON, not executable) and could give us prerender without
  a client router. It's the one Tier-4 feature that might be ADR-000-
  compatible. Needs investigation: does CSP `script-src` block it? If not,
  it's a free addition. Tracked as a follow-up, not part of this migration.
- **No 103 Early Hints.** Bun.serve does not support this. Removed from
  earlier drafts of this guide. If it becomes available, it would let us
  send `<link rel="preload">` before the streaming body starts.
- **No automatic Brotli.** `bun:zlib` exposes `gzipSync` but not
  `brotliCompressSync`. Gzip is the available compression. Brotli would
  need a tamed FFI to a native library — not worth it for a starter.

## Risks and honest tradeoffs

**Risk: new security-critical code.** The `node:http` decision called this
out and it's still true. Mitigation: the FFI file is ~80 lines, auditable,
and the ContractSpec + gate enforce its shape. The attack surface is
*smaller* than `node:http`'s compat layer (which is thousands of lines of
JS we don't control).

**Risk: streaming errors can't change status codes.** True and fundamental.
Mitigation: streaming is opt-in per route, only for data-backed pages, and
the shell includes an Alpine fallback. Non-streaming routes keep exact
status codes. This is the same tradeoff Next.js makes.

**Risk: `Bun.serve` API changes.** Bun is 1.4.0 (vendored) / 1.3.14
(deployed). The `fetch(req, server)` API has been stable since Bun 1.0.
Mitigation: pin the deployed Bun version (already done in Dockerfile) and
re-verify on upgrade (already tracked as #32).

**Risk: double-defense redundancy.** `maxRequestBodySize` + `maxBodyChars`,
`idleTimeout` + `bodyReadTimeout`. This is intentional, not waste — defense
in depth. The Bun-side bounds are the outer wall; the PS-side bounds are the
inner wall. If one is misconfigured, the other holds.

**Tradeoff: we lose Node portability.** True. We already lost it (Aug 2026
decision). This guide makes it concrete in code instead of just in docs.

## Success criteria

1. `make check` passes (gate + build + test + format).
2. `make test/integration` passes (Venom 01-05).
3. `make test/e2e` passes (Playwright).
4. `curl --no-buffer http://localhost:3001/en/posts` shows the shell
   + skeleton arriving before the post list (streaming + loading state).
5. `make eval EVAL=04-add-ffi --check` passes (FFI eval finds the real
   binding).
6. ContractSpec passes with the ten new assertions.
7. No feature code changed (only `App.Server.purs`, `App.Main.purs`
   streaming branch + `?_frag=1` parsing + `serveStatic` removal,
   `App.ServerBun.js`, `App.Layout.Page` shell + loading + error + prefetch,
   `App.Layout.Head` JSON-LD, `App.Alpine` `spaLink`, `Data.Route`
   `routeFragmentUrl` + `prefetchFor`, `css/input.css` view transitions).
8. `curl -I http://localhost:3001/css/styles.css` shows `ETag` and
   `Last-Modified` headers (Bun.file static serving is active).
9. `curl -I http://localhost:3001/assets/js/alpinejs.min.js` shows
   `Content-Type: application/javascript` (MIME detection works).
10. `curl http://localhost:3001/en` shows `<link rel="prefetch"
    href="/en/posts?_frag=1">` in the `<head>` (viewport prefetch active).
11. `curl http://localhost:3001/en/posts?_frag=1` returns a fragment (no
    `<html>`, no `<head>`) — URL-based fragment detection works.
12. DevTools Network tab: hovering a nav link triggers a `fetch` to the
    `?_frag=1` URL; clicking it is a cache hit (hover prefetch works).
13. `curl http://localhost:3001/en/posts` shows `<script
    type="application/ld+json">` with `@type: Blog` in the `<head>`
    (JSON-LD structured data present).
14. `curl http://localhost:3001/en` shows `<script
    type="application/ld+json">` with `@type: WebSite` in the `<head>`.
15. Disconnect the posts API and `curl --no-buffer
    http://localhost:3001/en/posts` shows the error fragment streaming
    into `#content` (error boundary works, layout stays intact).
16. Chrome DevTools: navigating between pages shows a smooth view
    transition (View Transitions CSS works).
