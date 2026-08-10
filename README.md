# purescript-fullstack-starter

> The browser gets HTML. The compiler gets the domain. The gate gets the escape hatches.

A full-stack web application starter for building server-rendered sites with
PureScript and Bun. Alpine.js adds focused browser behavior; it does not become
the application. Tailwind handles styling, and the Makefile turns the project's
architectural rules into checks you can run locally and in CI.

**PureScript 0.15.16** · **Bun canary** · **Alpine.js 3.15.12** · **Alpine AJAX 0.12.7** · **Tailwind CSS 4.3.3**

## Why this stack

This starter is for applications that want strong domain guarantees without
giving up the JavaScript runtime and its ecosystem.

### Effects are visible

PureScript distinguishes pure code from `Effect` and `Aff`. A normal pure
function cannot perform I/O or quietly introduce an effectful operation. In this
repository, network calls, server work, and other boundaries are visibly
effectful instead of being hidden behind ordinary-looking functions.

### Totality is a project rule

The strict build, exhaustive pattern matching, and `make gate` work together.
Partial and unsafe escape hatches such as `unsafePartial`, `fromJust`,
`unsafeCoerce`, and unsafe collection modules are rejected. Add a route variant
and the compiler leads you to the handlers, titles, codecs, and other consumers
that need a decision.

### HTML is a typed value

Views construct a closed `Html` ADT, not concatenated markup. Text and attributes
are escaped by the renderer. `doctype`, script text, and style text have
explicit constructors and contexts. There is no general-purpose unescaped HTML
constructor to reach for when the type gets inconvenient.

### Failures travel as data

Expected boundary failures use `Either AppError`, including data fetching and
page rendering. The server has one runtime exception boundary; application code
does not need to turn every failure into a thrown exception and hope a distant
handler catches it.

### Routes are one model, not scattered strings

`Data.Route` contains the route type and bidirectional `routing-duplex` codecs
for English and French. The same model parses incoming paths and prints URLs.
The bilingual dictionary is also type-shaped, so both languages must provide the
same structure.

### Bun is available, but interop is contained

The starter uses Bun's server, fetch, HTML escaping, cookies, and SQL support
where they are useful. FFI is restricted to four audited modules:
`App.ServerBun`, `App.FetchBun`, `App.Bun`, and `App.Data.SQL`. The gate rejects
new `foreign import` declarations outside that boundary.

### The browser is an enhancement layer

Alpine.js is self-hosted and pinned. Browser behavior is expressed through
typed constructors in `App.Alpine`, while links retain real `href` values and
forms retain server endpoints. The result is an MPA with enhanced navigation,
not a hydrated client application that must take over before the page works.

### The architecture is executable

`ContractSpec` checks response security headers, the exact CSP, layout seams,
feature isolation, form behavior, and Alpine boundaries. Property tests cover
decoding, escaping, route round-trips, and honeypot semantics. The rules are
part of the starter rather than advice in a wiki page.

## The shape of a request

```text
Bun.serve request
  -> App.Main router
  -> Data.Route parser
  -> feature Page / View
  -> Layout.Page
  -> Html renderer
  -> server response
```

Data-backed features add one explicit path:

```text
Types -> Service -> App.Data.Fetch -> Page -> View -> Html
```

`Service` decodes external data at the boundary. `Page` orchestrates the
effectful work. `View` composes HTML. Shared layout and UI primitives stay
outside feature modules, and sibling features cannot import each other.

## What is included

The demo is deliberately small but covers the important seams:

- English and French routes: `/en/*` and `/fr/*`
- Static Home, About, Contact, and Legal pages
- Contact and newsletter forms with same-origin checks, rate limiting, and a
  silent-success honeypot
- A Posts list and `/posts/:id` detail page backed by JSONPlaceholder
- Alpine-enhanced navigation, hover prefetch, dark mode, and form states
- Generated `robots.txt`, `sitemap.xml`, and `healthz` endpoints
- Unit/property/contract tests, Venom HTTP tests, and Playwright tests,
  including a no-JavaScript browser project

The Posts API is demonstration data. Replace or remove that feature before
shipping a real application.

