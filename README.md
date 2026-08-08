# purescript-fullstack-starter

A type-safe, server-rendered web application starter built with PureScript and
Alpine.js. Server-rendered HTML with SPA-feel navigation — no hydration, no
virtual DOM, no client build step, no runtime errors from missed pattern
matches.

## Why this exists

Every web starter trades **safety** against **simplicity**:

- **TypeScript starters** (Next.js, Remix, SvelteKit) ship fast but enforce
  safety by convention — `as any`, `!`, thrown exceptions, and missing routes
  are eslint-banned, not compiler-enforced. TypeScript's type system is
  intentionally unsound.
- **Haskell/Rust starters** match or exceed our compile-time safety but leave
  the JS runtime. JS library access means FFI to C (memory-unsafe) or WASM.
- **Existing PureScript starters** wrap a JS framework (React, Halogen, Deku),
  re-introducing hydration, virtual DOM, and a client build pipeline.

This starter occupies the gap: **pure functional compile-time safety on a JS
runtime, with no client build step**.

### What the type system proves

`a -> b` in PureScript cannot perform I/O, mutate state, or throw — side
effects require `Effect` or `Aff` in the type signature. `Either AppError a`
is the only failure mode from pure code. Rust's `fn foo() -> i32` can do
anything; TypeScript's `function foo(): number` can throw, await, or lie with
`!`. `foo :: Int -> Int` is a mathematical function.

**Scope.** This eliminates null derefs, unhandled branches, and forgotten
error returns in domain logic — the class that dominates real-world JS/Go
server incidents. It does not prove the FFI is honest, that Bun won't
segfault, or that memory won't exhaust.

### What the FFI boundary contains

Bun gives GC memory safety, native `fetch`, `Bun.escapeHTML`, `Bun.XML.stringify`,
`Bun.CookieMap`, and the npm ecosystem. Access goes through a **3-module FFI
allowlist** (`App.ServerBun`, `App.FetchBun`, `App.Bun`); the Makefile gate
rejects `foreign import` elsewhere, and every FFI function returns `Aff (Either
AppError a)`. Each wrapper is defensive — `ServerBun.makeFetch` catches all
exceptions and returns a 500 with security headers, `FetchBun` routes fetch
errors to the `Either` channel, `stringifyXML` catches and returns `Nothing`.

This is a **trust boundary, not a type-proven one** — as is every FFI in every
language (Haskell's FFI to C, Rust's `unsafe`). The compiler can't verify the
JS we call. What's contained: the blast radius is 3 audited modules, every
entry point forces callers to handle failure, and the wrappers are tested.
What's not: a bug in a wrapper itself, or a Bun behavioural change, could
escape. Haskell/Rust FFI to C is memory-unsafe on top; this is the niche for
teams that need JS ecosystem access without paying TypeScript's soundness tax.

### What CI enforces beyond the compiler

- **Makefile gate** (~2s) — grep-bans `unsafeCoerce`, `unsafePerformEffect`,
  `unsafePartial`, `fromJust`, partial functions, unallowlisted FFI, `raw`
  HTML outside the allowlist.
- **ContractSpec** — security headers on every response, CSP pinned
  byte-exact, layout shell on every page, no cross-feature imports, no raw
  Alpine attribute strings, honeypot semantics.
- **Property tests** — form decoding totality, honeypot silent-success, HTML
  escaping, route round-trips.
- **ADRs** — every architectural decision recorded.

### Trade-offs

No stack dominates on every axis — it's a Pareto frontier, not a hierarchy.
Rust's borrow checker buys deterministic resource management (compile-time-known
lifetimes, no GC pauses) at the cost of a borrow checker; GC makes
use-after-free and lifetime bugs impossible without that cost. Haskell's
Servant publishes the API as a type-level contract (we use `routing-duplex` —
type-safe round-trips via a Generic codec, but not a publishable type-level
API). TypeScript with `fp-ts` or `Effect` can approximate our effect tracking,
but it's opt-in — the TS compiler doesn't force you to use them, and `as any`
/ `!` / thrown exceptions remain available everywhere. PS's effect tracking is
language-level and inescapable.

