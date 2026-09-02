# Pohjola

> A North for your web applications.

[![Live Website](https://img.shields.io/badge/Live-pohjola.icaro.fr-059669?style=flat)](https://pohjola.icaro.fr)
[![PureScript](https://img.shields.io/badge/PureScript-0.15.16-1D222D?style=flat&logo=purescript&logoColor=white)](https://www.purescript.org)
[![Bun](https://img.shields.io/badge/Bun-1.4-000000?style=flat&logo=bun&logoColor=white)](https://bun.sh)
[![Alpine.js](https://img.shields.io/badge/Alpine.js-3.15-8BC0D0?style=flat&logo=alpinedotjs&logoColor=white)](https://alpinejs.dev)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-v4.0-06B6D4?style=flat&logo=tailwindcss&logoColor=white)](https://tailwindcss.com)
[![Licence](https://img.shields.io/badge/Licence-AGPL-334155?style=flat)](LICENCE.md)

**Pohjola is an opinionated full-stack web framework where routes, data decoding, errors, translations, and HTML share a single, unbroken compile-time model.**

The compiler is your contract. Pohjola turns brittle architectural conventions into mechanically enforced invariants. Built on **PureScript** and **Bun**, it is designed around server-authoritative hypermedia: the server renders complete HTML and owns application state. Alpine.js is an optional progressive-enhancement seam, not a second application runtime.

---

## The Seam Problem

Every serialisation step, unchecked template string, and ad-hoc JSON endpoint is a seam where contracts drift and silent bugs breed. In traditional Single-Page Applications (SPAs), teams duplicate domain state across two runtimes: a backend serving JSON and a client state machine reconstructing DOM trees from scratch.

When teams turn to traditional hypermedia (htmx, Django, Rails, PHP), they solve the state duplication problem but inherit a new vulnerability: **stringly-typed templates**. Broken URLs, missing form fields, typoed attributes, and escaping risks hide in raw strings until users encounter them in production.

Pohjola closes both seams.

---

## Hypermedia as the Engine of State (HATEOAS)

Pohjola embraces **Hypermedia as the Engine of Application State (HATEOAS)** with mathematical rigor.

Instead of shipping megabytes of client JavaScript to parse JSON and maintain out-of-band state, the server returns self-contained, semantic HTML. When resource state changes (such as an account balance update or a validation error), the server emits the updated hypermedia representation: valid links, enabled actions, and localized error banners.

Alpine AJAX acts as the hypermedia transport: navigation links and form submissions automatically fetch and morph HTML fragments without full page reloads.

```text
Incoming Request -> PureScript Route Codec -> Typed Service -> Algebraic Html ADT -> Bun Response
                                                                                        |
                                    Browser receives semantic HTML (instant morph via Alpine AJAX)
```

---

## One Model, Request to Browser

From incoming HTTP request down to emitted DOM fragments, application-level shapes are checked by the PureScript compiler; runtime behavior, FFI, infrastructure, and application intent remain outside that guarantee:

```purescript
-- Feature views fill template slots only (no class_ / layout soup).
-- See src/App/Features/About/View.purs

renderAbout :: Lang -> Maybe FormStatus -> Html
renderAbout lang status =
  renderPage lang About status (Editorial (aboutSlots lang))

aboutSlots :: Lang -> EditorialSlots
aboutSlots lang =
  let
    d = (dict lang).about
    nav = (dict lang).nav
  in
    editorialSlots
      d.heading
      (Just d.subtitle)
      d.mission
      (valuesSlotsFromArray d.values.heading d.values.intro d.values.items)
      [ PageHeader.breadcrumbHome lang nav.home
      , PageHeader.breadcrumbHere nav.about
      ]
```

Feature logic lives in isolated domain modules. Asynchronous effects compose cleanly through `Aff`. Alpine.js provides reactive micro-interactivity through typed constructors: the browser always receives complete, semantic HTML first.

---

## Architectural Highlights

### PureScript Type Safety
- **Totality and Exhaustive Matching:** The compiler rejects missing route handlers, forgotten dictionary translations, and unhandled failure branches.
- **Algebraic Html ADT:** HTML is constructed through closed, typed data structures with centralized escaping, reducing risks from raw string concatenation; runtime, FFI, and intent remain outside the guarantee.
- **Errors as Values:** I/O boundaries return `Either AppError a`. Exceptions are never thrown into the wild.

### Buffered SSR on Bun
- **Native Bun Server Runtime:** Server-side rendering is buffered by default; experimental streaming is opt-in.
- **Instant Hot Reload:** Fast file watcher and dev server restarts with `make dev`.
- **Minimal Asset Footprint:** No heavy client JavaScript bundle is required for the baseline experience; performance depends on deployment, network, content, and runtime conditions.

### Alpine.js Reactive Seams
- **Progressive enhancement without a SPA:** Optional navigation helpers can fetch and morph HTML fragments; the server remains authoritative and ordinary links and forms remain the baseline.
- **Zero-JS Resilience:** If JavaScript fails or is disabled, routes and forms use ordinary accessible HTML documents.

### Built for AI Agents: Zero-Drift by Construction
In loosely typed stacks, AI coding assistants frequently hallucinate missing properties, drop edge cases, forget localized translation keys, or produce inconsistent "utility soup" layouts.
- **Mechanical Logic Enforcement:** An agent cannot declare a route without completing its bidirectional codec, sitemap entry, and dictionary entries for every language in `allLangs`.
- **Visual Drift Prevention (daisyUI + page templates):** Raw layout utility soup in views is forbidden. `App.Ui.Templates` owns page chrome and section recipes on **daisyUI 5**; agents fill typed slot records (`Landing`, `Hub`, `Editorial`, `Feed`, `Article`, `Schedule`, `Form`). This limits structural drift; the type system does not guarantee pixels or intent.
- **Fast Guardrails:** `Policy.Contract` (`src/Policy/Contract.purs`) is the single source of truth. `make gate` (`Test.Gate`) enforces structural policy; `PolicySpec` (`make test`) adds reference-page archetypes; `ContractSpec` pins CSP, Alpine seams, and security headers.

---

## Architectural Trade-offs and Comparisons

Pohjola makes a deliberate architectural choice: the **PureScript application owns server-authoritative semantic hypermedia**, **feature code owns its async lifecycle**, and **PureScript unifies routing, decoding, errors, and rendering in one typed codebase**. Alpine adds optional progressive enhancement without turning the application into a client-side runtime.

### When Pohjola is the Right Fit
- **Request and response web applications** demanding ultra-fast initial render and low latency.
- **Content, dashboard, commerce, and SaaS platforms** requiring real semantic URLs, automated SEO, and pristine Core Web Vitals.
- **Systems demanding strict correctness**, typed failure handling, and bounded application-level failure modes.
- **Teams partnering with AI coding agents** that need the compiler to mechanically reject hallucinations.

### When to Choose an Alternative
- **Offline-first client applications** with complex local sync engines.
- **Heavy client-canvas applications** (for example Figma, Canva, or complex vector suites).
- **Projects reliant on massive React or Vue component libraries** over custom semantic design systems.

---

### Landscape Comparison

| Framework / Paradigm | Primary Optimisation | How Pohjola Compares |
|:---|:---|:---|
| **htmx / Hypermedia (Go, Django, Rails)** | Server-rendered HTML fragments driving client DOM updates without heavy SPA frameworks. | Pohjola delivers the same lightweight hypermedia model, while typed ADTs, centralized escaping, and bidirectional route codecs reduce template, link, and XSS risk. |
| **IHP (Integrated Haskell Platform)** | Full-stack Haskell with built-in ORM, schema designer, and heavy Nix environment. | Pohjola provides pure typed functional SSR on the ultra-fast Bun runtime with standard npm access, avoiding heavy Nix tooling and GHC build overhead. |
| **Django / Rails / Laravel** | Batteries-included conventions (ORM, admin panel, built-in mailers). | Pohjola trades built-in framework magic for compile-time control over domain types, explicit effects, and centralized HTML escaping at typed boundaries. |
| **Next.js / SvelteKit / Nuxt** | Large npm ecosystem, client hydration, and hybrid meta-framework tooling. | Pohjola avoids hydration waterfall debt and runtime serialisation surprises; types, error values, and HTML escaping survive all boundaries. |
| **Elm Architecture** | Strict client-side event loops and centralised browser state. | Pohjola keeps the request lifecycle on the server with `Aff` async orchestration, avoiding heavy single-page client runtimes. |
| **Gleam / BEAM (Phoenix)** | Actor concurrency, fault-tolerant supervision, and distributed clustering. | Pohjola brings functional type safety directly to the Bun runtime, providing seamless access to modern web tooling and npm dependencies. |

---

## Proof in this Repo (Enforced Invariants)

Pohjola's guarantees are not documentation conventions. They are mechanically verified on every commit:

- [x] **Closed `Html` ADT**: General-purpose or untrusted HTML escape hatches and raw string concatenation are forbidden (`make gate` via `Policy.Contract`). The explicitly reviewed experimental streaming shell is a scoped exception; buffered SSR remains the default.
- [x] **Errors as Values**: Async data boundaries strictly return `Aff (Either AppError a)`.
- [x] **Scrutinized FFI Floor**: Foreign JavaScript imports are restricted to four allowlisted modules in `Policy.Contract` (`App.ServerBun`, `App.FetchBun`, `App.Bun`, `App.Data.SQL`).
- [x] **Pinned Security Policy (CSP)**: Nonce-based Content Security Policy verified byte-exact in `test/ContractSpec.purs`.
- [x] **UI Archetype Policy**: UI: gate requires Templates.Render in every View; class_ banned (`Policy.Contract` + `Test.Gate`).
- [x] **Total multilingual routing**: Derived via `routing-duplex`; missing translations or routes fail at compile time (`allLangs`: En, Fr, Pt).
- [x] **Agent evals**: `make eval EVAL=10-ui-archetypes CHECK=1` (and matching evals for page/chrome/UI) after convention changes.

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
# (scripts/dev.js — CSS embed, static sync, Tailwind + Spago watchers, Bun)
make dev
```

Visit [`http://localhost:3000/en`](http://localhost:3000/en) locally, or view the live deployment at [`https://pohjola.icaro.fr`](https://pohjola.icaro.fr).

### Development Commands

| Command | Description |
|:---|:---|
| `make dev` | Local development — CSS + static sync + hot reload (picks port 3000, else 3001) |
| `make run` | Production-like — full `make build` then bundled server (CI/e2e parity) |
| `make watch` | Spago watcher only (no server) |
| `make css` | One-shot Tailwind compile + embed (rarely needed — `make dev`/`make run` include this) |

---

## Verification and Quality Gates

Policy is defined once in [`src/Policy/Contract.purs`](src/Policy/Contract.purs) (ADR-013):

| Tier | Command | What it checks |
|:---|:---|:---|
| Structural (fast) | `make gate` | `Test.Gate` — banned unsafe imports, FFI allowlist, content firewall, closed Ui/Templates, feature-view contract |
| Design | `make design-policy` | Generator/`App.Ui` boundary + compiled CSS primary token |
| Behavioral | `make test` | `PolicySpec` (reference pages) + `ContractSpec` (CSP, Alpine seam, security headers) |

```bash
# Structural policy from Policy.Contract (build + Test.Gate)
make gate

# Unit, property, PolicySpec, and ContractSpec tests
make test

# Cheap policy and formatting checks
make fast

# Fast checks plus the normal local build
make local

# Complete local validation (gate, design-policy, build, test, assets, format)
make check                 # equivalent to make full

# Integration tests against test containers
make test/integration

# Full end-to-end browser test suite (Playwright)
make test/e2e

# Canonical CI-equivalent validation (integration/E2E remain separate)
make ci-equivalent
```

`make check`/`make full` covers the local gate, design policy, build, unit tests,
asset verification, and formatting. It is not complete CI when integration and
E2E jobs are required; run `make test/integration` and `make test/e2e` separately.

---

## Documentation

- **Architecture and Philosophy:** [`docs/conventions/adding-pages.md`](docs/conventions/adding-pages.md)
- **Data Layer and Fetching:** [`docs/conventions/data-layer.md`](docs/conventions/data-layer.md)
- **Forms and CSRF Security:** [`docs/conventions/forms.md`](docs/conventions/forms.md)
- **Alpine Seams and Contracts:** [`docs/conventions/alpine-contracts.md`](docs/conventions/alpine-contracts.md)
- **Strict Invariant Guarantees:** [`docs/GUARANTEES.md`](docs/GUARANTEES.md)
- **Agent Guide and Safety Floor:** [`AGENTS.md`](AGENTS.md)

---

## Apps workspace

Local layout: `~/projects/pohjola/{framework,apps/*}`.
Apps are private clones with `upstream` → this public repo.
Pull framework improvements with: `git fetch upstream && git merge upstream/master`.

---

## Licence

Distributed under the [AGPL Licence](LICENCE.md).
