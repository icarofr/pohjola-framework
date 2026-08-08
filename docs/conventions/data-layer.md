# Data layer — async page rendering

Pages are **not** pure. `pageRenderer :: Route -> Lang -> Aff (Either AppError Html)`
in `Main.purs` is async. Static pages use the `staticPage` smart constructor
from `App.Layout.Page` (signature `staticPage :: Html -> Aff (Either AppError Html)`).
Data-backed pages fetch and may return `Left AppError`.

## The two feature templates

- **STATIC** (Contact, About, Legal, Home): `Page.purs` + `View.purs`
- **DATA-BACKED** (Posts): `Types.purs` + `Service.purs` + `Page.purs` +
  `View.purs`

ContractSpec enforces: every feature has `Page.purs` with a `render*` entry;
a feature with `Service.purs` implies the full `Types/Service/Page/View`
split; features stay isolated from siblings.

## The data-backed pattern (see `App.Features.Posts`)

1. **Types** (`Posts/Types.purs`) — domain newtype + `DecodeJson` instance
2. **Service** (`Posts/Service.purs`) — `fetchPosts :: Aff (Either AppError (Array Post))`.
   Errors are values (AppError), not exceptions.
3. **Page** (`Posts/Page.purs`) — `renderList :: Lang -> Aff (Either AppError Html)`.
   Fetches, pattern-matches: `Right` → render view, `Left` → propagate.
4. **View** (`Posts/View.purs`) — pure rendering from pre-fetched data.
5. **Router** (`Main.purs`) — maps `Left AppError` to HTTP status
   (NotFound → 404, _ → 500) via `renderErrorPage`.

**Done when**: `make check` passes and the page renders data from the
fixture, returns 404 for missing resources, and 500 on upstream failure.

## Fetching — App.Data.Fetch

All HTTP fetching goes through `App.Data.Fetch.fetchJson`. Feature modules
import from shared modules only — importing a sibling feature fails
ContractSpec.

To add a data-backed feature, copy the Posts pattern. Swap JSONPlaceholder
for your CMS — the pattern stays the same.
