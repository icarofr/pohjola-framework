# HTMX 4 migration plan (deferred)

**ADR:** [ADR-011](../adr/ADR-011-alpine-ajax-frozen-transport.md) — **not active**; execute only when spike criterion fires  
**Status:** Deferred planning artifact — Alpine + Alpine AJAX is bedrock per ADR-011  
**Exit criterion (if ever executed):** `make check` green + CI all jobs green

---

## Summary

| From | To |
|---|---|
| Alpine AJAX 0.12.7 (transport) | **HTMX 4.0.0** (transport) |
| Alpine.js 3.15.12 (local UI) | **Alpine.js kept** (local UI — shrink `App.Alpine`) |
| `spaLink` / `x-target.push` | `App.Htmx.shellLink` / `hx-history-elt` |
| `x-alpine-request` + `?_frag=1` | `HX-Request` + `HX-Request-Type` + `?_frag=1` |
| `TitleSync` + `x-sync` | `hx-history-elt` + `hx-alpine-compat` |
| Inlined CSS (`embed-css.js`) | `<link href="/css/styles.css">` |
| CSP `unsafe-eval` | hx-csp + Alpine CSP build (spike) |
| — | `hx-alpine-compat` + SW (static CacheFirst) |

**Do NOT ship:** `alpine-ajax.min.js`, `hx-live.min.js` (conflicts with Alpine).

**Agent rules (frozen):**

- `App.Htmx.shellLink` — internal navigation
- `App.Alpine` — menus, theme, modals, `navLink` for language (Header only)
- `App.Htmx` hx-post/hx-get — in-page hypermedia (forms, tabs, search regions)

---

## Phase 0 — Prep (no behaviour change)

**Goal:** Pin assets, scaffold modules, CI still red on Alpine until Phase 6.

| Task | Files |
|---|---|
| Copy HTMX 4.0.0 dist from `research/htmx/dist/` to `static/assets/js/` | `htmx.min.js`, `ext/hx-preload.min.js`, `ext/hx-csp.min.js`, `ext/hx-alpine-compat.min.js`, `ext/hx-history-cache.min.js` — **not hx-live** |
| Spike `@alpinejs/csp` build vs standard + hx-csp | document in research note |
| Regenerate `static/assets/SHA256SUMS` | `Makefile` `assets-check` |
| Replace Makefile `assets` target: add HTMX, **drop alpine-ajax curl**, keep alpinejs | `Makefile` |
| Scaffold `src/App/Htmx.purs`, `src/App/Hypermedia.purs` | new modules |
| Scaffold `docs/conventions/browser-contracts.md` | docs |
| Add migration branch metadata if needed | — |

**Verify:** `make assets-check` passes (new hashes). Alpine CSP spike documented.

---

## Phase 1 — External CSS

**Goal:** Stop inlining CSS; linked stylesheet in `<head>`.

| Task | Files |
|---|---|
| Remove `embed-css.js` call from `make css` | `Makefile` |
| Delete or gut `src/App/Layout/Styles.purs` | stop generating inlined string |
| `Head.purs`: `<link rel="stylesheet" href="/css/styles.css">` | remove `<style>` with `stylesCss` |
| `Page.purs`: remove inline `<style>` from error paths | `renderErrorPage`, streaming shell |
| Ensure `make build` copies `dist/css/styles.css` → `dist/css/` | already in `build` target |
| Update `e2e/assets.spec.js` if it asserts inline style | assets spec |

**Verify:** `make build && make run` — pages styled via `/css/styles.css`. Venom `css returns 200` still passes.

---

## Phase 2 — `App.Htmx` + layout shell (keep `App.Alpine`)

**Goal:** Add transport seam + `#shell`; Alpine stays for local UI.

### 2a. `App.Htmx` module (transport only)

| Constructor | Role |
|---|---|
| `shellLink` | Replaces `spaLink` — hx-get, hx-target, hx-push-url, hx-preload, hx-nonce |
| `hxGet` / `hxPost` / `hxTarget` / `hxSwap` | In-page hypermedia |
| `withHxNonce` | Stamp hx-nonce on hx attributes |
| `shellId`, `contentTarget` | Layout constants |

**Do not move** `Flag`, `Expr`, `xShowFlag`, `onClickOutside`, theme helpers — they stay in `App.Alpine`.

### 2b. Shrink `App.Alpine`

