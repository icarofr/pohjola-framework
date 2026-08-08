# purescript-fullstack-starter

A type-safe, server-rendered web application starter built with PureScript and
Alpine.js. Server-rendered HTML with SPA-feel navigation — no hydration, no
client-side framework, no runtime errors from missed pattern matches.

## Why

The compiler is the contract. One codebase, one compiler — no OpenAPI spec to
keep in sync, no codegen step, no "CI validates generated code" step. The
PureScript compiler enforces the contract between routes, types, and HTML.

**If it compiles and CI is green, production doesn't crash.** Every guarantee
behind that sentence is enforced by a check you can run — see
[docs/GUARANTEES.md](docs/GUARANTEES.md).

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
