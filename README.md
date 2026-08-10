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

## A broader full-stack choice

Elm and PureScript both bring compiler-checked application code and exhaustive
changes. Elm’s focused architecture is effective for frontend applications,
with flags, ports, and custom elements forming a deliberate boundary. PureScript
extends the same discipline across full-stack code with direct FFI, Bun/server
access, and the freedom to choose domain modules and async composition styles.

| Stack | Primary strength | Best fit |
| --- | --- | --- |
| **PureScript + Bun** | Pure, effect-aware full-stack reach | Typed apps with direct JS access |
| **Elm** | Focused compiler-led frontend architecture | Highly constrained web UIs |
| **Lustre** | Gleam’s Elm-inspired web framework | Gleam teams building web UIs |
| **ReScript** | Typed JavaScript with excellent interop | Easier adoption into JS codebases |

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