This starter is on the frontier for {effect tracking, JS ecosystem access,
totality enforcement, memory safety via GC}. It is not on the frontier for
{deterministic resource management, type-level API publishing}. The claim:
**maximum-guarantee-per-unit-of-effort that keeps JS runtime access**.

Costs: the gate, ContractSpec, and Html ADT are bespoke — readable in this
repo, but no community tooling around them. The PS package ecosystem is
smaller than TypeScript's or Rust's; new DB drivers, payment gateways, or
niche APIs likely need FFI bindings. Hiring is hard — but no harder than
Haskell or Rust; it's the cost of any FP-strong-safety niche, not this starter
specifically. This is a starter for a small team that values correctness over
hiring throughput.

**If it compiles and CI is green, the PureScript domain logic doesn't crash
from null derefs, unhandled branches, or forgotten error returns.** Everything
outside that scope is documented in [docs/GUARANTEES.md](docs/GUARANTEES.md).

## Safety floor

- **Exhaustive pattern matching** — non-exhaustive `case` produces a `Partial`
  constraint that fails compilation by default; `unsafePartial` is gate-banned,
  so in this repo totality is enforced, not conventional. Adding a route
  variant breaks every handler at compile time.
- **No partial functions** — `fromJust`, `Data.Maybe.Unsafe`,
  `Data.Array.Unsafe`, `Data.String.CodePoint.Unsafe` are gate-banned outright.
- **No unsafe functions, no unapproved FFI** — `unsafeCoerce`,
  `unsafePerformEffect` are gate-banned; `foreign import` fails the build
  unless the module is allowlisted (3 modules, ADR-007).
- **Errors as values** — a single `AppError` ADT wraps library errors. Every
  boundary function returns `Aff (Either AppError a)`. Runtime exceptions are
  contained at one server boundary, logged, and answered with a 500.
- **No null, no undefined** — `Maybe a` for optional values, compiler forces
  handling.

## Architecture

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
  ADR-007) — no HTTP framework, no `node-http`.
- **HTML**: Custom `Html` ADT — sum type with `render :: Html -> String`,
  escaping via `Bun.escapeHTML`.
- **Routing**: `routing-duplex` — bidirectional codec (parse + print from one
  declaration), one per language, dynamic segments via `int segment`. Adding a
  `Route` constructor without updating the codec is a compile error.
- **Data layer**: Async page rendering (`Aff (Either AppError Html)`). Posts
  feature demonstrates the full pattern: Types → Service (`App.Data.Fetch`) →
  Page → View.
- **Interactivity**: Alpine.js 3.15.12 + Alpine AJAX 0.12.7 (self-hosted,
  pinned). Typed constructors in `App.Alpine` — no raw Alpine attribute strings
  (ContractSpec enforces). The standard Alpine build requires `unsafe-eval`
  and `unsafe-inline` in CSP for script-src; a CSP build exists but we don't
  use it.
- **SPA navigation**: `spaLink` helper bakes in AJAX swap + hover prefetch.
  Degrades to normal `<a>` if JS fails — the href is always real.
- **Styling**: Tailwind CSS v4 (dark mode via class).
- **i18n**: Type-safe bilingual dictionary (EN/FR) — compiler enforces both
  languages have identical structure.
- **JSON**: Argonaut `DecodeJson` — type-safe decoding at the boundary.

## Testing

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
| Routing | `routing-duplex` |
| HTML | Custom `Html` ADT |
| Interactivity | Alpine.js 3.15.12 + Alpine AJAX 0.12.7 |
| Styling | Tailwind CSS v4 |
| Runtime | Bun canary (pin to stable 1.4.0 on release) |
| Testing | `purescript-spec`, `purescript-quickcheck`, Venom, Playwright |
| Container | Distroless + Bun (~25MB) |

See `AGENTS.md` for agent conventions, `docs/` for full documentation.

## Licence

[LICENCE.md](LICENCE.md)
