# 19: Repo-wide em-dash purge and Songs from the North etymology restore

**What to build:** ~~About had lost the "Swallow the Sun" / Songs from the North naming etymology in the clean-sheet rewrite, and site copy used em dashes that the rest of the repo's prose avoids. Restore the etymology and switch all user-visible copy and page titles to ASCII punctuation.~~ Already done.

**Blocked by:** None

**Status:** done (2026-09-09), commit `c69b639` on branch `master`

- [x] `About` copy restores the Songs from the North / Swallow the Sun etymology
- [x] Site copy and page titles use ASCII punctuation instead of em dashes
- [x] `I18nSpec` gained a regression test so typesetting drift (em dashes creeping back in) fails the suite

## Comments

Retroactive ticket, filed 2026-09-09. This commit landed directly on `master` after `07-push-and-review.md` closed the clean-sheet spec as done, bypassing this repo's `.scratch` ticket tracker (found by the Spec-axis code review of `dadcfe3..HEAD`, see ticket 12). Logged here for the record per the user's decision on ticket 12: log retroactively, no process nudge — treated as a one-off, not worth a standing CLAUDE.md rule.
