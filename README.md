# purescript-fullstack-starter

> Server-rendered web with a compiler that makes the dangerous seams visible.

A PureScript + Bun starter for teams that want the JavaScript runtime and
ecosystem without making correctness entirely a matter of convention. The
server renders HTML; Alpine.js adds small enhancements without becoming a
second application.

## The problem

Web applications usually become fragile at the seams: a new route misses a
handler, external data is used before it is decoded, a thrown error becomes a
500, user data reaches markup through a string, or browser enhancements break
the no-JavaScript path.

Next/Remix-style TypeScript stacks are often the right choice for onboarding
speed and ecosystem breadth. Rails/Phoenix-style stacks are often the right
choice for server-rendered productivity and convention. Rust and Haskell can
offer strong domain discipline, but still leave a browser/runtime integration
decision.

This project chooses a narrower middle ground: PureScript's effect and pattern
matching discipline, Bun's runtime and npm access, and HTML-first delivery with
the failure-prone seams moved into types, a small FFI boundary, and executable
checks.

## The payoff

- **Effects are visible.** PureScript separates pure functions from `Effect` and
  `Aff`; network and server work cannot hide behind an ordinary pure signature.
- **Changes are exhaustive.** Routes, errors, and the English/French dictionary
  are algebraic data. Strict builds and `make gate` reject partial and unsafe
  escape hatches such as `unsafePartial`, `fromJust`, and `unsafeCoerce`.
- **HTML is a value.** `App.Html` builds a closed tree; text and attributes are
  escaped at render time, with no general-purpose unescaped constructor.
- **Failures are values.** Fetching and decoding use `Either AppError`; the
  router maps typed failures to responses and contains unexpected failures at
  one server boundary.
- **Bun stays available without becoming the architecture.** FFI is restricted
  to `App.ServerBun`, `App.FetchBun`, `App.Bun`, and `App.Data.SQL`.
- **The browser remains optional.** Alpine/AJAX can enhance real links and
  forms, but no hydration step is required for the page to work.

## Proof in the source

```purescript
-- src/App/Data/Fetch.purs
fetchJson :: forall a. DecodeJson a => String -> Aff (Either AppError a)
```

```purescript
-- src/App/Html.purs
data Html
  = Doctype
  | Element Tag (Array Attr) (Array Html)
  | Text String
  | Fragment (Array Html)
  | Empty
```

```purescript
-- src/Data/Route.purs
routeCodec :: Lang -> RouteDuplex' Route
```

```text
request -> route -> page/data -> Html -> response
```

`make gate` checks unsafe/partial APIs, FFI, environment access, and the HTML
escape boundary. `ContractSpec` pins security headers and CSP, layout flow,
Alpine seams, form semantics, feature isolation, and the absence of external
scripts. `make check` runs the full local path. The Posts list also streams its
HTML shell while data resolves.

## Start

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
bilingual static pages, contact/newsletter forms, and Posts backed by
JSONPlaceholder. `.env.example` documents email, origin, rate-limit, and SQL
configuration.

## Make the first change

```bash
make new-feature NAME=Team
make new-feature NAME=Products TYPE=data
make new-feature NAME=Team SLUG_FR=equipe
```

The generator creates the supported feature shape and prints the edits that are
application-specific. Start with [docs/SETUP.md](docs/SETUP.md), then use the
[page checklist](docs/conventions/adding-pages.md),
[data-layer guide](docs/conventions/data-layer.md), and
[forms guide](docs/conventions/forms.md).

## Verify

```bash
make gate
make test
make test/integration
make test/e2e
make check
```

CI runs the build/gate, unit, Venom, and Playwright suites on every push.

## The honest boundary

The compiler cannot prove business intent, that a JS wrapper returns the right
value of the right shape, or that Bun, an external API, or infrastructure has
enough capacity. Alpine's standard build requires `unsafe-eval`; the CSP uses
per-request nonces and does not permit `unsafe-inline` scripts. Bun canary is a
deliberate runtime commitment. See [docs/GUARANTEES.md](docs/GUARANTEES.md) for
the complete scope.

`dist/` is the public static root; `dist-server/` is the private server bundle.
Build and run the container with `make image`, `make up`, and `make down`.

## Read next

- [HTML ADT](docs/adr/ADR-001-hand-rolled-html-adt.md)
- [FFI boundary](docs/adr/ADR-003-ffi-taming.md)
- [Bun server](docs/adr/ADR-007-bun-serve.md)
- [Alpine contracts](docs/conventions/alpine-contracts.md)
- [Contributor conventions](AGENTS.md)

## License

[LICENCE.md](LICENCE.md)
