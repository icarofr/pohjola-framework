# 04: Write the real About page

**What to build:** A fresh framework story/philosophy page — why Pohjola exists, what it's built on, what it's for — sharing zero sentences with the deleted `About` page. Reintroduced deliberately (per this session's site-structure decision), not a resurrection of the old content.

**Blocked by:** 02

**Status:** done (2026-09-09), commit `802d978` on branch `clean-sheet-homepage`

- [x] Content explains why Pohjola exists and what it's built on, in its own fresh wording — no sentence shared with the deleted `About` page's mission/values copy.
- [x] Any factual/historical claim (naming origin, design ethos, etc.) stays accurate to what's true of this repo today — don't invent claims the framework doesn't back up.
- [x] Real, native-reading translations for `en`/`fr`/`pt`.
- [x] DaisyUI-styled through `App.Ui` primitives, consistent with the rest of the site's visual language established in ticket 02/03.
- [x] Idiomatic PureScript throughout (see ticket 03's idiom checklist — same standard applies).
- [x] `make dev`: manually viewed in a browser across all three language paths.
- [x] `make gate && make test` pass (19/19, 205/205). `make check`'s `generator-policy` step still fails in this sandbox only, for the pre-existing `/tmp noexec` reason recorded on ticket 02.

## Comments

Spec: `.scratch/clean-sheet-homepage/spec.md`.
