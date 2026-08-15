# Pohjola

> A North for your web applications.

[![Live Website](https://img.shields.io/badge/Live-pohjola.icaro.fr-059669?style=flat)](https://pohjola.icaro.fr)
[![PureScript](https://img.shields.io/badge/PureScript-0.15.16-1D222D?style=flat&logo=purescript&logoColor=white)](https://www.purescript.org)
[![Bun Runtime](https://img.shields.io/badge/Bun-Runtime-000000?style=flat&logo=bun&logoColor=white)](https://bun.sh)
[![Alpine.js](https://img.shields.io/badge/Alpine.js-3.15-77C1D2?style=flat&logo=alpinedotjs&logoColor=white)](https://alpinejs.dev)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-v4.0-06B6D4?style=flat&logo=tailwindcss&logoColor=white)](https://tailwindcss.com)
[![Architecture](https://img.shields.io/badge/Architecture-SSR%20%2B%20Alpine%20Morph-059669?style=flat)](https://github.com/icarofr/pohjola-framework)
[![Unit & Property Tests](https://img.shields.io/badge/Unit%20%26%20Property%20Tests-191%20Passed-059669?style=flat)](https://github.com/icarofr/pohjola-framework)
[![E2E Tests](https://img.shields.io/badge/Playwright%20E2E-40%20Passed-059669?style=flat&logo=playwright&logoColor=white)](https://github.com/icarofr/pohjola-framework)
[![Security](https://img.shields.io/badge/Security-Strict%20CSP%20%2B%20Zero%20XSS-10B981?style=flat)](https://github.com/icarofr/pohjola-framework)
[![License: MIT](https://img.shields.io/badge/License-MIT-gray?style=flat)](LICENCE.md)

**Pohjola is an opinionated full-stack SSR framework where routes, data decoding, errors, translations, and HTML share a single, unbroken compile-time model.**

The compiler is your contract. Pohjola turns brittle architectural conventions into mechanically enforced invariants. Built on **PureScript**, **Bun**, and **Alpine.js**, it delivers sub-millisecond server rendering, zero runtime exceptions, instant client fragment transitions, and an immutable safety floor for both humans and AI agents.

---

## The Seam Problem

Every serialization step, unchecked template string, and ad-hoc API boundary is a seam where contracts drift and silent bugs breed. As web applications grow, asynchronous data flows and untyped DOM mutations spread across uncontrolled surfaces until confidence erodes and maintenance slows.

Pohjola closes the seams.

---

## One Model, Request to Browser

From incoming HTTP request down to emitted DOM fragments, everything is checked by the PureScript compiler:

```purescript
-- 1. Total bidirectional routing (one codec per language)
--    "/fr/articles" <-> Just { lang: Fr, route: PostList }

-- 2. Typed data fetching with explicit error values (never thrown)
renderList :: Config -> Lang -> Aff (Either AppError Html)
renderList cfg lang = do
  result <- fetchPosts cfg
  pure case result of
    Right posts -> Right (renderPostList lang posts)
    Left _      -> Right (renderPostsError lang)

-- 3. Algebraic closed HTML ADT (XSS-impossible by construction)
renderPostList :: Lang -> Array Post -> Html
renderPostList lang posts =
  container "max-w-7xl" "py-16 sm:py-24"
    [ el "h1" [ class_ "text-4xl font-bold text-gray-900 dark:text-white" ]
        [ text (dict lang).posts.listTitle ]
    , el "div" [ class_ "mt-10 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8" ]
        (map (renderPostCard lang) posts)
    ]
```

Feature logic lives in isolated domain modules. Asynchronous effects compose cleanly through `Aff`. Alpine.js provides reactive micro-interactivity through typed constructors: the browser always receives complete, semantic HTML first.

---

## Architectural Highlights

### PureScript Type Safety
- **Totality and Exhaustive Matching:** The compiler rejects missing route handlers, forgotten dictionary translations, and unhandled failure branches.
- **Algebraic Html ADT:** HTML is constructed through typed data structures, eliminating raw string concatenation and XSS vectors.
- **Errors as Values:** I/O boundaries return `Either AppError a`. Exceptions are never thrown into the wild.

### Sub-Millisecond SSR on Bun
- **Native Bun Server Runtime:** Sub-millisecond route response times with streaming server-side rendering.
- **Instant Hot Reload:** Fast file watcher and dev server restarts with `make dev`.
- **Minimal Asset Footprint:** Zero heavy client JavaScript bundles (<15KB total). Perfect Core Web Vitals (CLS: 0, instant TTFB) by default.

### Alpine.js Reactive Seams
- **SPA Feel Without SPA Complexity:** Navigation links (`spaLink`) automatically prefetch HTML fragments on hover (`@mouseenter`) and perform instant DOM morph swaps on click.
- **Zero-JS Resilience:** If JavaScript fails or is disabled, all routes, forms, and pages degrade seamlessly into accessible HTML documents.

### Built for AI Agents: Zero-Drift by Construction
In loosely typed stacks, AI coding assistants frequently hallucinate missing properties, drop edge cases, forget localized translation keys, or introduce runtime bugs.
- **Mechanical Enforcement:** An agent cannot declare a route without completing its bidirectional codec, sitemap entry, and bilingual dictionaries.
- **Instant Guardrails:** `make gate` (~2s) and `ContractSpec` automatically verify FFI boundaries, CSP nonces, and feature isolation before changes can land.

---

## Architectural Trade-offs and Comparisons

Pohjola makes a deliberate architectural choice: the **server renders the first HTML**, **feature code owns its async lifecycle**, and **PureScript unifies routing, decoding, errors, and rendering in one typed codebase**. Alpine adds reactive micro-interactions without turning the application into a bloated client-side runtime.

### When Pohjola is the Right Fit
- **Request and response web applications** demanding ultra-fast initial render and low latency.
- **Content, dashboard, commerce, and SaaS platforms** requiring real semantic URLs, automated SEO, and pristine Core Web Vitals.
- **Systems demanding strict correctness**, total failure handling, and zero runtime crashes.
- **Teams partnering with AI coding agents** that need the compiler to mechanically reject hallucinations.

### When to Choose an Alternative
- **Offline-first client applications** with complex local sync engines.
- **Heavy client-canvas applications** (for example Figma, Canva, or complex vector suites).
- **Projects reliant on massive React or Vue component libraries** over custom semantic design systems.

---

### Landscape Comparison

| Framework / Paradigm | Primary Optimization | How Pohjola Compares |
|:---|:---|:---|
| **IHP (Integrated Haskell Platform)** | Full-stack Haskell with built-in ORM, schema designer, and heavy Nix environment. | Pohjola provides pure typed functional SSR on the ultra-fast Bun runtime with standard npm access, avoiding heavy Nix tooling and GHC build overhead. |
| **Django / Rails / Laravel** | Batteries-included conventions (ORM, admin panel, built-in mailers). | Pohjola trades built-in framework magic for total compile-time control over domain types, explicit effects, and guaranteed HTML safety. |
| **Next.js / SvelteKit / Nuxt** | Large npm ecosystem, client hydration, and hybrid meta-framework tooling. | Pohjola avoids hydration waterfall debt and runtime serialization surprises; types, error values, and HTML escaping survive all boundaries. |
| **Elm Architecture** | Strict client-side event loops and centralized browser state. | Pohjola keeps the request lifecycle on the server with `Aff` async orchestration, avoiding heavy single-page client runtimes. |
| **Gleam / BEAM (Phoenix)** | Actor concurrency, fault-tolerant supervision, and distributed clustering. | Pohjola brings functional type safety directly to the Bun runtime, providing seamless access to modern web tooling and npm dependencies. |

---

## Proof in this Repo (Enforced Invariants)

Pohjola's guarantees are not documentation conventions. They are mechanically verified on every commit:

- [x] **Closed `Html` ADT**: Rendering is restricted to algebraic data constructors. Raw string concatenation is forbidden (`make gate`).
- [x] **Errors as Values**: Async data boundaries strictly return `Aff (Either AppError a)`.
- [x] **Scrutinized FFI Floor**: Foreign JavaScript imports are restricted to four allowlisted modules (`App.ServerBun`, `App.FetchBun`, `App.Bun`, `App.Data.SQL`).
- [x] **Pinned Security Policy (CSP)**: Nonce-based Content Security Policy verified byte-exact in `test/ContractSpec.purs`.
- [x] **Total Bilingual Routing**: Derived via `routing-duplex`; missing translations or routes fail at compile time.

> For an in-depth breakdown of guarantees, see [`docs/GUARANTEES.md`](docs/GUARANTEES.md).

---

## Quickstart

### Prerequisites
- [Bun](https://bun.sh)
- [PureScript](https://www.purescript.org/)
- [Spago](https://github.com/purescript/spago)

```bash
# 1. Clone the repository
git clone https://github.com/icarofr/pohjola-framework.git
cd pohjola-framework

# 2. Install dependencies & Alpine assets
make deps

# 3. Start development environment with live reload
# (Runs Tailwind watcher + PureScript watcher + Bun server concurrently)
make dev
```

Visit [`http://localhost:3000/en`](http://localhost:3000/en) locally, or view the live deployment at [`https://pohjola.icaro.fr`](https://pohjola.icaro.fr).

### Development Commands

| Command | Description |
|:---|:---|
| `make dev` | Run full concurrent development environment (Tailwind + Spago + Bun hot reload) |
| `make watch` | Run Spago watcher for PureScript hot rebuilds |
| `make css-watch` | Run Tailwind CSS CLI watcher |
| `make run` | Build production bundle and run under Bun |

---

## Verification and Quality Gates

```bash
# Run structural invariants & security gate checks (~2s)
make gate

# Run unit tests, property tests, and exact contract checks
make test

# Run full end-to-end browser test suite (Playwright)
make test/e2e

# Run complete CI verification (gate + build + test + format-check)
make check
```

---

## Documentation

- **Architecture and Philosophy:** [`docs/conventions/adding-pages.md`](docs/conventions/adding-pages.md)
- **Data Layer and Fetching:** [`docs/conventions/data-layer.md`](docs/conventions/data-layer.md)
- **Forms and CSRF Security:** [`docs/conventions/forms.md`](docs/conventions/forms.md)
- **Alpine Seams and Contracts:** [`docs/conventions/alpine-contracts.md`](docs/conventions/alpine-contracts.md)
- **Strict Invariant Guarantees:** [`docs/GUARANTEES.md`](docs/GUARANTEES.md)
- **Agent Guide and Safety Floor:** [`AGENTS.md`](AGENTS.md)

---

## License

Distributed under the open source [MIT License](LICENCE.md).
