# 20: Fix the language menu's broken open state and scroll-to-top on AJAX swap

**What to build:** ~~`LangMenuOpen` toggled `open`, but `x-data` only initialized `themeOpen`, so the language dropdown never actually opened. Separately, an Alpine AJAX nav or language swap replaced `#content` but left the window scrolled to wherever the previous page was.~~ Already done.

**Blocked by:** None

**Status:** done (2026-09-09), commits `aa08b6a` + `ee98547` on branch `master`

- [x] `xDataSiteChrome` initializes both `ThemeMenuOpen` and `LangMenuOpen` — language dropdown opens
- [x] Theme and language dropdowns share one Daisy recipe (`dropdownTriggerClass`/`dropdownItemClass`) so item class and panel width cannot drift independently
- [x] `TitleSync` scrolls to top on `ajax:merged`, covering both forward navigation and popstate restore
- [x] `ContractSpec` covers the scroll behaviour; `alpine-contracts.md`/`chrome-checklist.md` updated

## Comments

Retroactive ticket, filed 2026-09-09. These two commits landed directly on `master` after `07-push-and-review.md` closed the clean-sheet spec as done, bypassing this repo's `.scratch` ticket tracker (found by the Spec-axis code review of `dadcfe3..HEAD`, see ticket 12). `aa08b6a`'s lang-dropdown-never-opened fix is also the root cause behind this session's own `/grill-me` retrospective (ticket 14 — chrome-checklist.md's reuse-before-duplicate rule was added in this same commit). Logged here for the record per the user's decision on ticket 12: log retroactively, no process nudge.
