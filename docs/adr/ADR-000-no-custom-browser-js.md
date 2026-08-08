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
