## Step 1 — Choose the target (priority order)

1. **PS-first library** — use it.
2. **Node built-in** (`node:crypto`, `node:fs`) — portable across Node + Bun.
3. **Bun-native — when it offers something Node doesn't.** Verified in the
   vendored Bun 1.4.0 source: `Bun.password` (native argon2), `Bun.file`
   (zero-copy serving), `bun:sqlite`, `Bun.sql`. We deploy 100% Bun, so
   direct Bun-native calls are acceptable. A `typeof Bun !== "undefined"`
   dispatch with a Node fallback remains cheap insurance for anything that
   might also run in Node-based tooling.
4. **npm package** — vet it (below).

## Vetting criteria (npm packages)

- Battle-tested, maintained, good security track record
- Stable API (no monthly breaking churn)
- Small dependency tree (supply-chain surface)
- Does one thing well — **no frameworks** (you'd be wrapping a paradigm)
- Function-call API (not configuration-heavy, not middleware chains)

Good candidates: `@node-rs/argon2`, `jose`, `@sentry/node`, `prom-client`.
Bad candidates: `express`, `next` (paradigms), `lodash` (PS has arrays —
FFI is for capabilities PS lacks, never convenience).

## Step 2 — Write the `.js` binding

- Call library functions; return primitives or plain objects.
- **No app logic in JS**: no `if` about behaviour, no decisions. The PS side
  decides. If the JS file contains branching about what the app should do,
  the boundary is in the wrong place.
- **Callback currying rule** — PS `Effect a` is runtime-represented as
  `() -> a`. A callback passed from PS (e.g. `makeAff`'s `Either e a -> Effect Unit`)
  returns an `Effect Unit` **thunk** that must be applied to `()` to execute.
  In JS: `onSuccess(result)()` — double application. Single application
  (`onSuccess(result)`) returns the thunk without running it; `makeAff` never
  resolves and the fiber hangs silently. This bug is invisible — no error,
  no crash, just a hang. Reference: `App.Bun.js` `readTextFileImpl`,
  `App.Data.SQL.js` `queryImpl`/`executeImpl`/`closeImpl`.
- Stateful shapes:
  - **Stateless function** (hash, sign): export a plain function.
  - **Configured instance** (logger, Sentry): init once with config, export
    functions closing over the instance; the PS side holds an opaque handle
    (`Foreign`, never decoded — just passed back).
  - **Long-lived resource** (db pool): same, plus a `close`/`dispose`
    function; lifecycle managed on the PS side (bracket-style).
- **Push-based APIs** (streams, sockets, events): out of scope for this
  recipe. Prefer request/response. If genuinely needed, write a new ADR first.

## Step 3 — Write the `.purs` boundary

- The typed signature is the contract.
- JS returning primitives → import directly.
- JS returning objects → `Effect Foreign` + decode (`purescript-foreign`,
  or `open-foreign-generic` for derived decoders).
- Every function returns `Aff (Either AppError a)` (or `Effect (Either …)`).
  **Never throw across the boundary.** Add an `AppError` variant if needed —
  the compiler will enumerate every handler.
- Template: `docs/examples/Crypto.purs` + `Crypto.js`.

## Step 4 — Register

- Add the module to `FFI_ALLOWLIST_GREP` in the Makefile.
- Write `docs/adr/ADR-00N`: why this library, what's bounded, what state it
  holds, why not the alternatives.

## Step 5 — Test

- Unit-test the decoder: malformed JS objects are rejected (`Left`), valid
  ones accepted.
- Integration-test the behaviour (does `hashPassword` actually verify?).

## Boundary discipline

- Keep app logic on the PS side. The `.js` file calls library functions and
  returns primitives or plain objects — branching about app behaviour means
  the boundary is in the wrong place.
- Decode at the boundary, always. TS types do not exist at runtime; a typed
  TS library still returns untyped JS to PureScript. Decode anyway.
- Use Promise/Aff boundaries for async. Passing callbacks into JS couples
  lifecycle to the JS side — return a Promise and bridge with `Aff`.
- One interface, one module. Dispatch inside the binding or pick one runtime
  per ADR — parallel `App.X.Bun` / `App.X.Node` modules split one contract
  across two files.
- Reserve FFI for capabilities PS lacks (crypto, native APIs, streaming).
  Date formatting, string helpers, and array utilities belong in
  PureScript.
