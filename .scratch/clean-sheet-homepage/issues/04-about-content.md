# 04: Write the real About page

**What to build:** A fresh framework story/philosophy page — why Pohjola exists, what it's built on, what it's for — sharing zero sentences with the deleted `About` page. Reintroduced deliberately (per this session's site-structure decision), not a resurrection of the old content.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Content explains why Pohjola exists and what it's built on, in its own fresh wording — no sentence shared with the deleted `About` page's mission/values copy.
- [ ] Any factual/historical claim (naming origin, design ethos, etc.) stays accurate to what's true of this repo today — don't invent claims the framework doesn't back up.
- [ ] Real, native-reading translations for `en`/`fr`/`pt`.
- [ ] DaisyUI-styled through `App.Ui` primitives, consistent with the rest of the site's visual language established in ticket 02/03.
- [ ] Idiomatic PureScript throughout (see ticket 03's idiom checklist — same standard applies).
- [ ] `make dev`: manually viewed in a browser across all three language paths.
- [ ] `make gate && make test && make check` pass.

## Comments

Spec: `.scratch/clean-sheet-homepage/spec.md`.
