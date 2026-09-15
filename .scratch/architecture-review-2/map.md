# ExportStatic architecture review follow-through

## Destination

Resolve the two findings from the 2026-09-15 `/improve-codebase-architecture` pass over `App.Cli.ExportStatic` and its neighbors: `rootRedirectHtml` bypassing the `renderShell` seam, and `stubConfig`'s comment-only invariant. Unlike the first architecture-review effort (`.scratch/architecture-review/`), the goal for this one explicitly carries execution into the map itself, not just planning — both tickets below are resolved by implementing directly, not left for a live grilling round.

## Notes

- Execution in scope (overrides wayfinder's plan-don't-do default): the user's own goal for this effort was "find a path to all these fixes, then execute it... til its all fixed."
- Ground fixes in `codebase-design` vocabulary and this repo's own established idiom: `Policy.Contract` + `Test.Policy.Scan` + `Test.Policy.GateSpec` for mechanical gate rules; `renderShell` (from the prior architecture-review effort) as the document-shell seam.
- The report: `/tmp/architecture-review-20260915-163005.html` (this machine, may not survive a reboot).

## Decisions so far

- [rootRedirectHtml routed through renderShell](issues/01-root-redirect-seam.md): built its head content as `Html` like `renderErrorPage` does, called `renderShell` instead of hand-building a fourth document skeleton. Fixed the two live bugs this caused (missing `lang`, missing CSP) as a side effect. Verified via a real `make export-static` run.
- [stubConfig's invariant made mechanical](issues/02-stubconfig-gate-rule.md): added a `Policy.Contract`-style gate rule, derived from the real `Data.Route.isStaticRoute`, that fails if any static-route feature imports `App.Config`. Verified both green (current tree) and red (injected a violation, confirmed the gate caught it, reverted).

## Not yet specified

(none)

## Out of scope

- `parseCliArgs` silently drops unrecognized flags (architecture report Candidate 3, `/tmp/architecture-review-20260915-163005.html`): low-stakes CLI UX gap, not a shallow-module or seam-bypass finding. Left alone; not part of this effort's destination.
