Type: task
Status: resolved

## Question

`App.Cli.ExportStatic.stubConfig` is a hand-built fake `Config` with placeholder values, justified by a comment: "pageRenderer's Config param is unused by every static route today." Nothing mechanically enforced that. If a future `isStatic: true` feature's `Page.purs` started reading a real `Config` value, it would compile fine everywhere, and every exported HTML file would silently bake in `stubConfig`'s placeholder values instead of real ones — a silent-drift failure, not a crash.

## Blocked by

None (can start immediately)

## Answer

Added a new `make gate` rule in `test/Policy/GateSpec.purs`: "static-route features do not import App.Config." It derives the set of static features directly from `Data.Route.isStaticRoute`/`allRoutes` (not a second hand-maintained list), globs each one's directory, and reuses the existing `Test.Policy.Scan.findForbiddenImportsInFiles` primitive already used for the feature-view import checks. No new Scan helper was needed — this is a composition of two already-existing pieces (`Policy.Contract`-style declarative checks, real `Route` data) rather than a new mechanism.

Verified both directions, not just green: confirmed the current tree passes (20/20), then injected `import App.Config (Config)` into `src/App/Features/Home/Page.purs`, reran `make gate`, watched it fail exactly as intended (`19/20`, naming the offending file), then reverted the injected line and confirmed green again.
