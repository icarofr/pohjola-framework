# PureScript + Bun

## The compiler is the contract.

`purescript-fullstack-starter` is a full-stack SSR starter for teams who want
fewer runtime surprises, fewer duplicated contracts, and less JavaScript glue.

> Model the domain once. Let the compiler find every consumer. Ship it on a
> fast JavaScript runtime.

| Typed end to end | Bun-speed runtime | Direct JavaScript FFI | No OpenAPI ceremony* |
| --- | --- | --- | --- |
| Routes, forms, data, HTML, and errors are compiler-visible | SSR on Bun with native `fetch` and streaming | Use the JavaScript and npm ecosystem without leaving PureScript | The compiler is the source of truth inside one application |

\* OpenAPI is still the right tool for independently owned public APIs. This
starter does not make you maintain a second schema for contracts already
represented by the types in your application.

## The web application problem

Most production surprises are not difficult algorithms. They are seams:

- the frontend and backend quietly disagree about a payload;
- a new route or error variant leaves an old branch behind;
- I/O is hidden inside code that looked like a calculation;
- external data is trusted before it is decoded;
- HTML, forms, and JavaScript attributes are assembled by convention;
- a useful JavaScript library is awkward to reach from a “safe” language.

This starter makes those seams visible in the code, then makes the compiler,
tests, and small gates enforce them.

## One model from request to browser

```text
request
  → typed route
  → typed service + boundary decode
  → typed view
  → Html ADT
  → Bun response
```

The same compiler-visible model covers routes, forms, i18n, data records,
application errors, and rendered browser pages. Add a route, error, or
translation field and PureScript finds the consumers that must change.

The browser gets real HTML first. Alpine.js adds progressive enhancement for
navigation, prefetching, themes, and forms through typed constructors in
`App.Alpine`; links still work and pages still render without hydration.

## Why this stack

### The compiler is the source of truth

For an application in one repository, the types are the contract. There is no
generated client SDK, schema file, or OpenAPI document to keep synchronized
with the code that already defines the route, payload, form, or error.

PureScript gives the compiler enough vocabulary to model the real domain:
algebraic data types, records, exhaustive pattern matching, typeclasses, and
row polymorphism. The payoff is not type-system trivia. The payoff is a small,
explicit change surface when the product changes.

### Safe without being sealed off

PureScript compiles to JavaScript and calls JavaScript directly. Bun exposes a
fast runtime, native `fetch`, `Bun.serve`, streaming, cookies, HTML escaping,
and access to the npm ecosystem.

This repository keeps that power in four reviewed FFI modules:

```text
PureScript application → typed boundary → allowlisted Bun / JavaScript API
```

You can reach the vast JavaScript ecosystem without turning every module into
untyped glue. The boundary is narrow, visible, and decoded on the PureScript
side.

### Effects are visible; failures are values

Pure functions stay pure. Network, filesystem, and server work appears as
`Effect` or `Aff`. Expected failure travels as a value such as
`Aff (Either AppError a)`, so handlers cannot quietly pretend that I/O is a
plain calculation.

### HTML and security are code, not hope

Pages are built through a closed `Html` ADT. Text and attributes are escaped by
construction; general-purpose unescaped HTML is not an application escape
hatch. Security headers, the CSP, form behavior, Alpine seams, and feature
boundaries are pinned by executable `ContractSpec` tests.

## As safe as Elm — with wider reach

If the claim is **“compiled application code should not contain ordinary
runtime exceptions,” PureScript is not less safe than Elm**.

Elm’s famous guarantee applies to compiled Elm application code. PureScript
can make the same strong application-code claim when the code is total, unsafe
partial-function shortcuts are banned, and JavaScript/external input crosses a
typed and decoded boundary. Neither language can prove business intent or make
the network, infrastructure, foreign code, or a bad value of the right shape
infallible.

The difference is not safety. It is the shape of the boundary:

| | Primary strength | JavaScript boundary | Best fit |
| --- | --- | --- | --- |
| **PureScript + Bun** | Purity, explicit effects, expressive types, full-stack reach | Direct FFI, with reviewed allowlists in this starter | One typed model across server code and browser-facing output, with the Bun/npm ecosystem |
| **Elm** | A famously constrained and friendly frontend architecture | Flags, ports, and custom elements | A frontend that benefits from a highly curated runtime and narrow interop surface |
| **Lustre** | Elm-inspired web architecture in Gleam | Gleam/JavaScript boundaries and web components | A web UI in the Gleam ecosystem |
| **ReScript** | Typed JavaScript with excellent direct interop and fast adoption | JavaScript-shaped interop | Teams prioritizing a gentle path from JavaScript and maximum JS familiarity |

Elm’s ports are not bad, and PureScript’s FFI is not magic. Ports provide a
disciplined message boundary; direct FFI provides broader, deeper access to
browser, server, Bun, and npm APIs. This starter chooses the latter while
making the seam explicit and reviewable.

## Proof in this repository

This is not a README promise floating above the code. The project enforces:

- a closed `Html` ADT with no general-purpose unescaped constructor;
- typed boundary failures through `Aff (Either AppError a)`;
- exhaustive route, error, and bilingual dictionary changes;
- a four-module FFI allowlist: `App.ServerBun`, `App.FetchBun`, `App.Bun`, and
  `App.Data.SQL`;
- a gate banning partial-function and unsafe escape hatches;
- executable contracts for headers, CSP, forms, Alpine seams, HTML escaping,
  feature isolation, and external scripts;
- build, unit/property, integration, and browser checks on every push.

Read the full claim and its enforcement in
[`docs/GUARANTEES.md`](docs/GUARANTEES.md).

## Start the demo

Requirements: Node.js 22, Bun canary, PureScript 0.15.16, Spago 1.0.4, and
Docker for integration tests and the container workflow.

```bash
npm install --global purescript@0.15.16 spago@1.0.4
curl -fsSL https://bun.sh/install | bash -s canary

git clone https://github.com/icarofr/purescript-fullstack-starter.git
cd purescript-fullstack-starter
cp .env.example .env
make deps
make run
```

Open [`http://localhost:3001/en`](http://localhost:3001/en) or
[`http://localhost:3001/fr`](http://localhost:3001/fr). The demo includes
bilingual pages, contact/newsletter forms, and Posts backed by JSONPlaceholder.

## Add a feature

```bash
make new-feature NAME=Team
make new-feature NAME=Products TYPE=data
make new-feature NAME=Team SLUG_FR=equipe
```

Then use the [setup guide](docs/SETUP.md), [page checklist](docs/conventions/adding-pages.md),
[data-layer guide](docs/conventions/data-layer.md), and
[forms guide](docs/conventions/forms.md).

## Verify the contract

```bash
make gate             # unsafe functions, raw HTML, and unapproved FFI
make test             # unit and property tests under Bun
make test/integration # Venom HTTP tests via Docker
make test/e2e         # Playwright browser tests
make check            # full build, tests, assets, and format check
```

## Deploy

`dist/` is the public static root. `dist-server/` contains the private server
bundle and is never served as static content.

```bash
make image
make up
make down
```

The container is distroless and non-root; put TLS and the public reverse proxy
in front of it. `/healthz` is the health check.

## The honest boundary

The compiler proves shape and exhaustiveness, not business intent. Foreign code
can still return the wrong value of the right shape. External APIs, Bun, and
infrastructure can still fail. Those are explicit boundaries, not reasons to
give up the contract: decode at the edge, contain unexpected failures, and
make the remaining risk visible.

See the [HTML ADT decision](docs/adr/ADR-001-hand-rolled-html-adt.md),
[FFI decision](docs/adr/ADR-003-ffi-taming.md),
[Bun server decision](docs/adr/ADR-007-bun-serve.md),
[Alpine contracts](docs/conventions/alpine-contracts.md), and
[contributor conventions](AGENTS.md).

## License

[LICENCE.md](LICENCE.md)