| Remove | Keep |
|---|---|
| `spaLink`, `xTargetPush`, `prefetchHover`, `prefetchExpr` | `Flag`, `Expr`, all x-data/x-show/theme/outside/escape builders |
| `alpineRequestHeader`, `contentTarget` (move to App.Htmx) | `navLink` (lang/external — no hx attrs) |
| `xSync` | — |

### 2c. Layout shell

| Task | Files |
|---|---|
| Wrap header+main+footer in `<div id="shell" hx-history-elt>` | `Page.purs` |
| `renderShell` replaces `renderFragment` | `Page.purs`, `Main.purs` |
| Remove `x-sync` from `Header.purs` — compat handles re-init | Header |
| Load `hx-alpine-compat.min.js` before Alpine in `<head>` | Head, Page |

### 2d. Head scripts

| Task | Files |
|---|---|
| **Delete** `HeadScript.TitleSync` (popstate fetch) | `Scripts.purs` |
| Optional: tiny `HtmxTitleSync` — `htmx:after:swap` reads `data-page-title` | only if HTMX doesn't update title from shell response |
| Keep `DarkModeInit`, `DevLiveReload` | Scripts.purs |

**Verify:** `spago build`. Manual: shell swap re-inits Alpine dropdowns via compat.

---

## Phase 3 — Server hypermedia + CSP

| Task | Files |
|---|---|
| `App.Hypermedia.detectMode :: RequestHeaders -> Query -> HypermediaMode` | `Hypermedia.purs` |
| Replace `isFragmentRequest` / `alpineRequestHeader` | `Main.purs`, `Server.purs` |
| `Vary: HX-Request` | `Main.purs` `varyHeader` |
| `handleShell` / `renderShell` on `ShellSwap` + `IntegrationShell` | `Main.purs` |
| History restore → full `renderPage` | `Main.purs` |
| Drop `unsafe-eval` from `cspWithNonce` | `Server.purs`, `ServerBun.js` fallback CSP |
| Error shell on 404/500 when `ShellSwap` | `Main.purs`, `Page.purs` |

**Verify:** Manual `curl -H 'HX-Request: true' -H 'HX-Request-Type: partial' /en/about` returns shell HTML without `<!DOCTYPE`.

---

## Phase 4 — Cutover (burn Alpine AJAX, keep Alpine)

| Task | Files |
|---|---|
| **Delete** `static/assets/js/alpine-ajax.min.js` only | assets |
| **Keep** `alpinejs.min.js` (or swap to CSP build) | assets |
| Split imports: `shellLink` from `App.Htmx`; menus/theme from `App.Alpine` | see file list |
| `Page.purs`: HTMX + compat + Alpine in `<head>`; remove body scripts | Page, Head |
| `Button.purs`: `spaLink` → `shellLink` from `App.Htmx` | Button, PostCard, Footer, features |
| Header/Footer/Modal/Tabs/Toast/Accordion: keep `App.Alpine` | UI |
| Remove `x-cloak` only if Alpine still needs it (keep for now) | Head.purs |
| Update marketing copy | I18n, Content |

### Import split (both modules)

```
App.Htmx:  Button, PostCard, Footer, Page, Main, features (nav links)
App.Alpine: Header, Modal, Tabs, Toast, Accordion, Header lang navLink
Both:      ContractSpec (separate describe blocks)
```

**Verify:** `make gate` — `attr "hx-"` only in `App.Htmx`; `attr "x-"` / `attr "@"` only in `App.Alpine`.

---

## Phase 5 — Service worker

| Task | Files |
|---|---|
| `static/sw.js` — CacheFirst static, NetworkOnly HTML | static |
| `HeadScript.ServiceWorkerRegister` | `Scripts.purs` |
| Serve `/sw.js` from Bun (`ServerBun.js` or static route) | server |
| Build step: inject asset manifest into SW precache list | `Makefile` or `scripts/build-sw.js` |
| Optional Phase 5b: `src/Worker/Main.purs` + `WORKER_FFI_ALLOWLIST` | ADR + Makefile |

**Verify:** E2E `e2e/sw-cache.spec.js` (new) — second navigation serves CSS from SW (0 transfer).

---

## Phase 6 — Tests & docs (must pass for merge)

### 6a. `test/ContractSpec.purs` — rewrite blocks

