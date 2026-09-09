# 12: Decide disposition for 3 unticketed commits pushed to `master` after review closed

**What to build:** Not a code change — a decision. Ticket `07-push-and-review.md` closed the clean-sheet-homepage spec as done at `dadcfe3`. Five more commits then landed directly on `master` (`aa08b6a`, `c69b639`, `ee98547`, `6b4faa1`, `97517fc`), bypassing this repo's own local-markdown ticket tracker. Three of them are scope creep relative to `spec.md`/the 7 closed tickets, each already merged and functioning, but none was ever recorded as its own ticket:

- `c69b639` — repo-wide em-dash purge across all copy/languages/scaffolder output. `spec.md` never mentions punctuation style.
- `aa08b6a` + `ee98547` — language-menu dropdown rework and Alpine-AJAX scroll-to-top-on-swap. Chrome/UX polish outside the four-page-site deliverable.
- `97517fc` — scaffolder wiring for `TYPE=data` Main.purs config. `spec.md` explicitly scoped the rebuild to four *static* pages and explicitly excluded a data feature.

**Blocked by:** None (can start immediately)

**Status:** done (2026-09-09) — decided by the user, logged retroactively, no process nudge

- [x] Decided: accept as legitimate out-of-band engineering — retroactively logged, not flagged as a process gap
- [x] No repo-level nudge added; treated as a one-off

## Comments

Found by the Spec-axis code review of `dadcfe3..HEAD` (5 post-push commits on `master`, reviewed 2026-09-09). Filed to make sure the finding isn't lost, not because any of the 3 commits need to be reverted or are individually wrong.

User's decision (2026-09-09): log retroactively, no nudge. Each of the 3 items is now its own closed ticket: [[19-em-dash-punctuation-purge]] (`c69b639`), [[20-lang-dropdown-scroll-restore-polish]] (`aa08b6a` + `ee98547`), [[21-scaffolder-data-type-wiring]] (`97517fc`).
