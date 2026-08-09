# Adding a new page — checklists

> See [ADR-008](../adr/ADR-008-component-architecture.md) for the rationale
> behind the component architecture and the mandatory `Container` module.

## Component architecture (rule)

Every feature follows this structure — no variations:

```
src/App/Features/<Name>/
  Page.purs              # Orchestrator: calls data fetch, composes children
  View.purs              # Page-level rendering, imports from Components/
  Components/            # Feature-local presentational components (one per file)
    <ComponentName>.purs
  Types.purs             # Data-backed features only
  Service.purs           # Data-backed features only
```

**Two seams, two rules:**

1. **`Components/`** — feature-local presentational render functions. Extract
   a component when it's reused within the feature OR when `View.purs` exceeds
   ~80 lines. One component per file, named PascalCase. Components are pure:
   `Lang -> Data -> Html` (props in, Html out).

2. **`App/Ui/`** — shared primitives reused across features (Button, Card,
   Container, Social). A feature component promotes to `App/Ui/` when a
   second feature needs it. `App/Ui/` modules must never import from
   `App/Features/`.

**Container**: all width-constrained wrappers go through `App.Ui.Container.container`:

```purescript
container :: String -> String -> Array Html -> Html
container maxWidth extra inner
-- Produces: <div class="mx-auto w-full {maxWidth} px-4 sm:px-6 lg:px-8 {extra}">{inner}</div>
```

Never hand-write `mx-auto max-w-*` in a view — the `w-full` is load-bearing
(`<main>` is a flex column; without `w-full`, `margin: auto` shrinks children
to content width). `container` centralises the fix.

**Cross-feature imports are forbidden** (enforced by ContractSpec). Features
compose through shared `App/Ui/` primitives and `App.Data.Fetch`, never by
importing a sibling feature's modules.

## Static page (no data fetching)

1. New variant in `data Route` (`src/Data/Route.purs`)
2. Update both codecs in `routeCodec` (En + Fr)
3. Update `routeTitle` (in `Data.Route.purs`)
4. Update `pageRenderer` in `Main.purs`
5. `src/App/Features/<Name>/Page.purs` :: `render :: Lang -> Aff (Either AppError Html)`
   (wrap pure Html in `pure (Right ...)`)
6. `src/App/Features/<Name>/View.purs` — page-level rendering via `container`
7. `src/App/Features/<Name>/Components/` — extract when `View.purs` exceeds ~80 lines
8. i18n keys in `Data.I18n.purs` (both languages)
9. Add to `navItems` if it belongs in navigation
10. Venom assertions in `venom/01_routes.yml` + unit route tests

**Done when**: `make check` passes and the page renders at both `/en/<route>`
and `/fr/<route>` with localized titles.

## Dynamic route + data fetching (e.g. `/posts/:id`)

1. New variant in `data Route` with an argument: `PostDetail Int`
2. Update both codecs: `"PostDetail": "posts" / int segment` (En + Fr)
3. Update `routeTitle` — pattern-match on `PostDetail _`
4. Update `seoDescription` in `Head.purs` — pattern-match on `PostDetail _`
5. Update `pageRenderer` in `Main.purs` — call the async page renderer
6. Create `src/App/Features/<Name>/Types.purs` — newtype + `DecodeJson`
7. Create `src/App/Features/<Name>/Service.purs` — `fetchX :: Aff (Either AppError a)`
   via `App.Data.Fetch.fetchJson`
8. Create `src/App/Features/<Name>/Page.purs` — `render :: Lang -> Aff (Either AppError Html)`
9. Create `src/App/Features/<Name>/View.purs` — page-level rendering via `container`
10. Create `src/App/Features/<Name>/Components/` — extract cards/items as components
11. i18n keys in `Data.I18n.purs` (both languages)
12. Add the LIST route to `allRoutes` (for sitemap) — omit detail routes
    (dynamic IDs)
13. Add to `navItems` if the list page belongs in navigation
14. Unit tests: route round-trip + DecodeJson in `test/`

**Done when**: `make check` passes, the list page renders, and a detail
page returns 404 for a missing ID.

## ContractSpec enforcement

ContractSpec verifies: every feature has `Page.purs` with a `render*` entry;
a `Service.purs` implies the full `Types/Service/Page/View` split; no imports
from sibling features.