| Old describe block | New |
|---|---|
| `Alpine seam — contentTarget` | `Htmx seam — shell and contentTarget` — assert `#shell[hx-history-elt]`, `#content` |
| `Alpine seam — data-page-title` | keep — still on `#content` |
| `Alpine seam — attribute literals` | `Htmx seam — attribute literals` — scan for raw `hx-`, ban outside `App.Htmx` |
| `nav links carry x-target.push` | `shellLink carries hx-get, hx-target, hx-push-url, hx-preload, hx-nonce` |
| `fragment responses are fragment-shaped` | `shell responses are shell-shaped` — `#shell` children, no `<!DOCTYPE` |
| `spaLink @mouseenter prefetch` | `shellLink hx-preload` |
| `CSP exact value` | remove `'unsafe-eval'` from pinned string |
| `generated expressions (ADR-000 Vector B)` | **keep** `App.Alpine.Expr`; add `App.Htmx` only if hx-on builders needed |
| `no raw Alpine outside App.Alpine` | **keep** + add `no raw HTMX outside App.Htmx` |
| `findRawAlpineOutsideAlpine` | keep + `findRawHtmxOutsideHtmx` |

### 6b. E2E — `e2e/navigation.spec.js`

| Test | Change |
|---|---|
| `header#header[x-sync]` | `div#shell[hx-history-elt]`; header inside **without** x-sync |
| `scriptCount: 2` (body Alpine) | htmx + preload + csp + compat + alpine in `<head>` |
| marker preserved on nav | same — HTMX shell swap must not full reload |
| `goBack` / `goForward` | same — via `hx-history-elt`; may need `hx-history-cache` for zero-network back |
| hover prefetch | `hx-preload` on mousedown — intercept `HX-Request` not `x-alpine-request` |
| fragment shell children | shell inner: header + main (footer optional); no `x-sync` |

### 6c. E2E — `e2e/prefetch-cache.spec.js`

| Test | Change |
|---|---|
| `Vary: x-alpine-request` | `Vary: HX-Request` |
| fragment signal matrix | `HX-Request: true` + partial vs `?_frag=1` vs neither |
| `x-sync` in shell body | remove — hx-alpine-compat handles re-init |
| click cache provenance (CDP) | **Re-measure** against hx-preload semantics — HTMX may differ from Alpine hover+cache; document new expected behaviour in test header comment |
| self-prefetch guard | `shellLink` omits preload when `target == current` |

### 6d. E2E — other specs

| File | Change |
|---|---|
| `e2e/error-fragment.spec.js` | `HX-Request` header; shell shape on 500 |
| `e2e/theme.spec.js` | "AJAX nav" → "shell nav"; hx-live selectors if needed |
| `e2e/assets.spec.js` | htmx assets not alpine; external CSS link |
| `e2e/forms.spec.js` | hx-post if forms use HTMX (or unchanged if plain POST) |

### 6e. Venom — `venom/01_routes.yml`

```yaml
# Replace:
- name: GET /en with X-Alpine-Request returns fragment
# With:
- name: GET /en with HX-Request returns shell
  headers: { HX-Request: "true" }  # + note: may need HX-Request-Type in integration
```

Add case for `?_frag=1` shell response.

### 6f. Evals — `evals/evals/08-browser-island/check.sh`

```bash
# Both seams required
grep -rn 'App.Htmx' src/App/Features/
grep -rn 'App.Alpine' src/App/Layout/Header.purs
! grep -rn 'alpine-ajax' static/
! grep -rn 'hx-live' static/
```

### 6g. Docs & agent guides

| File | Action |
|---|---|
| `docs/adr/ADR-000-no-custom-browser-js.md` | Amend — HTMX + HeadScript, no Alpine |
| `docs/adr/ADR-007-bun-serve.md` | Amend — shell protocol, HX headers, SW, external CSS |
| `docs/adr/ADR-010-browser-island-integration.md` | Amend — `App.Htmx` tier 4 islands |
| `docs/conventions/alpine-contracts.md` | **Delete** → `browser-contracts.md` |
| `docs/GUARANTEES.md` | Clauses 11–12: HTMX, no unsafe-eval |
| `docs/conventions/server.md` | Shell detection, cache policy for shell responses |
| `AGENTS.md` / `CLAUDE.md` | Task→doc map, architecture blurb |
| `README.md` | Stack description |
| `scripts/auto-scaffold.js` | `App.Htmx`, `shellLink` |
| `Makefile` header comment | PureScript + HTMX 4 |