## Run it

Install Node.js 22, Bun canary, PureScript 0.15.16, and Spago 1.0.4. Docker is
needed for the Venom integration tests and the container workflow.

```bash
npm install --global purescript@0.15.16 spago@1.0.4
curl -fsSL https://bun.sh/install | bash -s canary

git clone https://github.com/icarofr/purescript-fullstack-starter.git
cd purescript-fullstack-starter
cp .env.example .env
make deps
make run
```

Open [http://localhost:3001/en](http://localhost:3001/en) or
[http://localhost:3001/fr](http://localhost:3001/fr). `make deps` installs
project dependencies and downloads the pinned Alpine assets. `make run` builds
CSS and the private server bundle before starting Bun.

The demo starts without a real email provider. Set `RESEND_API_KEY` in `.env`
when you want submissions to send through Resend. See `.env.example` for
`BASE_URL`, `PORT`, `POSTS_API_BASE`, rate limits, email addresses, and
`DATABASE_URL`.

## Make the first change

Scaffold a feature instead of inventing a third architecture:

```bash
make new-feature NAME=Team
make new-feature NAME=Products TYPE=data
make new-feature NAME=Team SLUG_FR=equipe
```

A new page normally requires a route variant, both language codecs, a renderer,
localized dictionary entries, and tests. The generator prints the manual edits
because those are application decisions the compiler cannot guess.

Start with the [page checklist](docs/conventions/adding-pages.md). Then use the
[data-layer guide](docs/conventions/data-layer.md), [forms guide](docs/conventions/forms.md),
and [setup guide](docs/SETUP.md) as needed.

## Verify the guarantees

The development loop is intentionally boring:

```bash
make dev                 # strict PureScript build, CSS, and static sync
make watch               # PureScript rebuilds
make css-watch           # Tailwind rebuilds
make gate                # unsafe/partial/FFI/HTML/environment checks
make test                # unit, property, and contract tests under Bun
make test/integration    # Venom tests through Docker Compose
make test/e2e            # Playwright, including JavaScript-disabled pages
make check               # gate + build + tests + assets + format
```

`make check` is the local pre-push path. It does not claim that external APIs,
Bun itself, or deployment infrastructure are infallible; it verifies the
invariants this repository owns.

## Honest trade-offs

- **Bun is a real commitment.** The server uses `Bun.serve` and the container
  uses Bun canary; this is not a Node-portable server starter.
- **FFI is contained, not magically verified.** The compiler cannot prove a JS
  wrapper honest, so the boundary is kept small, defensive, and gate-checked.
- **Alpine's standard build still needs `unsafe-eval`.** The CSP rejects
  `unsafe-inline` and external scripts, but Alpine's requirement remains an
  explicit documented trade-off in [ADR-000](docs/adr/ADR-000-no-custom-browser-js.md).
- **The safety layer is opinionated.** The `Html` ADT, contract tests, ADRs, and
  gate are bespoke project infrastructure, not a general-purpose web framework.
- **The demo is not a product.** Authentication, production content, email
  credentials, and real persistence still need application-specific design.

## Ship it

`dist/` is the public static root. `dist-server/` contains the private bundled
server and must never be served from `dist/`.

```bash
make image
make up
make down
```

The Dockerfile builds with Node.js, packages the server, and runs it with Bun in
a distroless non-root image. Put TLS and the public reverse proxy in front of
the app. The container health check uses `/healthz`.

For SQL-backed features, create a migration with
`make migrate-create NAME=create_users` and run it with
`DATABASE_URL=postgres://... make migrate`.

## Read the source of truth

- [Guarantees and limits](docs/GUARANTEES.md)
- [Contributor conventions](AGENTS.md)
- [HTML ADT decision](docs/adr/ADR-001-hand-rolled-html-adt.md)
- [FFI decision](docs/adr/ADR-003-ffi-taming.md)
- [Bun server decision](docs/adr/ADR-007-bun-serve.md)
- [Alpine contracts](docs/conventions/alpine-contracts.md)

## License

[LICENCE.md](LICENCE.md)
