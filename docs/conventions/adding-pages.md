# Adding a new page — checklists

> See [ADR-008](../adr/ADR-008-component-architecture.md) for the rationale
> behind the component architecture and the mandatory `Container` module.

**Fast path:** `make new-feature NAME=Team WIRE=1` scaffolds files and wires
Route, Main, I18n, and Head. Then add navigation in `SiteShell` per
[`chrome-checklist.md`](chrome-checklist.md) or use `CHROME=1`. Verify with `make eval EVAL=01-add-page --check`
and `make eval EVAL=11-edit-chrome --check` when nav changes.
Component/template UI: [`component-checklist.md`](component-checklist.md), [`page-architectures`](../superpowers/specs/2026-08-31-page-architectures.md), `make eval EVAL=12-add-ui-component --check`.

## Component architecture (rule)

Every feature follows this structure — no variations:

```
src/App/Features/<Name>/
  Page.purs              # Static: handler + renderPage slots (single module)
  View.purs              # Data-backed: renderPage slots (fetch lives in Page.purs)
  Components/            # Optional — extract when a second visual unit appears
    <ComponentName>.purs
  Types.purs             # Data-backed features only
```

**Static pages** use one `Page.purs` (handler + template slots). **Data-backed** pages split fetch (`Page.purs`) and view (`View.purs`). Do not add `Service.purs` unless you have non-trivial domain logic — prefer `App.Data.Fetch` from `Page.purs`.

**Two seams, two rules:**

1. **`Components/`** — feature-local presentational render functions. One
   component per file, named PascalCase. Extract any distinct visual unit
   (a card, a form, a section, a sidebar) into its own file. `View.purs` is
   the orchestrator that composes them, not a dumping ground for inline
   helpers. Components are pure: `Lang -> Data -> Html` (props in, Html out).

2. **`App/Ui/`** — shared primitives reused across features (Button, Card,
   Container, Social). A feature component promotes to `App/Ui/` when a
   second feature needs it. `App/Ui/` modules must never import from
   `App/Features/`.

**Container**: width-constrained sections go through `App.Ui.Container.container`:

```purescript
container :: String -> String -> Array Html -> Html
container maxW extraClass children
-- Produces: <div class="container mx-auto px-4 sm:px-6 lg:px-8 {maxW} {extraClass}">{children}</div>
```

DaisyUI's `container` class handles full-width inside flex parents. Never
hand-write `mx-auto max-w-*` in a feature view.

**Page layouts**: compose via `App.Ui.Templates.renderPage` and a `PageTemplate`
slot record. Pick the template from [`page-architectures`](../superpowers/specs/2026-08-31-page-architectures.md). Do not add `class_` in feature views.

**Cross-feature imports are forbidden** (enforced by ContractSpec). Features
compose through shared `App.Ui.Templates` / primitives and `App.Data.Fetch`, never by
importing a sibling feature's modules.

## Static page (no data fetching)

1. `make new-feature NAME=<Name> WIRE=1` — or manually:
2. New variant in `data Route` (`src/Data/Route.purs`)
3. Update both codecs in `routeCodec` (every language in `allLangs`)
4. Update `routeTitle` (in `Data.Route.purs`)
5. Update `pageRenderer` in `Main.purs`
6. `src/App/Features/<Name>/Page.purs` :: `render :: Lang -> Aff (Either AppError Html)`
   (wrap pure Html in `pure (Right ...)`)
7. `src/App/Features/<Name>/Page.purs` — `renderPage` + `PageTemplate` slots
   (see [`page-architectures`](../superpowers/specs/2026-08-31-page-architectures.md); default scaffold uses `Editorial`)
8. `src/App/Features/<Name>/Components/` — optional; extract when you have a
   distinct reusable visual unit (card, sidebar, etc.)
9. i18n keys in `Data.I18n.purs` (every language in `allLangs`)
10. **Navigation** — if the page belongs in the header/footer, edit
    `App.Ui.Templates.SiteShell` (`desktopNavLink`, `mobileNavLink`,
    `footerLink`) per [`chrome-checklist.md`](chrome-checklist.md). `WIRE=1`
    does not wire nav for you.
11. Venom assertions in `venom/01_routes.yml` + unit route tests

**Done when**: `make check` passes and the page renders at each language prefix
(`/en/…`, `/fr/…`, `/pt/…` by default) with localized titles.

## Dynamic route + data fetching (e.g. `/posts/:id`)

1. `make new-feature NAME=<Name> TYPE=data WIRE=1` — or manually:
2. New variant in `data Route` with an argument: `PostDetail Int`
3. Update every language codec: `"PostDetail": "posts" / int segment`
4. Update `routeTitle` — pattern-match on `PostDetail _`
5. Update `seoDescription` in `Head.purs` — pattern-match on `PostDetail _`
6. Update `pageRenderer` in `Main.purs` — call the async page renderer
7. Create `src/App/Features/<Name>/Types.purs` — newtype + `DecodeJson`
8. Create `src/App/Features/<Name>/Service.purs` — `fetchX :: Aff (Either AppError a)`
   via `App.Data.Fetch.fetchJson`
9. Create `src/App/Features/<Name>/Page.purs` — `render :: Lang -> Aff (Either AppError Html)`
10. Create `src/App/Features/<Name>/View.purs` — `renderPage` + `Feed` / `Article` slots
11. Create `src/App/Features/<Name>/Components/` — optional; extract list
    items/cards when the view grows
12. i18n keys in `Data.I18n.purs` (every language in `allLangs`)
13. Add the LIST route to `allRoutes` (for sitemap) — omit detail routes
    (dynamic IDs)
14. **Navigation** — add list route to `SiteShell` if it belongs in chrome
    (see [`chrome-checklist.md`](chrome-checklist.md))
15. Unit tests: route round-trip + DecodeJson in `test/`

**Done when**: `make check` passes, the list page renders, and a detail
page returns 404 for a missing ID.

## ContractSpec enforcement

ContractSpec verifies: every feature has `Page.purs` with a `render*` entry;
a `Service.purs` implies the full `Types/Service/Page/View` split; no imports
from sibling features.

## Related docs

| Task | Doc |
|---|---|
| Page templates / slots | `design-system.md`, `docs/superpowers/specs/2026-08-30-ui-blueprint-recipe.md` |
| Site chrome / nav | `chrome-checklist.md`, `docs/superpowers/specs/2026-08-30-shell-recipe.md` |
| Scaffolding | `generators.md` |
| DaisyUI reference | `vendor/daisyui/skills/daisyui/components/` (submodule) |
