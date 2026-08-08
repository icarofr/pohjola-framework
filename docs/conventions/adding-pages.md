# Adding a new page — checklists

## Static page (no data fetching)

1. New variant in `data Route` (`src/Data/Route.purs`)
2. Update both codecs in `routeCodec` (En + Fr)
3. Update `routeTitle` (in `Data.Route.purs`)
4. Update `pageRenderer` in `Main.purs`
5. `src/App/Features/<Name>/Page.purs` :: `render :: Lang -> Route -> Aff (Either AppError Html)`
   (wrap pure Html in `pure (Right ...)`)
6. `src/App/Features/<Name>/View.purs` for sections
7. i18n keys in `Data.I18n.purs` (both languages)
8. Add to `navItems` if it belongs in navigation
9. Venom assertions in `venom/01_routes.yml` + unit route tests

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
9. Create `src/App/Features/<Name>/View.purs` — pure rendering functions
10. i18n keys in `Data.I18n.purs` (both languages)
11. Add the LIST route to `allRoutes` (for sitemap) — omit detail routes
    (dynamic IDs)
12. Add to `navItems` if the list page belongs in navigation
13. Unit tests: route round-trip + DecodeJson in `test/`

**Done when**: `make check` passes, the list page renders, and a detail
page returns 404 for a missing ID.

## ContractSpec enforcement

ContractSpec verifies: every feature has `Page.purs` with a `render*` entry;
a `Service.purs` implies the full `Types/Service/Page/View` split; no imports
from sibling features.
