# ADR-015: Migrate from Alpine + Alpine AJAX to Datastar

**Status:** Accepted
**Date:** 2026-09-09
**Supersedes:** ADR-011 (Alpine AJAX frozen transport)
**Amends:** ADR-000 (client seam tiers, CSP threat model)

## Context

ADR-011 froze Alpine + Alpine AJAX as the bedrock transport (2026-08-30) after
evaluating Alpine, HTMX 4, and Datastar, and explicitly rejected Datastar for
shell navigation — its own docs recommend plain `<a>` links over
`pushState`-based navigation, and it has no history API at all.

That rejection was correct on the facts available at the time, but rested on
estimated bundle sizes and an untested hypothesis about how much custom glue
Datastar's missing history support would actually cost. Branch
`spike/datastar-shell-nav-port` (`.scratch/datastar-streaming-transport/`)
replaced that estimate with a real, measured spike: a side-by-side toggle
(`?ds=1`) porting Home + About's full shell-nav, theme/language dropdowns, and
mobile drawer to Datastar, gated behind a mechanical "no raw Datastar strings
outside `App.Datastar`" rule mirroring Alpine's own constructor-seam gate.

### What the spike measured, not estimated

| Metric | Alpine + Alpine AJAX (ADR-011) | Datastar |
|---|---:|---|
| Client bundle (gzip) | 20,437 B (`alpinejs.min.js` 16,704 B + `alpine-ajax.min.js` 3,733 B) | 12,374 B (single file) — confirmed via network trace: zero Alpine scripts loaded on the Datastar path |
| Reduction | — | 8,063 B / 39.5% |
| Shell-nav parity | baseline | Forward nav, back/forward, theme dropdown, language dropdown, mobile drawer, scroll-to-top — all verified via live `playwright-core`, not just unit assertions |
| CSP | `script-src 'nonce-…' 'self' 'unsafe-eval' 'strict-dynamic'` | Same policy, zero violations (verified via `securitypolicyviolation` event listener through the full interaction sequence) — no widening needed |
| Custom JS required | `pageSyncScript` (title/lang sync + `popstate` restore), 993 B raw / 536 B gzip | `dsShellRouterScript` (same job, since Datastar has no history support either), ~1.3 KB raw — comparable cost, not a new category of cost ADR-011 didn't already pay |

The spike found and fixed three real bugs invisible to `spago build`/`make
gate`/`make test` (an ES-module script loaded as a classic `<script>`, a
PureScript string-escaping bug that broke the shell-router's SSE-terminator
parsing, and a missing `Vary` header that let the browser's own HTTP cache
serve a stale full document to a patch request) — see `findings.md` for the
full account. All three are the class of bug a spike is supposed to surface,
and none are fundamental to Datastar itself.

### Why the ADR-011 rejection doesn't hold up

ADR-011's stated reasons for keeping Alpine, checked against the spike:

1. *"HTMX convention familiarity does not justify +12 KB"* — not about
   Datastar, unaffected.
2. *"Datastar rejected — no history API, SSE-first server contract,
   philosophy opposes shell partial navigation."* The no-history-API fact is
   true and unavoidable — the spike didn't get around it, it paid for it with
   `dsShellRouterScript`. But ADR-011 treated that gap as disqualifying
   without pricing it: Alpine's own transport pays the *identical* cost
   (`pageSyncScript` already exists for the same reason — Alpine AJAX's own
   `x-target.push` doesn't sync title/lang or handle scroll restoration
   either). Once priced, the gap is a wash, not a blocker.
3. The SSE-first server contract is real but was never a cost — Datastar's
   `datastar-patch-elements` framing is a thin wrapper (`event: …\ndata:
   elements <html>\n\n`) around the exact same rendered HTML Alpine's fragment
   path already produced.

## Decision

### Adopt Datastar as the bedrock transport layer; delete Alpine entirely

| Layer | Owner | Convention |
|---|---|---|
| Shell navigation | `App.Datastar.dsNavGet` / `dsNavLinkRecord` / `dsSpaLink` | Internal links → `dsSpaLink`/`dsNavLinkRecord`; language switch → `dsLangLink` (chrome only) |
| Local UI | `App.Datastar` (`DsFlag`, theme, menus) | All chrome through typed builders |
| Glue (owned) | `dsShellRouterScript` (`App.Layout.Scripts`), `datastar-request` detection | Documented in `docs/conventions/datastar-contracts.md`; tested in ContractSpec + e2e |
| Server response | `isDatastarRequest` / `Server.sseEventResponse` | `datastar-request: true` header only (no query-param fallback — see below); `Vary: datastar-request` |

