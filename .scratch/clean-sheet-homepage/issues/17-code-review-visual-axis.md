# 17: Give `code-review` a third, runtime/visual axis

**What to build:** The `code-review` skill's two sub-agents (Standards, Spec) both work from `git diff` text only. Neither would ever catch "the dropdown doesn't open" or "this page is narrower than its siblings" — those aren't visible in a diff. Add a third parallel sub-agent, dispatched for diffs touching `App.Ui.Templates/*`, `SiteShell.purs`, or Alpine-related files: it runs `make run`, screenshots/clicks the affected routes via raw `playwright-core`, and reports visual/interaction findings the same way Standards/Spec report theirs.

**Note:** this is a change to a user-level skill (`~/.claude/skills/code-review`), not a file in this repository — it needs the user's own action/access, not an agent PR in this tree. Filed here anyway so the decision isn't lost.

**Blocked by:** None (can start immediately, but requires the user to act outside this repo)

**Status:** wontfix (2026-09-09) — decided by the user

- [x] Decided: skip for now. Ticket 13 (mandatory implementer-side visual verification, now shipped in `AGENTS.md`) should make this redundant in practice; revisit only if visual defects still slip through review in the future.

## Comments

From a `/grill-me` retrospective (2026-09-09). Recommended answer during grilling: yes, but as a backstop, not the primary fix. User's decision (2026-09-09): skip for now — deferred rather than rejected outright, contingent on ticket 13's discipline actually holding.
