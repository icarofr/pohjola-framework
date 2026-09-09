# 12: Decide disposition for 3 unticketed commits pushed to `master` after review closed

**What to build:** Not a code change — a decision. Ticket `07-push-and-review.md` closed the clean-sheet-homepage spec as done at `dadcfe3`. Five more commits then landed directly on `master` (`aa08b6a`, `c69b639`, `ee98547`, `6b4faa1`, `97517fc`), bypassing this repo's own local-markdown ticket tracker. Three of them are scope creep relative to `spec.md`/the 7 closed tickets, each already merged and functioning, but none was ever recorded as its own ticket:

- `c69b639` — repo-wide em-dash purge across all copy/languages/scaffolder output. `spec.md` never mentions punctuation style.
- `aa08b6a` + `ee98547` — language-menu dropdown rework and Alpine-AJAX scroll-to-top-on-swap. Chrome/UX polish outside the four-page-site deliverable.
- `97517fc` — scaffolder wiring for `TYPE=data` Main.purs config. `spec.md` explicitly scoped the rebuild to four *static* pages and explicitly excluded a data feature.

**Blocked by:** None (can start immediately)

**Status:** ready-for-human

- [ ] For each of the 3 items above: either (a) accept as legitimate out-of-band engineering and retroactively log it as its own closed ticket for the record, or (b) flag as a process gap to avoid repeating (agents/sessions pushing straight to `master` instead of routing through `.scratch/<feature-slug>/issues/`)
- [ ] If (b), decide whether any repo-level nudge is warranted (e.g. a CLAUDE.md note) or this is a one-off worth just noting and moving on

## Comments

Found by the Spec-axis code review of `dadcfe3..HEAD` (5 post-push commits on `master`, reviewed 2026-09-09). Filed to make sure the finding isn't lost, not because any of the 3 commits need to be reverted or are individually wrong.