Unlike ADR-011's decision to keep both stacks side by side pending a spike
criterion, this decision **removes Alpine entirely** rather than running two
transports: `App.Alpine.purs` and `App.Ui.Templates.SiteShell.purs` are
deleted, not deprecated, and every consumer (chrome, `App.Ui.Button`,
`App.Ui.Templates.ActionLink`, `App.Ui.Breadcrumbs`) is ported. Running both
stacks indefinitely would mean two client bundles, two attribute-name gates,
and two things to keep in sync for every future chrome change — a real and
growing tax with no page left that needs the old one.

### Client runtime (pinned, self-hosted)

| Script | Role |
|---|---|
| `datastar.js` (pinned to commit SHA, not a moving `@main` ref — see below) | Reactive attributes + shell-nav SSE actions |

**Pinning by commit SHA, not a branch ref:** during the spike, two fetches of
the "same" `v1.0.0-RC.7`-labeled build from jsdelivr's `@main` provider
produced different byte content and checksums. `Makefile`'s `assets`/
`assets-check` targets fetch `cdn.jsdelivr.net/gh/starfederation/datastar@<commit-sha>/…`
and verify against `static/assets/SHA256SUMS` — a floating ref is not safe to
redeploy from.

### Interactivity tiers (amended)

| Tier | Tool |
|---|---|
| 0 | CSS-native (`<details>`, `:focus-within`) in `App.Ui` |
| 1 | `App.Datastar` — menus, theme, modals, dismiss |
| 2 | `App.Datastar.dsSpaLink`/`dsNavLinkRecord` — shell navigation |
| 3 | `HeadScript` ADT — `DarkModeInit`, `DevLiveReload`, `DsShellRouter` |
| 4 | Server — forms, mutations (POST → redirect or full/patch page) |
| 5 | island runtime — ADR-010 (proposed, do not implement) |

### A protocol constraint this migration inherits, not chooses

Every Datastar patch response — including error content (a 404/500 page
rendered into `#content`) — is HTTP status **200**, never the real status
code. Confirmed against the vendored `datastar.js` source: the client only
applies an SSE patch when `status === 200`; 300-399 is treated as a redirect
branch and 400-599 as an error branch, neither of which parses or applies the
patch body at all. Returning the real 404/500 status would mean Datastar
*refuses to render* the styled error content into `#content` — the opposite
of what `routeMiss404`/`failureDatastarPatch` are for. This is a genuine,
deliberate difference from Alpine AJAX's fragment path, which carried the
real status code on every response, including errors. Operational
consequence: an access-log or uptime-monitor analysis keyed on HTTP status
will not see a 404/500 for a failed Datastar-driven navigation — only the
rendered content shows it. `e2e/error-fragment.spec.js` pins this exact
behavior so a future "fix" doesn't reintroduce the real status code and
silently break error rendering instead.

### A capability this migration does not preserve

ADR-007 valued `?_frag=1` as "a header-free way to request a fragment (curl,
integration tests, non-header clients)". Datastar's own protocol has no
query-param convention for this, and inventing one would be adding behavior
Datastar itself doesn't have. A header-free patch request is no longer
supported — see `docs/conventions/server.md`. Nothing in this codebase's own
test suite or tooling needed it (confirmed: no test relied on a header-free
fragment fetch), but it is a real, disclosed capability loss for an external
consumer that might have depended on it.

## ADR-000 amendment: the CSP threat-model story for Datastar

ADR-000's addendum argued Alpine's `Expr` (abstract, constructor not
exported) and `Flag` (closed sum type) close the injection vector
`unsafe-eval` would otherwise amplify — **by construction, not convention** —
because every expression-producing function funneled through one opaque
type.

Datastar's port does **not** carry an equivalent single unifying type. What
it does have:

- `dsSetTheme`, `dsShowTheme`, `dsClassWhenTheme` take `App.Theme.ThemeMode`
  (closed sum type) — an invalid theme is a compile error, matching Alpine's
  closure for this case exactly.
- `dsShowFlag`, `dsShowNotFlag`, `dsToggleFlag`, `dsSetFlag`, `dsClassWhenFlag`
  take `App.Datastar.DsFlag` (closed sum type) — same property, for flags.
