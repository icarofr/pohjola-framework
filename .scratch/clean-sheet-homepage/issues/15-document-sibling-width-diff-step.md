# 15: Document a "diff against sibling templates" step for new page templates

**What to build:** Docs shipped at `Container.ContainerW3xl` while every other full-page template (`Article`, `Editorial`, `Hub`, `Landing`, `Feed`, the shell itself) uses `ContainerW6xl` — picked without checking what siblings already do (fixed in commit `58f4390`). Add a line to `docs/conventions/chrome-checklist.md` or `docs/conventions/component-checklist.md`: before shipping a new `App.Ui.Templates` module, `grep -n "Container\." src/App/Ui/Templates/*.purs` and either match the prevailing width or write one sentence justifying the difference.

Deliberately **not** a mechanical gate rule (considered and rejected during grilling) — a width-majority check would false-positive on legitimately narrower templates that already exist (`Form` at `ContainerW2xl`).

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] `chrome-checklist.md` or `component-checklist.md` has the sibling-diff step
- [ ] The doc explicitly notes this is a checklist step, not a gate check, and why (existing legitimate width outliers)

## Comments

From a `/grill-me` retrospective (2026-09-09). Recommended answer during grilling: documented step, not a `Policy.Contract` rule — the mechanical version trades one bug class for false positives on cases like `Form`'s narrower container.
