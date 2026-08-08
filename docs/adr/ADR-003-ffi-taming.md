# ADR-003: Taming JS libraries via FFI — pattern and rules

**Status:** Accepted
**Date:** 2026-08

## Context

PureScript's native ecosystem is thin; npm's is vast — and we run 100% on
Bun, whose native API surface (`Bun.password`, `Bun.file`, `bun:sqlite`,
`Bun.sql`) is itself a taming target. Uncontrolled FFI would erode every
guarantee in `docs/GUARANTEES.md`. Controlled FFI is how we get the JS
ecosystem's coverage without giving up compulsory strictness.

## Decision

All FFI follows `docs/ffi-taming-guide.md`:

1. **Target priority:** PS-first library → Node built-in → Bun-native (when
   it offers something Node doesn't) → npm package.
2. The `.purs` signature is the contract; the `.js` side calls library
   functions and returns primitives/plain objects. **No app logic in JS.**
   (Exception: `streamResponseImpl` in `ServerBun.js` orchestrates the
   `ReadableStream` lifecycle, including fetching data and calling PS render
   callbacks, because the Bun `ReadableStream` API requires the producer logic
   to run inside the JS `start` callback).
3. Decode at the boundary (`Foreign` / `open-foreign-generic`); return
   `Aff (Either AppError a)`. Never throw across the boundary.
4. `FFI_ALLOWLIST_GREP` entry (gate-enforced) + an ADR per tamed library.

## Consequences

- The gate fails any `foreign import` outside the allowlist.
- `docs/GUARANTEES.md` clause 3 scopes the runtime-safety claim: it covers
  PureScript code + allowlisted boundaries with decoders.
- One tamed module that skips decoding voids the claim — the recipe is
  mandatory, not advisory.
