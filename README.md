# PureScript + Bun

## The compiler is the contract.

A full-stack SSR starter for teams tired of runtime surprises, contract drift,
and JavaScript glue spread across the application. One compiler-visible model
connects the request, domain, rendered page, and browser-facing seams.

> **Compiler-visible types for internal boundaries · one model across routes,
> forms, data, and pages · Bun-speed runtime · direct JS/npm FFI**

For one typed application boundary, the compiler-visible model carries the
contract; OpenAPI remains a strong choice for independently owned public APIs.

## Request to browser

```text
typed route → typed service/data decode → typed HTML → Bun response
```

The same domain model travels through server code, forms, routes, i18n, and
rendered browser pages. Alpine.js provides progressive enhancement through
typed constructors in `App.Alpine`; the browser receives real HTML first.

## Why it holds up

- **Effects stay visible:** sequential and parallel I/O compose through `Effect`
  and `Aff`.
- **Errors are values:** boundaries return types such as
  `Aff (Either AppError a)`.
- **HTML is typed:** a closed `Html` ADT handles text and attributes by
  construction.
- **Changes are exhaustive:** compiler checks and executable contracts expose
  stale routes, errors, and translations during change.

## Elm-level safety, PureScript freedom

Elm and PureScript both provide compiler-checked application code and
exhaustive changes. Elm’s focused architecture and flags, ports, and custom
elements make a deliberate, effective boundary for its target. PureScript
extends that discipline across full-stack code with direct FFI and general-
purpose Bun/server access. Here, the compiler checks PureScript application code
and signatures; small, reviewed boundary modules connect them to JavaScript,
with decoded inputs, `Either` failures, and server containment making foreign
work legible.

PureScript lets teams choose domain modules and structured `Aff` composition
for sequential or parallel async work. Elm’s architecture is focused and
effective for the applications it targets; this starter chooses a broader
full-stack shape.

| Stack | Primary strength | Best fit |
| --- | --- | --- |
| **PureScript + Bun** | Pure, effect-aware full-stack reach | Typed apps with direct JS access |
| **Elm** | Focused compiler-led frontend architecture | Highly constrained web UIs |
| **Lustre** | Gleam’s Elm-inspired web framework | Gleam teams building web UIs |
| **ReScript** | Typed JavaScript with excellent interop | Easier adoption into JS codebases |

## Proof in the repo

- Closed `Html` ADT for typed rendering.
- `Aff (Either AppError a)` for typed data failures.
- Four-module FFI allowlist: `App.ServerBun`, `App.FetchBun`, `App.Bun`, and
  `App.Data.SQL`.
- `make gate`, strict compilation, `ContractSpec`, property tests, and CI.
- SSR progressive enhancement: real URLs, real HTML, and typed Alpine seams.

See the repository’s detailed guarantees in
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

```bash
make gate
make test
make check
```

Explore [setup](docs/SETUP.md), [adding pages](docs/conventions/adding-pages.md),
[data layer](docs/conventions/data-layer.md), [forms](docs/conventions/forms.md),
and [project conventions](AGENTS.md).

Types define application shape; decoders, executable contracts, and tests
extend confidence to runtime seams. Deploy the Bun server with its private
`dist-server/` bundle and public `dist/` assets.

## License

[`LICENCE.md`](LICENCE.md)
