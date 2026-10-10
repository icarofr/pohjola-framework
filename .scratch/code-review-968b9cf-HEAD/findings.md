# /code-review findings: 968b9cf...HEAD (2026-09-22 to 2026-10-09 pulled-in work)

Reviewed the 8 commits that landed via fast-forward pull since the prior session (`5f4bc29`..`968b9cf`), two axes: Standards and Spec. See commit `f1fe745` for the fixes; this file is the paper trail so a future review doesn't re-raise what's already settled.

## Standards axis

- **Fixed** — ADR-003 exception list didn't name `cachedAsset`/`isUnsafeRel`/`devStaticPath` in `src/App/ServerBun.js`, which read as app logic in JS outside the two already-named exceptions. Named as a third exception (commit `f1fe745`).
- **Fixed** — Duplicated Code: `devStaticPath` inlined the same path-traversal check `isUnsafeRel` already does. `devStaticPath` now calls `isUnsafeRel` (commit `f1fe745`).
- **Not addressed, left open** — `docs/agents/domain.md:26` still says "`CONTEXT.md` does not exist yet," stale since before this diff. Minor, not blocking.
- **Not addressed, left open** — `docs/conventions/generators.md` doesn't mention `scripts/lib/wire-live-shape.js`, the new mechanism behind "clone from live shape."

## Spec axis

- **Resolved, no fix needed** — flagged as scope creep: commit `037f16c` (footer/robots.txt) silently dropped `ariaLabel labels.menuLabel` from the hamburger `<label>` in `App.DatastarShell.renderHeader`, unrelated to that commit's stated change. Investigated: the checkbox it controls (`DatastarShell.purs:166`) already carries the same `ariaLabel labels.menuLabel`, added in an earlier commit (`043ec99`) specifically because axe audits that real form control, not the label — a plain `<label>` isn't in the tab order and never needed its own accessible name. Confirmed via CI: `E2E Tests (Playwright)` (the job `043ec99` exists to satisfy) has been green on every commit since, axe check included. A legitimate dedup of a redundantly-named value, not a regression.
- Everything else on this axis (11c2e4c, bee87dc, f274a4f/946cede, and the other three no-spec commits) was faithful to its spec / own commit message — see the original review conversation for detail, not repeated here.
