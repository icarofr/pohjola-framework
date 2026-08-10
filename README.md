# purescript-fullstack-starter

> Full-stack web where the domain is typed, the HTML is server-rendered, and the browser stays optional.

A PureScript 0.15.16 + Bun starter for applications that want more than a
green build: visible effects, exhaustive domain changes, typed HTML escaping,
and failures that travel as values. Alpine.js adds small browser enhancements;
it does not become a second application.

**Bun canary** · **Alpine.js 3.15.12** · **Alpine AJAX 0.12.7** · **Tailwind CSS 4.3.3**

## The problem

Most full-stack stacks make one of these trade-offs:

- Mainstream TypeScript SSR stacks optimize for ecosystem and onboarding. Their
  type checker is useful, but it does not require effect boundaries, exhaustive
  handling, typed HTML construction, or explicit error returns.
- Server-first frameworks make HTML and HTTP productive, but many correctness
  rules remain conventions enforced by review, tests, or developer discipline.
- Rust and Haskell can provide strong static discipline, but teams still need a
  separate browser/runtime story to use the JavaScript ecosystem.

This starter keeps Bun, npm, Alpine, and server-rendered HTML while moving the
most failure-prone application seams into PureScript's types, a small FFI
boundary, and executable repository checks.

The point is not that other stacks are unusable. The point is a different
default for teams where the cost of a forgotten branch, unchecked response,
unsafe markup path, or hidden side effect is higher than the cost of learning
PureScript.

## What this stack actually guarantees

These are claims about this repository, not promises about every PureScript app.

| Seam | Guarantee | Enforced by |
| --- | --- | --- |
| Effects | Pure functions cannot perform I/O; server and network work uses `Effect`/`Aff`. | PureScript types |
| Totality | Adding a route, error, or translation variant forces every consumer to be updated; banned partial/unsafe APIs cannot be used in `src/`. | Strict build + `make gate` |
| HTML | `Html` is a closed tree; text and attributes escape at render time, and there is no general-purpose unescaped constructor. | `App.Html` + gate + property tests |
| Failures | Boundary operations use `Either AppError`; decode, HTTP, FFI, and email failures are values that callers pattern-match. | Types + `App.Error` |
| Routes and i18n | One route model parses and prints both English and French URLs; both dictionaries share one shape. | Compiler + route tests |
| JavaScript interop | `foreign import` is restricted to four named Bun modules; FFI is plumbing, not application logic. | Makefile allowlist |
| HTTP security | Security headers are attached to every response; the nonce-based CSP is pinned and widening it breaks the contract tests. | `ContractSpec` |
| Forms and seams | Same-origin checks, rate limiting, total decoding, honeypot silent-success, layout flow, and feature isolation are tested behaviors. | `App.Form` + property/contract tests |

The type system does not prove that business logic is correct, FFI returns the
right value, Bun is bug-free, or infrastructure has capacity. Those limits are
part of the design, documented in [docs/GUARANTEES.md](docs/GUARANTEES.md).

## The runtime model

```text
Bun request
  -> Data.Route
  -> App.Main
  -> Feature Page / View
  -> Layout.Page
  -> Html
  -> HTTP response
```

Data-backed features use `Types -> Service -> Page -> View`. `Service` fetches
through `App.Data.Fetch.fetchJson` and decodes at the boundary. The Posts list
streams its HTML shell while data resolves; other pages return full documents or
Alpine-requested fragments from the same server routes.

The browser receives real links and forms. Alpine AJAX can enhance navigation,
prefetch, theme, and form states, but no hydration step is required for the
page to render or navigate.

## Run the demo

Install Node.js 22, Bun canary, PureScript 0.15.16, and Spago 1.0.4. Docker is
needed for the Venom integration tests and container workflow.

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
[http://localhost:3001/fr](http://localhost:3001/fr). The demo includes Home,
About, Contact, Legal, bilingual routes, and Posts backed by JSONPlaceholder.
Set `RESEND_API_KEY` in `.env` to exercise real email delivery.

## Extend it

```bash
make new-feature NAME=Team
make new-feature NAME=Products TYPE=data
make new-feature NAME=Team SLUG_FR=equipe
```

The generator creates the feature shape and prints the decisions it cannot
guess. A new page normally updates the route codecs for both languages, the
page renderer, localized dictionary, and tests.

Start with [docs/SETUP.md](docs/SETUP.md) when turning the boilerplate into an
app. The [page checklist](docs/conventions/adding-pages.md),
[data-layer guide](docs/conventions/data-layer.md), and
[forms guide](docs/conventions/forms.md) describe the supported seams.

## Verify it

```bash
make gate                # unsafe/partial/FFI/HTML/environment checks
make test                # unit, property, and contract tests under Bun
make test/integration    # Venom HTTP tests through Docker Compose
make test/e2e            # Playwright, including JavaScript-disabled pages
make check               # gate + build + tests + assets + format
```

`make check` is the local pre-push path. CI runs the build/gate, unit tests,
Venom, and Playwright independently on every push.

## Honest trade-offs

- Bun is the runtime commitment; this is not a Node-portable server starter.
- The FFI boundary is small and audited, not compiler-proven. JS can still
  return the wrong value of the right shape.
- Alpine's standard build requires `unsafe-eval`; the CSP removes
  `unsafe-inline` from scripts and uses per-request nonces. See
  [ADR-000](docs/adr/ADR-000-no-custom-browser-js.md).
- The HTML ADT, gate, contracts, and ADR discipline are opinionated project
  infrastructure, not a general-purpose web framework.
- Posts, email configuration, authentication, and persistence are starter/demo
  concerns that still need application-specific design.

## Ship it

`dist/` is the public static root. `dist-server/` is the private server bundle
and must never be served from `dist/`.

```bash
make image
make up
make down
```

The Dockerfile packages the server in a distroless non-root image. Put TLS and
the public reverse proxy in front of it; `/healthz` is the container health
check. For SQL-backed features, use
`make migrate-create NAME=create_users` and
`DATABASE_URL=postgres://... make migrate`.

## Read the decisions

- [Guarantees and limits](docs/GUARANTEES.md)
- [HTML ADT](docs/adr/ADR-001-hand-rolled-html-adt.md)
- [FFI boundary](docs/adr/ADR-003-ffi-taming.md)
- [Bun server](docs/adr/ADR-007-bun-serve.md)
- [Alpine contracts](docs/conventions/alpine-contracts.md)
- [Contributor conventions](AGENTS.md)

## License

[LICENCE.md](LICENCE.md)
