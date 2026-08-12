# Guarantees

**The claim: if it compiles and CI is green, production doesn't crash.**

Not "no runtime errors" in the absolute — this stack contains effects, FFI
boundaries, and a JavaScript runtime. The claim is scoped, and every clause is
enforced by a check you can run. If a guarantee below ever breaks, a named
check fails loudly — on every push, in CI.

## The guarantee table

| # | Guarantee | Enforced by | Verify with |
|---|-----------|-------------|-------------|
| 1 | No partial functions — `fromJust`, `Data.Maybe.Unsafe`, `Data.Array.Unsafe`, `Data.String.CodePoint.Unsafe` cannot appear in `src/` | Makefile gate | `make gate` |
| 2 | No `unsafeCoerce` / `unsafePerformEffect` / `unsafePartial` | Makefile gate | `make gate` |
| 3 | No unapproved FFI — `foreign import` in `src/` fails the build unless the module is allowlisted (default: none) | Makefile gate (`FFI_ALLOWLIST_GREP`) | `make gate` |
| 4 | No general-purpose unescaped HTML constructor — the `Html` ADT has no `raw`/`Raw` escape hatch; script/style and JSON-LD contexts are explicit | Makefile gate + ContractSpec (filesystem scan) | `make gate`, `spago test` |
| 5 | Every handler failure is a typed value — `Aff (Either AppError a)` at every boundary | Compiler (types) + convention | `spago build` |
| 6 | Exhaustive pattern matching — adding a route, i18n key, or error variant breaks the build until every site is updated | Compiler | `spago build` |
| 7 | Bilingual completeness — `en` and `fr` share one record type; a missing key in either is a compile error | Compiler | `spago build` |
| 8 | Runtime exceptions (socket errors, JS failures) are contained at one boundary, logged, and answered with a 500 — never a process crash | `attempt` in `App.Server` + `makeFetch` try/catch in `App.ServerBun` | `spago test` |
| 9 | No hung requests — `idleTimeout: 30` closes connections with unresolved handler Promises; `makeFetch` catches synchronous throws in the callback bridge; stream `controller.close()` is guaranteed via `try/finally` | `idleTimeout` + `makeFetch` guard + `try/finally` in `App.ServerBun` | runtime-verified at introduction; exercised under Venom/Playwright |
| 10 | Security headers on every response, including errors and redirects | ContractSpec (all 10 `Response` constructors) | `spago test` |
| 11 | CSP is the pinned nonce-based policy — `script-src 'nonce-<random>' 'self' 'unsafe-eval' 'strict-dynamic'`; no `unsafe-inline`. Widening it fails a test that demands a justification | ContractSpec (`cspWithNonce` exact-string assertion + `securityHeaders` carries no CSP) | `spago test` |
| 12 | Alpine seams can't silently break — the `contentTarget` id and `data-page-title` attribute are asserted in rendered output. Alpine attribute *names* should only be built inside `App.Alpine`, **enforced by a literal-text scan** (`attr "x-`, `attr "@`, `attr ":`, `flag "x-`): a non-literal construction such as `let k = "@click" in attr k …` evades it, since `App.Html.attr` is exported unrestricted. Clause 12a is the compiler-enforced half | ContractSpec (literal scan) | `spago test` |
| 12a | Browser JS cannot be hand-written at a call site — handlers take `App.Alpine.Expr` and builders take `App.Alpine.Flag`, both closed types, so a string literal in either position is a compile error. Closes ADR-000 Vector B by construction. The generated expressions themselves are pinned by assertion | Compiler (abstract type + closed sum) + ContractSpec | `spago build`, `spago test` |
| 13 | Honeypot semantics — a filled honeypot ALWAYS means silent success (303 `status=success`) **after passing the rate gate** (429 if rate‑limited), for every possible input | Property tests (quickcheck) | `spago test` |
| 14 | Form decoding is total — every possible input decodes to a value, never throws | Property tests (quickcheck) | `spago test` |
| 15 | Route round-trips — `parseRoute (routeUrl r) == r` for every route × language | Test suite (all pairs) | `spago test` |
| 16 | Rendered HTML never contains unescaped `<`/`>` from `text` | Property tests (quickcheck) | `spago test` |
| 17 | No external scripts — rendered pages never reference `src="http…"` | ContractSpec (static routes) | `spago test` |
| 18 | Every page flows through the layout shell — no hand-rolled HTML documents | ContractSpec | `spago test` |
| 19 | All of the above runs on every push | GitHub Actions (build+gate, unit, Venom, Playwright) | `.github/workflows/ci.yml` |

## FFI marshalling: a named exemption to clause 3

Clause 3 requires decoding at the boundary. `toPsRequest` in
`App/ServerBun.js` does not decode request headers or cookies — it marshals
them structurally:

```js
headers: Object.fromEntries(req.headers)
cookies: Object.fromEntries(new Bun.CookieMap(req))
```

This is a deliberate exemption, not an oversight. Both sources are specified to
yield string→string pairs (the `Headers` iterator by the Fetch standard,
`Bun.CookieMap` by Bun's cookie API), so a decoder would restate the runtime's
own guarantee and reject nothing. Missing keys are already handled: every read
goes through `Map.lookup`, which returns `Maybe`.

**Scope: the whole `JsRequest` record, not just those two fields.** `method`,
`url`, `path`, `query`, `ip` and `body` are marshalled on the same terms — every
one is a primitive produced by `Bun.serve` and none is decoded. Naming only
headers and cookies would understate the trust actually placed in the runtime,
in the direction that flatters the claim. The exemption is: *primitives and
primitive maps produced by `Bun.serve` itself are trusted; everything else
decodes.*

The exemption covers **primitive maps of known shape, nothing else.** Anything
carrying structure or coming from a third party still decodes: upstream JSON
through Argonaut in `App.Data.Fetch`, form bodies through `App.Form`, DB rows
through `App.Data.SQL`. A future FFI addition does not inherit this exemption by
resembling it — it either decodes, or it argues its own case here.

(This section was written once, removed by the revert of `8f411a4e`, and
re-landed. The gap it documents was never closed in the meantime.)

## What the claim does NOT cover

Honesty is what makes the claim worth anything:

- **Logic bugs** — the type system proves shape, not intent. A function can
  return the wrong value of the right type.
- **FFI boundary content** — JS returning *wrong data of the right shape*
  passes decoding and fails the business. Boundary decoders catch malformed
  data, not wrong data.
- **Infrastructure** — OOM, disk full, kernel. No application-level guarantee
  covers these.
- **The runtime itself** — we run on `Bun.serve` via a tamed FFI boundary
  (`App.ServerBun`). Its semantics are upstream's; the integration and e2e
  layers exercise the server under Bun on every push.

## Keeping it true

- Every future FFI module: decode at the boundary, allowlist entry, ADR.
  One undecoded boundary voids clause 3.
- Every new convention: promoted to compiler, gate, or ContractSpec — or
  accepted as taste. Prose without enforcement gets deleted.
