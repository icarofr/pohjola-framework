# Datastar shell-nav port spike

**Status:** ready-for-agent

**Relationship to ticket 01** (`issues/01-adopt-datastar-as-live-transport-with-readablestream.md`):
that ticket is a *different* scenario — Datastar as one bounded, complementary
live-update island alongside an unchanged Alpine AJAX, for a feature that
doesn't exist yet. This spec is the *full-replacement* scenario — Datastar
taking over Alpine AJAX's shell-nav job **and** Alpine core's local-UI job
entirely, evaluated as an isolated spike. The two are not in conflict and
should not be merged into one ticket: ticket 01's complement path is cheap and
narrow; this spec's replacement path is what actually reduces bundle size, at
a much larger cost. Read both before acting on either.

## Problem Statement

Pohjola's client transport (Alpine core + Alpine AJAX, ~20.0 KB gzip
combined) works today, but the maintainer wants to know, with real evidence
rather than speculation, whether replacing it with Datastar (a smaller,
SSE-native hypermedia engine) would actually reduce the bundle and whether
full behavioral parity — shell navigation, browser back/forward, title/lang
sync, scroll-to-top, the theme and language dropdowns — is achievable on top
of Datastar's primitives, none of which provide shell navigation with
history out of the box. Nobody has built this; every number discussed so far
is either measured on the *current* stack or bounded by proxy (Pohjola's own
existing glue size, the full Alpine AJAX plugin's size), not measured on a
real port.

## Solution

Build a throwaway, branch-isolated port of two representative pages —
`Home` (Landing template) and `About` (Editorial template) — from Alpine +
Alpine AJAX onto Datastar (free/core tier only, no Pro features), covering
both shell navigation and local UI (theme dropdown, language dropdown,
mobile drawer). Keep the server's existing fragment-detection contract
(`isFragmentRequest`, `x-alpine-request` header / `?_frag=1`) completely
intact; add a Datastar-SSE-framed response encoding as an *additional* path,
never a replacement, so the current Alpine-based pages on the same branch
keep working unmodified as a live comparison baseline. Measure the real
gzip bundle delta from an actual `make build`, and verify full behavioral
parity against the current Alpine-based versions of the same two pages,
before any decision is made about a production migration.

## User Stories

1. As the maintainer, I want this work confined to a disposable git branch
   with zero changes to `master`, so exploring it carries no production risk.
2. As the maintainer, I want `Home` and `About` specifically ported (not all
   four pages), so the spike is bounded and timeboxed while still covering
   both current page templates (Landing, Editorial) Pohjola has in the tree.
3. As the maintainer, I want the existing `isFragmentRequest` /
   `x-alpine-request` / `?_frag=1` contract left untouched, so the spike
   doesn't risk breaking fragment detection for pages that stay on Alpine.
4. As the maintainer, I want a new response encoding path that wraps a
   fragment in Datastar's `datastar-patch-elements` SSE framing, so
   Datastar's client can consume what the server already renders without
   duplicating the render logic.
5. As the maintainer, I want the SSE response encoded via a real Bun
   `ReadableStream`, so Datastar's client receives properly-framed
   `datastar-patch-elements` events. **(Amended post-implementation:** the
   existing `App.Server.streamResponse`/`App.ServerBun.streamResponseImpl`
   turned out hardcoded for a different, incompatible choreography — the old
   Posts-era "shell now, fetch external JSON later" flow, not a generic
   string-to-`ReadableStream` primitive — so they remain at zero call sites.
   A new, minimal, purpose-built `sseEventStreamImpl`/`sseEventResponse` pair
   was added instead, inside the already-allowlisted `App.ServerBun` module
   — no new FFI module, no ADR-003 trigger. See Implementation Decisions.)
6. As the maintainer, I want a new `App.Datastar` PureScript module — typed
   constructors only, no raw attribute strings at call sites — mirroring
   `App.Alpine`'s shape, so the spike doesn't undermine judging Datastar's
   viability with sloppy code quality of its own.
7. As the maintainer, I want a mechanical gate rule (`no raw Datastar
   strings outside App.Datastar`) added alongside the new module, mirroring
   the existing `no raw Alpine strings outside App.Alpine` rule, so the
   spike is held to the same discipline as production code even though it's
   throwaway.
8. As the maintainer, I want forward navigation (clicking an internal link)
   to swap `#content` and update the URL exactly like Alpine AJAX does
   today, so shell nav has full parity, not an approximation.
9. As the maintainer, I want browser back/forward to correctly restore the
   previous page's content, title, and language attribute, matching the
   current `restore()`/`popstate` behavior in `App.Layout.Scripts`, so
   history isn't degraded.
10. As the maintainer, I want the page to scroll to top on every navigation
    (forward and restore), matching this session's existing scroll-to-top
    fix, so that regression doesn't quietly reappear on the new transport.
11. As the maintainer, I want the document title and `<html lang>` to sync
    correctly after every swap, matching current `TitleSync` behavior, so
    accessibility and tab-title correctness aren't lost.
12. As the maintainer, I want the theme dropdown (Light/Dark/System) reimplemented
    with Datastar signals instead of Alpine's `x-data`/`x-show`, with the
    same open/close-on-outside-click/close-on-escape/active-item-highlight
    behavior, so local UI parity is real, not partial.
13. As the maintainer, I want the language dropdown reimplemented the same
    way, with the same behavior, so both disclosures stay in parity with
    each other the way `dropdownTriggerClass`/`dropdownPanelClass` keep them
    today.
14. As the maintainer, I want the mobile drawer (hamburger menu, close
    button, Escape-to-close) reimplemented the same way, so mobile parity
    isn't skipped.
15. As the maintainer, I want a real, measured gzip bundle-size diff from an
    actual `make build` on this branch, so the estimated range from
    conversation (a −22% to −38% reduction, bounded between Pohjola's own
    536 B popstate glue and the full 3,733 B Alpine AJAX plugin, against a
    measured 12,202 B Datastar core) is confirmed or corrected against real
    output, not left as an estimate.
16. As the maintainer, I want the current Content-Security-Policy checked
    against Datastar's actual runtime requirements (expression evaluation
    likely needs `unsafe-eval`, the same reason Alpine needs it today), so
    a silent CSP violation isn't discovered only after a production decision.
