# purescript-fullstack-starter

A type-safe, server-rendered web application starter built with PureScript and
Alpine.js. Server-rendered HTML with SPA-feel navigation — no hydration, no
virtual DOM, no client build step, no runtime errors from missed pattern
matches.

## Why this exists

Every web starter makes a trade-off between **safety** and **simplicity**:

- **TypeScript starters** (Next.js, Remix, SvelteKit) are simple to ship but
  their safety is conventional — `as any`, `!`, thrown exceptions, and missing
  routes are all eslint-banned, not compiler-enforced. Every guarantee is one
  forgotten lint rule away from a runtime crash.
- **Haskell/Rust starters** match or exceed our compile-time safety, but they
  lose the JS runtime and its ecosystem. When you need a JS library, you FFI
  to C (memory-unsafe boundary) or WASM (complexity).
- **PureScript starters that exist** tend to wrap a JS framework (React, Halogen,
  Deku), re-introducing hydration, virtual DOM, and a client-side build pipeline.

This starter occupies the gap: **pure functional compile-time safety on a JS
runtime, with no client build step**. Three things together make it unique:

### 1. Pure functions are compiler-isolated from effects

In PureScript, `a -> b` cannot do I/O, mutate state, or throw. Side effects
require `Effect` or `Aff` in the type signature. Pure code can't call
effectful code. This means:

- `render :: Html -> String` is deterministic — no hidden filesystem reads,
  no network calls, no surprises in production.
- Property tests work on pure functions with zero mocking infrastructure.
- `Either AppError a` is the *only* way to fail from pure code — `throw` is
  not available.

Rust's `fn foo() -> i32` can do anything. TypeScript's `function foo(): number`
can throw, await, or return `undefined` with `!`. PureScript's `foo :: Int ->
Int` is a mathematical function. This is the guarantee neither can offer.

**Scope of the guarantee.** The effect system proves purity *inside* the
PureScript boundary. It does not prove the FFI is honest (see below), that Bun
won't segfault, or that memory won't exhaust. What it eliminates is the entire
class of crashes from null derefs, unhandled branches, and forgotten error
returns in domain logic — the class that dominates real-world JS/Go server
incidents.

### 2. Tamed FFI to a JS runtime

We run on Bun — GC memory safety (no lifetimes, no borrow checker), native
`fetch`, `Bun.escapeHTML` (SIMD), `Bun.XML.stringify`, `Bun.CookieMap`, and the
entire npm ecosystem. Access to all of it goes through a **7-module FFI
allowlist** with boundary decoders. The Makefile gate rejects `foreign import`
in any module not on the list. Every FFI function is wrapped to return `Aff
(Either AppError a)`.

**This is a trust boundary, not a type-proven one.** PureScript cannot
statically verify the JS it calls. A missed exception in a JS dependency, a
Bun behavioural change, or a decoder gap can still crash the process. What the
boundary buys is *containment*: the blast radius is 7 audited modules, not the
whole codebase, and every entry point returns `Either` so callers must handle
failure. The discipline is maintained by the gate (allowlist grep), the
ContractSpec (boundary shape), and review — not by the compiler.

Haskell and Rust have native libraries (no FFI needed for most things), but
when they do FFI it's to C — a memory-unsafe boundary. We get JS ecosystem
access through a contained, audited boundary. That's a niche no other safe
stack offers.

### 3. Pre-assembled enforcement apparatus

The guarantees above are portable — Haskell and Rust can replicate them. What
isn't portable is the **enforcement apparatus already wired to CI**:

- **Makefile gate** — grep-bans `unsafeCoerce`, `unsafePerformEffect`,
  `fromJust`, partial functions, unallowlisted FFI, `raw` HTML outside the
  allowlist. Runs in ~2s.
- **ContractSpec** — a PureScript test suite that enforces architectural rules
  the compiler can't: security headers on every response, CSP pinned
  byte-exact, every page flows through the layout shell, no cross-feature
  imports, no raw Alpine attribute strings, honeypot semantics.
- **Property tests** — quickcheck on pure seams: form decoding totality,
  honeypot silent-success, HTML escaping, route round-trips.
- **ADRs** — every architectural decision recorded with status, context, and
  consequences.

Rebuilding this apparatus in Haskell or Rust is weeks of work. Here it's
already built, tested, and documented.

### The honest trade-off

This is not the maximum-guarantee stack. Rust's `unsafe` keyword and borrow
checker eliminate memory and concurrency bugs a GC runtime hides; Haskell's
Servant offers type-level routing we don't attempt. TypeScript with `fp-ts` or
`Effect` gets close to our effect tracking without leaving the npm ecosystem.
The claim is narrower: **maximum-guarantee-per-unit-of-effort that also keeps
JS runtime access**, for teams who want the npm ecosystem on the server
without paying TypeScript's soundness tax.

**If it compiles and CI is green, the PureScript domain logic doesn't crash
from null derefs, unhandled branches, or forgotten error returns.** Crashes
outside that scope — Bun runtime faults, OOM, FFI leaks, misbehaving JS
dependencies — remain possible and are the focus of the enforcement apparatus
below, not the type system. See [docs/GUARANTEES.md](docs/GUARANTEES.md) for
the precise boundary of each guarantee.

### Costs worth naming

- **Bespoke tooling.** The Makefile gate, ContractSpec, and Html ADT are
  community-standard *patterns*, not community-standard *tools*. You are
  maintaining a small framework, not consuming one. The upside is that every
  rule is readable in this repo; the downside is no Stack Overflow answers.
- **Ecosystem surface.** PureScript has a strong compiler and core libraries
  but a fraction of TypeScript's or Rust's package ecosystem. New database
  drivers, payment gateways, or niche APIs will likely require writing FFI
  bindings — adding to the unit of effort.
- **Hiring.** Developers fluent in PureScript, `routing-duplex`, and Bun FFI
  boundaries are rare. This starter is optimised for a small team that values
  correctness over hiring throughput.

### Safety floor

- **Exhaustive pattern matching** — non-exhaustive `case` is a hard compile
  error, not a warning. Adding a route variant breaks every handler at compile
  time.
- **No partial functions** — `fromJust`, `Data.Maybe.Unsafe`,
  `Data.Array.Unsafe`, `Data.String.CodePoint.Unsafe`, and `unsafePartial` are
  gate-banned outright. Totality is enforced, not conventional.
- **No unsafe functions, no unapproved FFI** — `unsafeCoerce`,
  `unsafePerformEffect` are gate-banned; `foreign import` fails the build
  unless the module is allowlisted (7 modules, ADR-007).
- **Errors as values** — a single `AppError` ADT wraps library errors. Every
  boundary function returns `Aff (Either AppError a)`. Runtime exceptions are
  contained at one server boundary, logged, and answered with a 500.
- **No null, no undefined** — `Maybe a` for optional values, compiler forces
  handling.

### Architecture

```
Browser → Caddy (TLS) → PureScript server (Bun.serve)
                           ├── GET /en, /fr, /en/about, ... → SSR HTML
                           ├── GET /en/posts, /fr/articles/:id → SSR HTML (data-backed)
                           ├── POST /api/contact, /api/newsletter → redirect
                           ├── GET /healthz → "ok" (liveness probe)
                           ├── GET /assets/js/alpinejs.min.js → static
                           ├── GET /robots.txt, /sitemap.xml → generated
                           └── GET /css/styles.css → static
