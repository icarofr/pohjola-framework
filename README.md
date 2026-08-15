# Pohjola

> A North for your apps.

**Pohjola is an opinionated full-stack SSR framework where routes, data, errors, translations, and HTML share a single compile-time model.**

The compiler is the contract: turning architectural boundaries from fragile conventions into mechanically enforced invariants. Built on PureScript, Bun, and Alpine.js for systems that demand immovable safety, lightweight runtime performance, and zero architectural drift.

## The seam problem

Every API boundary, serialization step, and untyped template is a seam where contracts drift and runtime errors hide. As an application grows, async work, state, and rendering spread across unchecked boundaries until confidence is lost.

## One model, request to browser

Pohjola covers routing, data decoding, errors, i18n, and HTML in a single compiler-visible model:

```purescript
-- 1. Bi-directional route codec (total per language)
--    "/fr/articles" ➔ Just { lang: Fr, route: PostList }

-- 2. Typed data fetching with explicit error values
renderList :: Config -> Lang -> Aff (Either AppError Html)
renderList cfg lang = do
  result <- fetchPosts cfg
  pure case result of
    Right posts -> Right (renderPostList lang posts)
    Left _      -> Right (renderPostsError lang)

-- 3. Closed HTML ADT (safe by construction, zero unescaped strings)
renderPostList :: Lang -> Array Post -> Html
renderPostList lang posts =
  container "max-w-3xl" "py-16"
    [ el "h1" [ class_ "text-4xl font-bold text-slate-900 dark:text-white" ]
        [ text (dict lang).posts.listTitle ]
    , el "div" [ class_ "mt-8 space-y-6" ]
        (map (renderPostCard lang) posts)
    ]
```

Feature code stays in clean domain modules, while `Aff` composes sequential or parallel async work in the exact shape each feature requires. Alpine.js provides a typed seam for progressive enhancement—the browser always receives SSR HTML first.

## Built for agents: zero-drift by construction

In loosely-typed or macro-heavy stacks, AI agents frequently hallucinate missing props, ignore edge cases, forget localized dictionary keys, or introduce silent runtime exceptions.

Pohjola's rigid compiler constraints provide an immutable safety floor for LLMs:
- **Totality:** An agent cannot add a route without implementing its bidirectional codec, SEO metadata, and translations across all languages—the compiler rejects partial implementations.
- **Closed HTML ADT:** No raw HTML string interpolation. Agents cannot bypass sanitization or introduce XSS vulnerabilities.
- **Explicit Failures:** Async boundaries return `Aff (Either AppError a)`. Errors are values, forcing agents to handle failure states explicitly.
- **Instant Gatekeeping:** `make gate` (~2s) and `ContractSpec` verify FFI boundaries, CSP nonces, and feature isolation automatically before committing.

## SPA feel, 100/100/100/100 Lighthouse by default

Pohjola combines the speed, discoverability, and simplicity of server-rendered multi-page apps with the fluid, instant navigation of single-page apps:

- **100/100/100/100 Lighthouse & Core Web Vitals:** Pre-rendered HTML streams directly from Bun with zero hydration waterfall, zero cumulative layout shift (CLS: 0), minimal client JS (<15KB total), and instant Time to First Byte (TTFB).
- **SPA Transitions with Alpine AJAX:** Navigation links (`spaLink`) automatically prefetch HTML fragments on hover (`@mouseenter`) and swap content fragments on click without full document reloads.
- **Bilingual SEO Out of the Box:** Total bidirectional route codecs automatically generate localized `<link rel="alternate" hreflang="...">` tags, `sitemap.xml`, and JSON-LD structured data for every route across all languages.
- **Zero-JS Resilience:** If JavaScript is disabled or fails to load, every route, form submission, and page still functions as a standard, accessible HTML document.

## The payoff

- **Effects are visible:** I/O composes through `Effect` and `Aff`, with async work named in the types.
- **Errors are values:** data boundaries return `Aff (Either AppError a)`.
- **HTML is typed:** a closed `Html` ADT constructs text and attributes safely.
- **Bun and JavaScript stay close:** direct JS/npm access runs through a small, reviewed FFI boundary.

## What this choice trades

Pohjola makes a specific trade: the server renders the first HTML, feature code owns its own architecture, and PureScript keeps routes, data decoding, errors, forms, and rendering in one typed codebase. Alpine adds small browser interactions without turning the whole application into a client-side runtime.

That is a good fit for request/response applications that need fast first renders, real URLs, explicit failure handling, and a small JavaScript surface. It is a worse fit for an offline-first client, a highly interactive canvas/editor, or a team that primarily wants a large catalogue of ready-made JavaScript components.

The important alternatives make different trade-offs:

- **An opinionated server framework such as Django, Rails, or Laravel** usually gives you conventional routing, controllers, views, persistence, migrations, validation, jobs, and mail. Django also includes forms, authentication, and an admin; Rails and Laravel provide strong first-party conventions and ecosystem components around their cores. Pohjola gives you complete control over the domain model and effect boundaries, but you must design and maintain those pieces yourself.
- **Elm** gives a deliberately constrained frontend architecture: the browser owns a long-lived model and update loop, while the server is a separate concern. Pohjola keeps the request lifecycle on the server and lets each feature choose its own `Aff` orchestration; the cost is less uniformity and a smaller ecosystem.
- **A TypeScript meta-framework such as Next.js, SvelteKit, Nuxt, or Remix/React Router** combines a browser UI framework with routing, bundling, server rendering, client navigation, and server handlers. It offers a massive hiring pool and package ecosystem, but types generally do not survive runtime boundaries, whereas Pohjola makes decoding, errors, escaping, and server/browser boundaries explicit.
- **A Gleam/BEAM web stack** is compelling when lightweight processes, supervision, and BEAM deployment are central requirements. Pohjola is aimed at teams that want PureScript’s type system while staying close to Bun, npm packages, and the JavaScript runtime.

The choice is therefore not “which language has the best types?” It is where the application should place its state, effects, rendering, and operational responsibilities—and how much of that structure the framework should decide.

## Proof in this repo

- Closed `Html` ADT for typed rendering.
- `Aff (Either AppError a)` for typed data failures.
- Four-module FFI allowlist: `App.ServerBun`, `App.FetchBun`, `App.Bun`, and `App.Data.SQL`.
- Strict compilation, `make gate`, `ContractSpec`, property tests, and CI.
- SSR progressive enhancement: real URLs, real HTML, and typed Alpine seams.

The detailed guarantees and their enforcement live in [`docs/GUARANTEES.md`](docs/GUARANTEES.md).

## Start

Requirements: Bun, PureScript 0.15.16, Spago 1.0.4.

```bash
git clone https://github.com/icarofr/pohjola-framework.git
cd pohjola-framework
cp .env.example .env
make deps
make run
```

Open [`/en`](http://localhost:3000/en) or [`/fr`](http://localhost:3000/fr).

## Explore / verify

```bash
make gate
make test
make check
```

Explore [setup](docs/SETUP.md), [adding pages](docs/conventions/adding-pages.md), [data layer](docs/conventions/data-layer.md), [forms](docs/conventions/forms.md), and [project conventions](AGENTS.md).

## License

[`LICENCE.md`](LICENCE.md)