### 6h. Makefile gate additions

```makefile
# Ban js: prefix in hx attributes (hx-csp unsafe pattern)
@if grep -rn 'js:' src/ | grep -vE '^src/App/Htmx.purs:'; then exit 1; fi

# Ban Alpine remnants
@if grep -rnE 'x-alpine|alpinejs|App\.Alpine' src/ test/ e2e/; then exit 1; fi
```

---

## Phase 7 — Polish (post-merge, not blocking)

| Task | Notes |
|---|---|
| `@view-transition { navigation: auto }` in CSS | Myth 4 |
| Content-hashed CSS filename | `styles.[hash].css` |
| PureScript service worker | `App.Worker` |
| `hx-history-cache` tuning | instant back |
| Tier 0 CSS pass on Header menus | reduce hx-live surface |
| Datastar spike (ADR-010 tier 4) | separate track |

---

## CI checklist (all must pass)

| Job | Command | What it catches |
|---|---|---|
| **Build** | `make ci-equivalent` | gate, generator-policy, build, test, assets-check, format |
| **Unit** | `bun x spago build --pure && bun test` | ContractSpec, property tests, CSP string |
| **Integration** | `make test/integration` | Venom routes, shell headers |
| **E2E** | `make build && bun run test:e2e` | navigation, prefetch, theme, forms, assets, errors |

### ContractSpec critical assertions (post-migration)

- [ ] CSP pinned **without** `unsafe-eval`
- [ ] `#shell` + `hx-history-elt` on every full page
- [ ] `#content` + `data-page-title` on every full page
- [ ] No raw `hx-*` outside `App.Htmx`; no raw `x-`/`@` outside `App.Alpine`
- [ ] `hx-alpine-compat.min.js` loaded before Alpine
- [ ] `shellLink` renders `hx-get`, `hx-target`, `hx-push-url`, `hx-preload`, `hx-nonce`
- [ ] Shell response: no `<!DOCTYPE`, contains `#header` + `#content`
- [ ] Full page response: `<!DOCTYPE`, `<html`, no shell-only shape
- [ ] `HX-Request` / `?_frag=1` matrix pinned
- [ ] `Vary: HX-Request` on HTML responses
- [ ] `htmlCacheControl` still `private, max-age=10` for success pages
- [ ] Error responses still `no-store`
- [ ] FFI 500 fallback CSP unchanged

### E2E critical behaviours (post-migration)

- [ ] Internal click: URL updates, content swaps, **no full reload** (marker test)
- [ ] Back/forward: correct page content + title
- [ ] Language switch: **full reload** (marker cleared)
- [ ] Theme persists across shell nav
- [ ] Theme persists across full reload
- [ ] hx-preload fires before click (network evidence)
- [ ] 404 shell request returns shell-shaped error, not full document
- [ ] `/css/styles.css` loads with validator (etag)
- [ ] HTMX scripts in head, not body

---

## Execution order (single PR vs stacked)

**Recommended: one migration PR** — Phases 0–6 atomic. Partial states (HTMX without burning Alpine) confuse tests.

```text
Day 1: Phases 0–1 (assets, external CSS)
Day 2: Phases 2–4 (App.Htmx, server, burn Alpine)
Day 3: Phase 5 (SW) + Phase 6 (tests/docs)
Day 4: make check + CI green + manual smoke
```

**Before merge:** `make check` locally. All four CI jobs green.

---

## Rollback

Revert single migration commit. Restore `SHA256SUMS`, Alpine assets via `make assets`, `git checkout` pre-migration `Styles.purs` from embed-css if needed.

---

## Open questions (resolve during Phase 0 spike)

1. **Alpine CSP build:** `@alpinejs/csp` drop-in for `alpinejs.min.js` — verify theme/menu expressions compile.
2. **Title on shell swap:** HTMX native vs minimal `HtmxTitleSync` HeadScript reading `data-page-title`.
3. **hx-preload + cache:** Re-run CDP prefetch-cache test; pin policy if HTMX mousedown preload differs from Alpine hover.
4. **hx-history-cache:** Enable in Phase 2 or 7 for instant back with Alpine state restore via compat.
5. **Forms:** Plain POST default; `hx-post` only where in-page swap is required.
