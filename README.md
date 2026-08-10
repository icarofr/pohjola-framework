# purescript-fullstack-starter

## A practical path to almost no application-level runtime surprises

PureScript on Bun. Server-rendered HTML. Alpine.js when the browser needs it.

This starter is for teams who want to keep the JavaScript runtime and ecosystem
without making production correctness entirely a matter of convention. Pure
code stays pure, effects are visible, failures are values, HTML is escaped by
construction, and the few places where JavaScript is necessary are kept in
plain sight.

It does **not** promise that business logic cannot be wrong, that FFI cannot lie,
or that Bun cannot fail. It does aim to remove or contain the ordinary failures
that make web applications surprising: forgotten branches, unchecked external
data, accidental markup injection, hidden effects, and unhandled handler errors.

## Why PureScript?

PureScript is more than typed JavaScript and less isolated from JavaScript than
most strongly typed functional languages.

### Pure by default

Values are immutable. Pure functions cannot perform I/O; effects must appear as
`Effect` or `Aff` in the type. `Either` makes expected failure explicit. The
monadic machinery is not the product pitch—the useful result is that code which
can touch the network, filesystem, server, or runtime cannot pretend to be a
plain calculation.

### A general-purpose type system

Algebraic data types, exhaustive pattern matching, type classes, higher-kinded
types, row polymorphism, and higher-rank types let the domain model stay
expressive as the application grows. This is useful beyond a UI component tree:
the same language models routes, HTTP, forms, data decoding, migrations, and
rendering.

### Still JavaScript

PureScript compiles to JavaScript and can call JavaScript directly. Here, Bun
provides `Bun.serve`, native `fetch`, cookies, HTML escaping, streaming, and SQL.
If the application needs another Bun capability or an npm library, it can be
introduced through a reviewed, allowlisted FFI module instead of turning the
whole codebase into untyped JavaScript.

## Why not Elm, Lustre, or ReScript?

- **Elm** is excellent at a constrained frontend architecture with a very
  friendly compiler. Its JavaScript boundary is deliberately narrow—flags,
  ports, and custom elements. PureScript is the better fit here because the
  server, Bun runtime, npm libraries, and FFI are part of the application.
- **Lustre** is an Elm-inspired Gleam framework for frontends, Web Components,
  and server components. It solves a neighboring UI-architecture problem. This
  starter is a general-purpose PureScript server whose HTML happens to be
  progressively enhanced.
- **ReScript** is a strong choice when typed JavaScript, direct interop, and
  adoption speed are the priority. PureScript makes purity and effect tracking
  the default language model and offers a more expressive functional type
  system. The trade is a smaller ecosystem and a steeper learning curve.

The choice is not “which language is safest?” in the abstract. It is whether
the team wants to spend more effort up front so that effects, domain changes,
and boundary failures are difficult to leave implicit later.

## What this repository guarantees

The guarantees are scoped to this codebase and backed by checks:

- **No partial-function escape hatches in `src/`.** The gate rejects
  `unsafePartial`, `fromJust`, unsafe collection modules, `unsafeCoerce`, and
  related shortcuts.
- **Exhaustive domain changes.** Add a route, error, or translation field and
  the strict compiler finds the consumers that must change.
- **No general-purpose unescaped HTML path.** `App.Html` is a closed tree;
  text and attributes escape at render time. Script/style raw-text contexts are
  explicit, and JSON-LD is escaped for its script context.
- **Typed boundary failures.** Fetching and decoding use
  `Aff (Either AppError a)`. Unexpected handler/FFI exceptions are contained at
  the server boundary and answered with a 500 and security headers.
- **A small JavaScript boundary.** `foreign import` is allowlisted to
  `App.ServerBun`, `App.FetchBun`, `App.Bun`, and `App.Data.SQL`.
- **Security and seam contracts.** `ContractSpec` pins response headers and
  CSP, layout flow, Alpine targets, form behavior, feature isolation, and the
  absence of external scripts.
- **Total form and route behavior.** Form inputs decode to values rather than
  throwing; honeypots silently succeed; English/French route URLs round-trip.

The guarantee is not “nothing can ever go wrong.” It is: **the compiler, gate,
and tests remove a large class of ordinary application failures before
deployment, and contain the failures they cannot remove.**

## The application model

```text
request
  -> typed route
  -> Page / Service / View
  -> Html ADT
  -> server response
```

Data-backed pages fetch and decode through `App.Data.Fetch`. The Posts list
streams its HTML shell while data resolves. Alpine/AJAX can enhance navigation,
prefetch, theme, and forms, but links remain real URLs and pages do not require
hydration to render.

## Start the demo

Install Node.js 22, Bun canary, PureScript 0.15.16, and Spago 1.0.4. Docker is
needed for integration tests and the container workflow.

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
[http://localhost:3001/fr](http://localhost:3001/fr). The demo includes
bilingual pages, contact/newsletter forms, and Posts backed by JSONPlaceholder.

## Make it yours

```bash
make new-feature NAME=Team
make new-feature NAME=Products TYPE=data
make new-feature NAME=Team SLUG_FR=equipe
```

The generator creates the feature shape and prints the application-specific
edits. Start with [docs/SETUP.md](docs/SETUP.md), then read the
[page checklist](docs/conventions/adding-pages.md),
[data-layer guide](docs/conventions/data-layer.md), and
[forms guide](docs/conventions/forms.md).

## Verify it

```bash
make gate
make test
make test/integration
make test/e2e
make check
```

CI runs the build/gate, unit, Venom, and Playwright suites on every push.

## Honest limits

PureScript cannot prove business intent. A JS wrapper can still return the
wrong value of the right shape. Bun, external APIs, and infrastructure can
still fail. Alpine's standard build requires `unsafe-eval`; the CSP uses
per-request nonces and does not permit `unsafe-inline` scripts. Bun canary is a
deliberate runtime commitment.

These are explicit boundaries, not hidden exceptions. See
[docs/GUARANTEES.md](docs/GUARANTEES.md) for the full scope.

## Deploy

`dist/` is the public static root; `dist-server/` is the private server bundle.

```bash
make image
make up
make down
```

The container is distroless and non-root. Put TLS and the public reverse proxy
in front of it; `/healthz` is the health check.

## Read the decisions

- [HTML ADT](docs/adr/ADR-001-hand-rolled-html-adt.md)
- [FFI boundary](docs/adr/ADR-003-ffi-taming.md)
- [Bun server](docs/adr/ADR-007-bun-serve.md)
- [Alpine contracts](docs/conventions/alpine-contracts.md)
- [Contributor conventions](AGENTS.md)

## License

[LICENCE.md](LICENCE.md)
