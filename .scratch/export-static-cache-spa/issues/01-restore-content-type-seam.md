Type: task
Status: resolved

## Question

`App.Layout.Scripts.dsShellRouterScript`'s `restore()` (the popstate handler) hardcoded the assumption that every response is SSE-framed (`"data: elements "` marker), which is only true on the live server. A static export's response to the exact same request is the prerendered document itself (confirmed via `App.Cli.ExportStatic`'s own module doc on how forward-nav already handles this for `@get()`). How should `restore()` handle both shapes correctly?

## Blocked by

None (can start immediately)

## Answer

First attempt (wrong, caught before shipping): "if the marker isn't found, treat the whole body as the document." This is wrong because the exported page's own `<script>` tag — present inline on every exported page — contains the literal string `"data: elements "` as part of its own source code (the `var marker='data: elements '` line). A naive `indexOf` search over the full HTML document finds *that* occurrence, not real SSE framing, and corrupts the parse (verified directly: a real static-export response had `marker index: 659855` — a false positive deep in the page's own inlined script, producing an 848-byte garbage slice that correctly failed the `#content` lookup and silently fell back to `location.reload()`, defeating the whole fix).

Real fix: branch on `Content-Type` instead. The live server always tags its SSE patch responses `text/event-stream` (`App.Server.sseEventResponseMatching`); a static host serves `text/html`. This is the same signal Datastar's own client already uses to distinguish response shapes (per `ExportStatic`'s own doc comment on `@get()`'s text/html branch), so it isn't a new convention, just applying the existing one to the hand-rolled popstate path too.

Verified with real browser automation (raw `playwright-core`, Chromium), not just compilation:
- **Static export** (served via Python's `http.server`, a genuinely dumb host with no Cache-Control/ETag at all — not Pohjola's own Bun server): 2 forward clicks + 2 backs + 1 forward, `loads` counter stayed at 1 throughout (confirmed via a `page.on('load', ...)` listener), a `window`-level marker survived every step (proving no real reload ever happened), and the final visible `<h1>` content was correct after the round-trip.
- **Live server** (same test sequence against `make run`): identical result — no regression in the original, already-working path.
- The existing e2e-covered 304 fallback (`e2e/navigation.spec.js`: "popstate restore of HTTP 304 falls back to a full document load") is untouched by this change — the `!r.ok` throw it depends on happens before the new Content-Type branch.

`make gate` (23/23), `make test` (246/246 + pick-port), `make format-check`, `make assets-check` all green.
