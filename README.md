# PS Alpine Starter

> PureScript on the server. HTML in the response. Alpine.js when the page needs it.

PS Alpine Starter is a full-stack starting point for web applications that want
the server to remain the source of truth. PureScript renders the document,
handles routes and data, and makes failures explicit. Alpine.js adds focused
browser behavior without turning the site into a second application.

**PureScript 0.15.16** · **Bun canary** · **Alpine.js 3.15.12** · **Tailwind CSS 4.3.3**

## The idea

Most web applications begin with a client application and make the server fit
around it. This starter takes the opposite route:

```text
request -> typed route -> page + data -> HTML document -> browser enhancement
```

That choice has practical consequences:

- The first response is useful HTML, not a loading shell.
- A link has a real URL and still works when JavaScript is unavailable.
- Routing, rendering, decoding, and error handling share one typed domain model.
- Client-side behavior stays at the edges instead of owning the application.
- The checks that protect these decisions ship with the template.

This is not an attempt to make every part of a web system provably safe. Bun,
FFI wrappers, external APIs, and deployment configuration are still trust
boundaries. The goal is a small, inspectable application whose important
invariants are hard to forget.

## See the shape

The demo is bilingual and intentionally ordinary: Home, About, Contact, Legal,
and a Posts feature that fetches JSONPlaceholder data.

```text
/en                     English home
/fr                     French home
/en/about               static page
/en/contact             form page
/en/posts/1             data-backed page
/fr/articles/1          the same page through the French route codec
```

The server also provides `robots.txt`, `sitemap.xml`, and `healthz`. Alpine.js
handles selected navigation, theme, prefetch, and form interactions; the server
still owns the page and the response.

## Run the demo

You need Node.js 22 for the build tools, Bun canary for the server, PureScript
0.15.16, and Spago 1.0.4. Docker is only needed for integration tests or the
container workflow.

Install the language tools if they are not already available:

```bash
npm install --global purescript@0.15.16 spago@1.0.4
curl -fsSL https://bun.sh/install | bash -s canary
```

Then clone and start the app:

```bash
git clone https://github.com/icarofr/purescript-fullstack-starter.git
cd purescript-fullstack-starter
cp .env.example .env
make deps
make run
```

Visit [localhost:3001/en](http://localhost:3001/en) or
[localhost:3001/fr](http://localhost:3001/fr). `make run` builds the CSS,
bundles the server into `dist-server/`, copies public assets to `dist/`, and
starts Bun.

The demo does not need a real email provider to start. Add `RESEND_API_KEY` to
`.env` when you want form submissions to send through Resend. The example file
also documents `BASE_URL`, `PORT`, `POSTS_API_BASE`, rate limiting, email
addresses, and `DATABASE_URL`.

## What building here looks like

HTML is a value. A page composes `Html` nodes; the renderer escapes ordinary
text and attributes. There is no general-purpose unescaped HTML constructor.

Routes are a `Route` type plus one `routing-duplex` codec for each language.
Adding a route means updating the domain model and every exhaustive consumer,
not adding a path string to an unrelated registry.

Features have two deliberate shapes:

```text
static feature:       Page -> View -> Html
data-backed feature:  Types -> Service -> Page -> View -> Html
```

Services fetch through `App.Data.Fetch.fetchJson` and decode at the boundary.
Pages return `Either AppError` rather than hiding expected failures in thrown
exceptions. Shared layout lives in `App.Layout`; reusable visual primitives
live in `App.Ui`; feature modules do not import sibling features.

Browser behavior follows the same rule: use typed constructors from
`App.Alpine`, not ad-hoc Alpine attribute strings. Alpine AJAX can swap server
rendered fragments, but the underlying links and forms remain real HTML.

## Make it yours

The demo is there to show the seams, not to become your product unchanged.
Start a static or data-backed feature with the generator:

```bash
make new-feature NAME=Team
make new-feature NAME=Products TYPE=data
make new-feature NAME=Team SLUG_FR=equipe
```

The generator creates the feature files and tells you where the compiler cannot
fill in application-specific decisions. A normal page change touches:

1. The `Route` type and both language codecs.
2. The page renderer, title, navigation, and sitemap where applicable.
3. Both sides of the `Data.I18n` dictionary.
4. The feature's tests and the relevant HTTP/browser assertions.

Read the [page checklist](docs/conventions/adding-pages.md) before adding a
route. For the two main extension points, see the [data-layer guide](docs/conventions/data-layer.md)
and [forms guide](docs/conventions/forms.md). The
[setup guide](docs/SETUP.md) explains how to turn this boilerplate into a new
application.

## The feedback loop

The Makefile is the development interface:

```bash
make dev                 # strict PureScript build + CSS + static sync
make watch               # PureScript rebuilds
make css-watch           # Tailwind rebuilds
make test                # unit, property, and contract tests under Bun
make test/integration    # Venom HTTP tests through Docker Compose
make test/e2e            # Playwright, including the no-JS project
make check               # gate + build + tests + assets + format
```

`make gate` rejects unsafe and partial functions, unapproved FFI, environment
reads outside the configuration boundary, and the general-purpose HTML escape
hatch. Contract tests pin the CSP and response security headers, and check the
layout, Alpine, form, and feature-isolation seams.

## The boundaries are visible

The project intentionally keeps a few boundaries easy to find:

- `src/App/Html.purs` — the HTML vocabulary and renderer.
- `src/Data/Route.purs` — bilingual route parsing and URL generation.
- `src/App/Main.purs` — the HTTP router and page selection.
- `src/App/Layout/Page.purs` — the document and fragment shell.
- `src/App/Data/Fetch.purs` — the data-fetching boundary.
- `src/App/Alpine.purs` — the typed browser seam.
- `test/ContractSpec.purs` — executable architectural contracts.

Generated output has its own boundary too: `dist/` is the public static root;
`dist-server/` is private and must never be served as static content.

## Ship the container

The Dockerfile builds with Node.js, packages the PureScript server, and runs it
with Bun in a distroless image. Put TLS and the public reverse proxy in front
of it. The included Compose file defines the app service; it does not pretend
to be a complete production edge.

```bash
make image
make up
make down
```

For SQL-backed features, create a migration with
`make migrate-create NAME=create_users` and run it with
`DATABASE_URL=postgres://... make migrate`. The container health check uses
`/healthz`.

## Read the decisions

The README is the map; the repository's decisions live in the docs:

- [Guarantees and limits](docs/GUARANTEES.md)
- [No custom browser JavaScript](docs/adr/ADR-000-no-custom-browser-js.md)
- [The HTML ADT](docs/adr/ADR-001-hand-rolled-html-adt.md)
- [FFI boundaries](docs/adr/ADR-003-ffi-taming.md)
- [Bun server](docs/adr/ADR-007-bun-serve.md)
- [Contributor conventions](AGENTS.md)

## License

[LICENCE.md](LICENCE.md)