```

- **Server**: PureScript + `Bun.serve` via tamed FFI boundary (`App.ServerBun`,
  ADR-007) — no HTTP framework, no `node-http`
- **HTML**: Custom `Html` ADT — sum type with `render :: Html -> String`,
  SIMD-accelerated escaping via `Bun.escapeHTML`
- **Routing**: `routing-duplex` — bidirectional codec, one per language, dynamic
  segments via `int segment`
- **Data layer**: Async page rendering (`Aff (Either AppError Html)`). Posts
  feature demonstrates the full pattern: Types → Service (`App.Data.Fetch`) →
  Page → View
- **Interactivity**: Alpine.js 3.15.12 + Alpine AJAX 0.12.7 (self-hosted,
  pinned). Typed constructors in `App.Alpine` — no raw Alpine attribute strings
  (ContractSpec enforces)
- **SPA navigation**: `spaLink` helper bakes in AJAX swap + hover prefetch.
  Degrades to normal `<a>` if JS fails — the href is always real
- **Styling**: Tailwind CSS v4 (dark mode via class)
- **i18n**: Type-safe bilingual dictionary (EN/FR) — compiler enforces both
  languages have identical structure
- **JSON**: Argonaut `DecodeJson` — type-safe decoding at the boundary

### Testing

| Layer | Tool | What it tests |
|-------|------|---------------|
| Domain logic | `purescript-spec` + `purescript-quickcheck` | Pure functions, property tests (decode totality, honeypot semantics, HTML escaping) |
| Behavioral contracts | ContractSpec (`purescript-spec`) | Security headers, pinned CSP, Alpine seams, layout shell, allowlists |
| HTML rendering | `purescript-spec` | Html ADT escape, structure, void elements |
| Route parsing | `purescript-spec` | `parseRoute` / `routeUrl` round-trip |
| i18n completeness | `purescript-spec` | Both languages have all keys |
| HTTP integration | Venom | Status codes, redirects, form POSTs, static files |
| E2E browser | Playwright | Alpine interactions (nav, dark mode, forms, hover prefetch) |

## Quick Start

```bash
cp .env.example .env        # fill in RESEND_API_KEY if using forms
make deps                   # install dependencies + Alpine JS assets
make dev                    # build (PS + Tailwind)
make run                    # start server at http://localhost:3001
```

## Development

```bash
make watch                  # PS hot rebuild
make css-watch              # Tailwind hot reload
make test                   # unit + property tests (runs under Bun)
make test/integration       # Venom HTTP tests (requires Docker)
make test/e2e               # Playwright browser tests
make check                  # full validation (gate + build + test + format)
```

## Adding a New Page

```bash
make new-feature NAME=Team                    # static page (default)
make new-feature NAME=Products TYPE=data      # data-backed page
make new-feature NAME=Team SLUG_FR=equipe     # custom FR slug
```

Scaffolds the feature files and prints the manual edits needed for
`Route.purs`, `Main.purs`, and `I18n/Dictionary.purs` — the compiler guides
you to every missing site.

See `docs/conventions/adding-pages.md` for the full checklist and
`docs/conventions/data-layer.md` for the data-backed pattern.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | PureScript 0.15.16 |
| Build | Spago 1.0.4 (pure registry, no git pins) |
| Server | `Bun.serve` via tamed FFI (`App.ServerBun`, ADR-007) |
| Routing | `routing-duplex` 0.7.0 |
| HTML | Custom `Html` ADT |
| Interactivity | Alpine.js 3.15.12 + Alpine AJAX 0.12.7 |
| Styling | Tailwind CSS v4 |
| Runtime | Bun canary (1.4.0 — pin to stable on release) |
| Testing | `purescript-spec`, `purescript-quickcheck`, Venom, Playwright |
| Container | Distroless + Bun (~25MB) |

See `AGENTS.md` for agent conventions, `docs/` for full documentation.

## Licence

[LICENCE.md](LICENCE.md)