- `dsNavGet`, `dsSpaLink`, `dsNavLinkRecord`, `dsLangLink`, `dsPrefetchHover`,
  `dsOnClickOutside`, `dsOnKeydownEscape` build their expression strings from
  typed `Route`/`Lang` values and fixed literals. No call site anywhere in
  `src/` passes a caller-supplied free-form `String` into one of these — but
  the *type signatures* don't forbid it the way an abstract `Expr` would.

**This is a real, narrower guarantee than Alpine's**, and `docs/GUARANTEES.md`
clause 12a is worded to reflect exactly that (closed for `ThemeMode`/`DsFlag`
builders; closed by absence-of-user-data for the rest, not by an equivalent
type-level wrapper). Closing the gap fully would mean introducing a Datastar
equivalent of `Expr` — deferred rather than done here, because every current
call site is already closed in practice and no user-influenced data reaches
any of these constructors; see ADR-014 for the standing pattern of deferring
speculative hardening until a concrete need exists.

`unsafe-eval` remains required for the same underlying reason ADR-000 named
for Alpine: Datastar evaluates attribute expressions via `new Function()`.

## Consequences

### Gains

- 12,374 B gzip client bundle — a measured 39.5% reduction from Alpine +
  Alpine AJAX's 20,437 B, not a projection
- Zero CSP changes — same nonce-based policy, verified violation-free
- Full behavioral parity on the two ported pages (Home, About), verified live
- One client bundle and one attribute-name gate instead of two, going forward
- `App.Ui.Button`/`ActionLink`/`Breadcrumbs` — content-level, not just
  chrome-level, primitives — now share the same seam as shell nav

### Accepted costs

- `dsShellRouterScript` — the same category of owned popstate/title-sync glue
  ADR-011 already accepted for Alpine (`pageSyncScript`), now Datastar's
  responsibility instead
- No header-free patch-request fallback (see above) — a real, disclosed
  capability loss with no current consumer
- **Hover-prefetch cache-hit — initially lost, then resolved twice.** Alpine AJAX's
  `prefetchHover`/`spaLink` fetched the identical plain URL on hover and
  click. The first Datastar port lost this because `@get()` appends
  `?datastar=`. Mirroring `JSON.stringify($)` onto the hover URL restored the
  click hit but made the cache key the live chrome store (open menus, theme).
  **Current contract (2026-09-09):** chrome signals are `_`-prefixed (Datastar
  omits them from GET by default); `@get(url, {payload: {}})` and
  `dsPrefetchHover` both send `?datastar={}`; popstate does the same.
  Successful patches are `private, max-age=180` with a `wyhash`-based ETag
  (a cache validator needs collision avoidance, not cryptographic
  strength — `sha256Hex` stays reserved for security-sensitive hashing).
  `e2e/prefetch-cache.spec.js` pins the click-from-cache and If-None-Match 304.
- `App.Datastar`'s security closure is narrower than Alpine's `Expr`
  abstraction was (see ADR-000 amendment above) — accepted because every
  current call site is already closed in practice, revisited if a future
  constructor needs to accept caller-influenced string data

### Rejected alternatives

| Alternative | Why rejected |
|---|---|
| Keep Alpine, run Datastar only where a future feature needs its differentiator | Two client bundles and two attribute-name gates indefinitely, for a differentiator (live/streamed multi-target updates) no current page uses — same objection ADR-011 raised against premature HTMX adoption, now pointed at premature Alpine retention instead |
| Introduce a Datastar `Expr`-equivalent abstract type now | No current call site needs it (no user-influenced data reaches any constructor) — speculative hardening ADR-014's standing pattern defers until a concrete need exists |
| Replicate `?_frag=1`'s header-free fragment request for Datastar | Datastar's own protocol has no such convention; inventing one adds behavior the library doesn't have for a capability nothing in this codebase currently exercises |

## Related

- `.scratch/datastar-streaming-transport/spec.md`, `findings.md`,
  `code-review.md` — the spike's spec, measured results, and review history
- [`docs/conventions/datastar-contracts.md`](../conventions/datastar-contracts.md) — typed constructor seam (supersedes `alpine-contracts.md`)
- [`docs/adr/ADR-000-no-custom-browser-js.md`](ADR-000-no-custom-browser-js.md) — amended above
- [`docs/adr/ADR-007-bun-serve.md`](ADR-007-bun-serve.md) — fragment/patch protocol origin
- [`docs/adr/ADR-010-browser-island-integration.md`](ADR-010-browser-island-integration.md) — proposed island runtime (do not implement); still not what this migration is
