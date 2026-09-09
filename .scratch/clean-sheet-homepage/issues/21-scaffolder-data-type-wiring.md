# 21: Teach the scaffolder to wire TYPE=data features against unused-config Main

**What to build:** ~~The clean-sheet `Head` uses `d.seo.*Description`, and `pageRenderer` binds `_cfg` until a `TYPE=data` route actually exists. `scripts/auto-scaffold.js`/`verify-generator-fixture.js` were still asserting the old body form and inserting `renderList cfg` against an unbound name, so generating a data feature against the clean-sheet tree was broken.~~ Already done.

**Blocked by:** None

**Status:** done (2026-09-09), commit `97517fc` on branch `master`

- [x] `auto-scaffold.js` wires `TYPE=data` features correctly against the clean-sheet `Main.purs`'s unused-config shape
- [x] `verify-generator-fixture.js` asserts the corrected form
- [x] `make eval EVAL=02-add-data-page CHECK=1` (or the fixture check under `make gate`) passes

## Comments

Retroactive ticket, filed 2026-09-09. This commit landed directly on `master` after `07-push-and-review.md` closed the clean-sheet spec as done — and `spec.md` explicitly scoped that rebuild to four *static* pages, explicitly excluding a data feature, so this is genuine scope creep relative to the spec (found by the Spec-axis code review of `dadcfe3..HEAD`, see ticket 12). Not reverted: the scaffolder generating broken code for `TYPE=data` is a real bug independent of whether the clean-sheet spec asked for it. Logged here for the record per the user's decision on ticket 12: log retroactively, no process nudge.