17. As a future reader of this spec (human or agent), I want the findings
    (bundle delta, parity checklist results, CSP findings, and a clear
    go/no-go recommendation) written up in one place, so the spike's value
    survives past the branch being deleted or kept dormant.
18. As the maintainer, I want the spike to use only Datastar's free/core
    tier, no Pro attributes (`data-persist`, `data-replace-url`, etc.), so
    the licensing profile of this comparison matches the fully open-source
    stack Pohjola runs everywhere else, and the measured numbers aren't
    contingent on a paid dependency.

## Implementation Decisions

- **Branch**: a new, disposable branch off `master` (e.g.
  `spike/datastar-shell-nav-port`); no merge to `master` follows from this
  spec — that is a separate decision made after the findings are in.
- **Vendoring**: Datastar is self-hosted and checksummed the same way
  `alpinejs.min.js`/`alpine-ajax.min.js` are today (`static/assets/js/`),
  free/core build only.
- **New module**: `App.Datastar`, structurally parallel to `App.Alpine` —
  typed constructors for whatever signal/patch/show/class-binding
  vocabulary the ported pages actually need. Not a 1:1 reimplementation of
  every `App.Alpine` function; only the subset exercised by `Home`/`About`'s
  shell nav and the three local-UI widgets in scope.
- **Gate rule**: extend `Policy.Contract`'s scan set with a `no raw Datastar
  strings outside App.Datastar` rule, following the same pattern as the
  existing Alpine rule, scoped to whatever files this spike touches.
- **Server-side encoding**: a new response-building path (parallel to, not
  replacing, the existing fragment path) that wraps `#content`'s rendered
  HTML in a `datastar-patch-elements` SSE event when the incoming request is
  a Datastar action call. Detection of "this is a Datastar request" is a new,
  separate signal from `x-alpine-request`/`?_frag=1` — the two must not be
  conflated, since pages remaining on Alpine still rely on the original
  contract exercising unmodified paths.
- **`ReadableStream` reuse (amended — the assumption below did not hold):**
  the plan was to build this encoding path on the existing
  `App.Server.streamResponse`/`App.ServerBun.streamResponseImpl`, avoiding
  new FFI entirely. On inspection during implementation, that pair is
  hardcoded for the old Posts-era "shell now, fetch external JSON later"
  choreography (`streamResponseImpl(url)(onContent)(shellOpen)(shellClose)`),
  not a generic string-to-`ReadableStream` primitive — it doesn't fit a
  one-shot SSE event. Built instead: a new `sseEventStreamImpl :: String ->
  Effect ReadableStream` + `sseEventResponse`, inside the same
  already-allowlisted `App.ServerBun` module (no new FFI module, no ADR-003
  trigger — extending an allowlisted module's internal surface, not adding a
  fifth one). `streamResponse`/`streamResponseImpl` remain at zero call
  sites, unchanged by this spike.
- **Client-side shell router**: hand-written glue on top of Datastar's
  `@get` action and patch mechanism — Datastar does not provide
  `pushState`/`popstate`-based navigation itself (its own documentation
  points toward plain `<a>` navigation instead). The glue's shape follows
  Pohjola's own existing `pageSyncScript` `restore()` logic in
  `App.Layout.Scripts` as its starting reference: intercept internal link
  clicks, trigger the Datastar action, on a successful patch call
  `history.pushState`, and wire a `popstate` listener that re-triggers the
  same fetch-and-patch path for back/forward.
