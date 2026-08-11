# PureScript + Bun

## Functional safety without a fixed architecture.

The compiler is the contract: a full-stack SSR starter for teams whose web
applications are accumulating boundary drift, runtime surprises, and JavaScript
glue. PureScript + Bun keeps the domain model visible while leaving feature
architecture and JavaScript access open.

## The seam problem

As an application grows, contracts, async work, rendering, and runtime
integrations spread across seams. Each seam adds another place for intent to
drift from the code that serves users.

## One model, request to browser

```text
typed route → typed service/data decode → typed HTML → Bun response
```

The same compiler-visible model covers routes, forms, data, errors, i18n, and
HTML. Feature code stays in domain modules, while `Aff` composes sequential or
parallel async work in the shape each feature needs. Alpine.js is a typed,
browser-facing seam for progressive enhancement; the browser receives SSR HTML
first.

## The payoff

- **Effects are visible:** I/O composes through `Effect` and `Aff`, with async
  work named in the types.
- **Errors are values:** data boundaries return `Aff (Either AppError a)`.
- **HTML is typed:** a closed `Html` ADT constructs text and attributes safely.
- **Bun and JavaScript stay close:** direct JS/npm access runs through a small,
  reviewed FFI boundary.

## What this choice trades

This starter makes a specific trade: the server renders the first HTML, feature
code owns its own architecture, and PureScript keeps routes, data decoding,
errors, forms, and rendering in one typed codebase. Alpine adds small browser
interactions without turning the whole application into a client-side runtime.

That is a good fit for request/response applications that need fast first
renders, real URLs, explicit failure handling, and a small JavaScript surface.
It is a worse fit for an offline-first client, a highly interactive editor, or
a team that primarily wants a large catalogue of ready-made JavaScript
components and integrations.

The important alternatives make different trade-offs:

- **An opinionated server framework such as Django, Rails, or Laravel** usually
  gives you conventional routing, controllers, views, persistence, migrations,
  validation, jobs, and mail. Django also includes forms, authentication, and
  an admin; Rails and Laravel provide strong first-party conventions and
  commonly used authentication and admin components around their cores. This
  starter gives you more control over the domain model and effect boundaries,
  but you must design and maintain those pieces yourself.
- **Elm** gives a deliberately constrained frontend architecture: the browser
  owns a long-lived model and update loop, while the server is a separate
  concern. This starter keeps the request lifecycle on the server and lets
  each feature choose its own `Aff` orchestration; the cost is less uniformity
  and a smaller ecosystem.
- **A TypeScript meta-framework such as Next.js, SvelteKit, Nuxt, or
  Remix/React Router** combines a browser UI framework with routing, bundling,
  server rendering, client navigation, and server handlers or actions. It
  offers a large hiring pool, library ecosystem, and deployment catalogue, but
  persistence, domain validation, and many security decisions still come from
  separate packages and application code. Its types are convenient at compile
  time but generally do not survive runtime boundaries, whereas this starter
  makes decoding, errors, escaping, and server/browser boundaries explicit.
- **A Gleam/BEAM web stack** is compelling when lightweight processes,
  supervision, and BEAM deployment are central requirements. This starter is
  aimed at teams that want PureScript’s type system while staying close to Bun,
  npm packages, and the JavaScript runtime.

The choice is therefore not “which language has the best types?” It is where the
application should place its state, effects, rendering, and operational
responsibilities—and how much of that structure the framework should decide.

## Proof in this repo

- Closed `Html` ADT for typed rendering.
- `Aff (Either AppError a)` for typed data failures.
- Four-module FFI allowlist: `App.ServerBun`, `App.FetchBun`, `App.Bun`, and
  `App.Data.SQL`.
- Strict compilation, `make gate`, `ContractSpec`, property tests, and CI.
- SSR progressive enhancement: real URLs, real HTML, and typed Alpine seams.

The detailed guarantees and their enforcement live in
[`docs/GUARANTEES.md`](docs/GUARANTEES.md).

## Start

Requirements: Node.js 22, Bun canary, PureScript 0.15.16, Spago 1.0.4.

```bash
npm install --global purescript@0.15.16 spago@1.0.4
curl -fsSL https://bun.sh/install | bash -s canary
git clone https://github.com/icarofr/purescript-fullstack-starter.git
cd purescript-fullstack-starter
cp .env.example .env
make deps
make run
```

Open [`/en`](http://localhost:3001/en) or [`/fr`](http://localhost:3001/fr).

## Explore / verify

```bash
make gate
make test
make check
```

Explore [setup](docs/SETUP.md), [adding pages](docs/conventions/adding-pages.md),
[data layer](docs/conventions/data-layer.md), [forms](docs/conventions/forms.md),
and [project conventions](AGENTS.md). Types define application shape; decoders,
executable contracts, and tests extend confidence to runtime seams.

## License

[`LICENCE.md`](LICENCE.md)
