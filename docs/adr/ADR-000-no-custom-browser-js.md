# ADR-000: No custom browser JavaScript — Alpine.js only, pinned and self-hosted

**Status:** Accepted
**Date:** 2026-08

## Context

The app is an SSR MPA. Interactivity (nav swaps, dark mode, mobile menu)
needs client-side behaviour, but a JS build pipeline and ad-hoc scripts erode
the "compiler is the contract" guarantee: anything written in raw JS is
invisible to the PureScript type system and to the gate.

## Decision

1. **Browser JS: banned.** No `<script src>` beyond the two pinned,
   self-hosted Alpine assets (integrity-verified via
   `static/assets/SHA256SUMS`). No inline `<script>` beyond the two head
   snippets (dark-mode init; title-sync + popstate). All interactivity is
   expressed as Alpine attributes in the Html ADT.
2. **Server JS app-logic: banned.** All server logic is PureScript.
3. **Server JS via FFI: allowed** — but only through the taming recipe
   (ADR-003 / `docs/ffi-taming-guide.md`): allowlisted, decoded at the
   boundary, ADR'd per library. The FFI is a thin binding to a library,
   never app logic.

## Consequences

- CSP `script-src 'self' 'unsafe-inline' 'unsafe-eval'` is pinned by
  ContractSpec; widening it fails a test that demands justification.
- ContractSpec asserts rendered pages never reference external `src="http…"`.
- The gate bans `foreign import` outside `FFI_ALLOWLIST_GREP`.
- If a behaviour can't be expressed in Alpine attributes, it moves to the
  server — it does not become a script tag.

## Addendum: CSP threat model and nonce-based tightening (2026-08)

### Threat model

The primary XSS defense is **upstream**, not CSP:

1. The `Html` ADT escapes all text via `Bun.escapeHTML` (SIMD, 5 metacharacters).
2. The unsafe HTML constructor is gate-banned outside 6 allowlisted modules.
3. ContractSpec property-tests that rendered text never contains unescaped
   `<`/`>` (guarantee #16).
4. No user-generated HTML content. No `x-html` usage.

CSP is **defense-in-depth** for future developer mistakes, not the load-bearing
wall. The residual vectors CSP mitigates:

- **Vector A:** an unsafe-HTML call inside an allowlisted module passing
  user-influenced data (currently all static, but not structurally prevented).
- **Vector B:** user data flowing into an Alpine constructor argument
  (currently doesn't happen, but `xData :: String -> Attr` accepts anything).

### Why `unsafe-eval` remains

Alpine's standard build evaluates attribute expressions via `new Function()`,
which requires `unsafe-eval`. The Alpine CSP build (`@alpinejs/csp`) removes
this requirement but **cannot call global functions** — `fetch`, `console.log`,
`Math.max`, etc. are unsupported. Our `prefetchHover` constructor emits
`fetch($el.href, {headers: {...}})`, which the CSP build cannot evaluate
inline. Switching would require moving that logic to an `Alpine.data()`
component in a nonced `<script>` block — a permanent custom-JS seam that
violates this ADR's no-custom-browser-JS rule. The vector `unsafe-eval`
amplifies (Vector B) is already closed by the absence of user data in Alpine
constructor arguments. Switching to the CSP build is dogma-driven
over-engineering for this threat model.

### Why `unsafe-inline` was dropped

`unsafe-inline` was needed for exactly two static `<script>` snippets in
`<head>` (dark-mode init, title-sync/popstate) and the JSON-LD script. It is
**not** needed for Alpine's `@click`/`x-data` attributes — those are custom
attributes read via `MutationObserver`, not inline event handlers in the CSP
sense. Per-request nonces (18 random bytes → base64, generated via Web Crypto
in `App.ServerBun.js`) are injected into these script tags at serve time, and
the CSP uses `script-src 'nonce-<random>' 'self' 'unsafe-eval' 'strict-dynamic'`.
This closes the inline-script variant of Vector A (an injected `<script>`
without the nonce is blocked) without breaking Alpine or violating ADR-000.

### Implementation

- `App.ServerBun.js`: `generateNonce()` FFI (Web Crypto, 18 bytes → base64).
- `App.Server`: `cspWithNonce` builds the per-request CSP; `withCsp` injects
  it; `replaceNonce` replaces the `__CSP_NONCE__` placeholder in rendered HTML.
- `App.Layout.Head`: `cspNoncePlaceholder` constant; all script tags use it.
- `App.Layout.Page`: all render functions embed the placeholder; `App.Main`
  replaces it for the streaming path (StringBody replacement happens in
  `serve`).
- The static page cache stores nonce-agnostic HTML (with the placeholder);
  replacement happens per-request at serve time, so cached pages get fresh
  nonces.
- The JS-side 500-fallback CSP (in `App.ServerBun.js`) drops `unsafe-inline`
  too — it's `text/plain` so no scripts execute regardless.
