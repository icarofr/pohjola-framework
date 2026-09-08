# 03: Replace Route's six independent exhaustive dispatches with one canonical metadata table

**What to build:** `Data.Route`/`App.Main` currently have 6+ independently
exhaustive `case route of` dispatches over the same `Route` ADT: `allRoutes`,
`staticRoutes`, `prefetchFor`, `routeTitle`, and the static-vs-dynamic
dispatch inside `handleRoute`/`fragmentHtml`. Each is individually total (the
compiler forces exhaustiveness on each one), but nothing forces an agent
adding a new `Route` constructor to touch all of them together — it's
possible to compile cleanly while forgetting one, e.g. a route present in
`handleRoute`'s static case but missing from `staticRoutes`, which would
misfile it under the wrong cache policy without any compile error.

Replace the N independent dispatches with one exhaustive `Route -> RouteMeta`
function (or equivalent record-of-routes table) capturing the per-route facts
that currently live scattered: title source, static-vs-dynamic, sitemap
inclusion, prefetch eligibility. `allRoutes`, `staticRoutes`, `prefetchFor`,
`routeTitle`, and the relevant `Main.purs` dispatch sites become thin
derivations from that one table — adding a route now means filling in one
row, and forgetting a field is a record-construction compile error instead
of a silently-correct-elsewhere omission.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] One exhaustive `Route -> RouteMeta`-shaped function/table in
      `Data/Route.purs` (or a sibling module) capturing: static vs. dynamic,
      sitemap inclusion, prefetch eligibility, and whatever else the existing
      dispatches independently decide today
- [ ] `allRoutes`, `staticRoutes`, `prefetchFor` derive from that table
      instead of restating their own `case route of`
- [ ] `routeTitle` and `Main.purs`'s static-vs-dynamic dispatch
      (`handleRoute`/`fragmentHtml`) likewise derive from it where they
      currently duplicate the same classification
- [ ] `test/Route/RouteSpec.purs`'s existing `allRoutes`/`staticRoutes`
      assertions (added in the earlier remediation pass) continue to pass —
      now as consequences of the table, not independently hand-synced lists
- [ ] `make gate` + `make test` + `make check` pass
- [ ] `PostDetail Int` (a dynamic route excluded from `allRoutes`/sitemap by
      design) stays correctly excluded — do not change that behavior, only
      how it's expressed
