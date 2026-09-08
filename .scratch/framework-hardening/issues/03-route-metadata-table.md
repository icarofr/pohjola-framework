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

**Status:** done

- [x] Added `type RouteMeta = { isStatic :: Boolean, prefetch :: Array Route }`
      and an exhaustive `routeMeta :: Route -> RouteMeta` in `Data/Route.purs`.
      Left `allRoutes` as a hand-written literal (unavoidable — `Route`
      isn't `Bounded`/`Enum`, and `PostDetail Int` can't be enumerated
      regardless) and left `routeTitle` as its own function (it needs `Lang`,
      which doesn't belong in a plain per-route data table, and it was never
      the source of the named bug — each of its branches is already forced
      total by the compiler with no silent-drift risk)
- [x] `prefetchFor` and `isStaticRoute` (new) derive from `routeMeta`;
      `staticRoutes` derives from `isStaticRoute` filtered over `allRoutes`
      instead of a second hand-written list
- [x] `Main.purs`'s `handleRoute` and `fragmentHtml` — the two places that
      actually caused the audit's named bug scenario — now dispatch on
      `isStaticRoute ctx.route` (an if/else) instead of each independently
      re-deciding the same static/dynamic split via its own 6-armed
      `case ctx.route of`. They can no longer disagree with each other or
      with `staticRoutes`, because all three now read the same function.
- [x] `test/Route/RouteSpec.purs`'s existing `allRoutes`/`staticRoutes`
      assertions pass unchanged, now as consequences of `routeMeta`
- [x] `make gate` + `make test` (244/244) + `make eval-repo-law` (5/5) +
      `make check` all pass
- [x] `PostDetail Int` stays correctly excluded from `allRoutes`/sitemap —
      unchanged, only how the static/dynamic and prefetch facts are expressed
- [x] Bonus, found while implementing: `scripts/auto-scaffold.js` (the
      feature generator) regex-matched the old per-route `staticRoutes`
      literal and the old `handleRoute`/`fragmentHtml` case arms to wire new
      features in. Updated it to insert a `routeMeta` arm instead, and
      *deleted* the `handleRoute`/`fragmentHtml` wiring blocks entirely —
      a new feature no longer needs them, since both are now blanket
      dispatches. `scripts/verify-generator-fixture.js`'s assertions updated
      to match. This is direct evidence the consolidation reduced the actual
      per-feature wiring surface, not just the mental model of it.