- **Local UI port**: `App.Datastar` gains the equivalent of `App.Alpine`'s
  `Flag`/`ThemeMode`/dropdown-trigger/dropdown-panel constructors, emitting
  Datastar's signal/attribute vocabulary instead of Alpine's `x-data`/
  `x-show`. Visual DaisyUI classes (`dropdownTriggerClass`,
  `dropdownPanelClass`, etc.) are unchanged — only the reactivity attributes
  swap, not the CSS.
- **Pages in scope**: `Home` and `About` only, on the spike branch, with
  their existing Alpine-based rendering left in place as the comparison
  baseline (i.e., the branch should be able to render both an Alpine version
  and a Datastar version to compare, rather than a one-way rewrite with
  nothing to diff against).
- **Licensing constraint**: Datastar free/core tier only; no Pro attributes
  or tooling.

## Testing Decisions

Two seams, both reusing what Pohjola already has for this class of module
rather than inventing a third:

- **Unit seam**: PureScript string-assertion tests on `App.Datastar`'s
  rendered constructor output, following the exact pattern
  `test/ContractSpec.purs` and `test/ShellSpec.purs` already use for
  `App.Alpine` (assert the constructor emits the expected attribute string).
  Tests only the module's own output shape — good tests here assert
  external behavior (what markup a constructor produces for a given input),
  not internal Datastar plumbing.
- **E2e seam**: a spike-local raw-`playwright-core` script (not added to the
  production `e2e/*.spec.js` suite, since this branch is throwaway) that
  drives the real built site and checks, for both the Alpine version and the
  Datastar version of `Home`/`About`: forward nav swap, `popstate`
  restore, title/lang sync, scroll-to-top, theme dropdown (open/close/
  active-item highlight/outside-click/Escape), language dropdown (same),
  and mobile drawer (open/close/Escape). This is the same verification
  method (raw `playwright-core`, not `make test/e2e`) already established
  as this session's practice and as `AGENTS.md`'s Verify section requires
  for chrome changes.
- **Bundle measurement**: run the branch's actual `make build`, inspect the
  real gzip size of whatever ships under `dist/assets/js/`, and record it
  against the conversation's estimated range (12,738–15,935 B) rather than
  trust the estimate.
- **CSP check**: load the Datastar-powered pages with the current pinned CSP
  and record whether anything is blocked (expression evaluation in
  particular) — a finding to report, not a new CSP policy to design as part
  of this spike.

## Out of Scope

- Merging anything to `master` — a separate decision after this spike's
  findings are in.
- `ADR-010`'s browser-islands proposal (imperative third-party library
  lifecycle — maps, canvas, audio) — unrelated; Datastar doesn't solve that
  problem, and this spike doesn't touch it.
- Ticket 01's scenario (Datastar as a complementary live-update island
  alongside unmodified Alpine AJAX) — a different, separately-tracked
  question with its own ticket.
- `Guarantees` and `Docs` pages (Hub and Notice templates) — only `Home`
  (Landing) and `About` (Editorial) are in scope for this spike.
- Datastar Pro features and tooling (`data-persist`, `data-replace-url`,
  the bundler/inspector) — free/core only.
- Finalizing a new CSP policy — only checking whether the current one holds.
- Rewriting `ContractSpec`/`ShellSpec`/the production e2e suite to assert
  Datastar attributes — those stay exactly as they are, asserting Alpine's
  output, since `master`'s pages remain on Alpine throughout this spike.

## Further Notes

Real, measured numbers already established, to anchor the spike's own
measurements against:

| Component | Gzip size (measured) |
|---|---|
| `alpinejs.min.js` (Alpine core) | 16,704 B |
| `alpine-ajax.min.js` (shell-nav plugin) | 3,733 B |
| **Current total** | **20,437 B** |
| Datastar v1.0.0-RC.7 (free/core, fetched from `cdn.jsdelivr.net`) | 12,202 B |
| Pohjola's own current popstate/title-sync glue (`pageSyncScript`, the *half* of shell-nav Alpine AJAX doesn't need to be ported for) | 536 B |

Estimated range for Datastar + a ported shell-nav glue layer (the scenario
this spike tests): **12,738–15,935 B**, i.e. a **22–38% reduction** versus
today — bounded by the two real reference points above, not a guess. This
spike's job is to replace that estimate with a real number.

`ADR-011`'s spike criterion (in-page hypermedia beyond shell nav — multi-target
updates, partial re-renders) is a *different* trigger from this spec's
question (bundle size and behavioral parity for a full transport swap).
Both are real, both are documented, and neither has fired yet as of this
writing.
