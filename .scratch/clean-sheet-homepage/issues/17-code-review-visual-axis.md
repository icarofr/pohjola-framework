# 17: Give `code-review` a third, runtime/visual axis

**What to build:** The `code-review` skill's two sub-agents (Standards, Spec) both work from `git diff` text only. Neither would ever catch "the dropdown doesn't open" or "this page is narrower than its siblings" — those aren't visible in a diff. Add a third parallel sub-agent, dispatched for diffs touching `App.Ui.Templates/*`, `SiteShell.purs`, or Alpine-related files: it runs `make run`, screenshots/clicks the affected routes via raw `playwright-core`, and reports visual/interaction findings the same way Standards/Spec report theirs.

**Note:** this is a change to a user-level skill (`~/.claude/skills/code-review`), not a file in this repository — it needs the user's own action/access, not an agent PR in this tree. Filed here anyway so the decision isn't lost.

**Blocked by:** None (can start immediately, but requires the user to act outside this repo)

**Status:** ready-for-human

- [ ] Decide whether to add the third axis at all, given ticket 13 (mandatory implementer-side visual verification) should mean review rarely needs to catch this
- [ ] If yes, write the sub-agent prompt/dispatch logic in the skill file

## Comments

From a `/grill-me` retrospective (2026-09-09). Recommended answer during grilling: yes, but as a backstop, not the primary fix — worth adding since implementer-side discipline (ticket 13) already slipped once in this exact session before being caught by the user, not by review.
