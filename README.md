# PureScript + Bun

## The compiler is the contract.

Most web applications do not fail because the algorithm was hard. They fail at
the seams: drifting API shapes, forgotten branches, hidden effects, unchecked
input, and JavaScript glue spread across the codebase.

This starter puts one compiler-visible model across routes, forms, data, HTML,
and errors—then runs it on Bun.

> **Typed application code. Fast JavaScript runtime. Direct access to the JS
> ecosystem.**

## What you get

- **No duplicate internal API schema.** For one typed application, records and
  sum types are the contract. No OpenAPI document to keep beside the code.¹
- **One model from request to browser.** Route → service/decode → view → HTML →
  Bun response.
- **Fast runtime and feedback loop.** Bun provides `Bun.serve`, native `fetch`,
  streaming, and npm compatibility; PureScript gives strict compile-time change
  feedback.
- **JavaScript without surrender.** Call JavaScript directly through a small,
  reviewed FFI boundary instead of abandoning the type system.

¹ OpenAPI still makes sense for independently owned public APIs. It is needless
duplication when the producer and consumer already share one compiler-visible
application model.

## Why it holds up

- **Effects are visible:** I/O appears as `Effect` or `Aff`, not as a surprise
  hidden inside a pure-looking function.
- **Failures are values:** boundaries return types such as
  `Aff (Either AppError a)`.
- **HTML is typed:** a closed `Html` ADT escapes text and attributes by
  construction.
- **Changes are exhaustive:** routes, errors, and translations cannot quietly
  leave stale consumers behind.

Alpine.js adds progressive enhancement through typed constructors in
`App.Alpine`. The browser gets real HTML first; pages do not depend on
hydration.

## As safe as Elm—with wider reach

PureScript is **not less safe than Elm for compiled application code**. Elm’s
“no runtime exceptions” claim applies to Elm code; PureScript can make the same
strong claim when application code is total, partial-function shortcuts are
banned, and foreign/external data is decoded at the boundary.

Neither language makes the network, infrastructure, foreign code, or bad
business logic infallible. Elm makes the safe path easier by offering a more
constrained runtime and JavaScript boundary. PureScript trades some default
constraint for direct FFI and general-purpose server access.

| Stack | Best fit | Boundary |
| --- | --- | --- |
| **PureScript + Bun** | Typed full-stack apps that still need JavaScript | Direct, allowlisted FFI |
| **Elm** | Highly constrained frontend architecture | Flags, ports, custom elements |
| **Lustre** | Elm-inspired web UI in Gleam | Gleam and web-component seams |
| **ReScript** | Typed JavaScript adoption and direct interop | JavaScript-shaped interop |

Ports are not bad, and FFI is not magic. The choice is whether you want a
narrow, curated boundary or broader access with an explicit boundary you own.

## Proof in the repository

- Closed `Html` ADT; no general-purpose unescaped HTML escape hatch.
- Typed data boundary: `Aff (Either AppError a)`.
- Four-module FFI allowlist: `App.ServerBun`, `App.FetchBun`, `App.Bun`, and
  `App.Data.SQL`.
- `make gate`, strict compilation, `ContractSpec`, property tests, and CI.
- SSR and progressive enhancement: real URLs, real HTML, typed Alpine seams.

The full claim and its enforcement live in
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

## Verify

```bash
make gate
make test
make check
```

Explore the [setup guide](docs/SETUP.md), [page checklist](docs/conventions/adding-pages.md),
[data layer](docs/conventions/data-layer.md), [forms guide](docs/conventions/forms.md),
and [project conventions](AGENTS.md).

The compiler proves shape and exhaustiveness—not intent, infrastructure, or
foreign code. Those boundaries are explicit, decoded, and contained where the
application can control them.

## License

[LICENCE.md](LICENCE.md)
