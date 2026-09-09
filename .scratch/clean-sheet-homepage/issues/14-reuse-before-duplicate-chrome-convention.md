# 14: Write down "reuse before duplicating a chrome pattern"

**What to build:** ~~The lang dropdown (`dadcfe3`) was a hand-copied, drifted variant of the existing theme dropdown (different panel width, different active-item class) instead of a shared recipe extracted first.~~ Already fixed and already documented.

**Blocked by:** None

**Status:** done (2026-09-09) — already satisfied, no action needed

- [x] `docs/conventions/chrome-checklist.md:58` already states the rule: "Never hand-roll a second dropdown width or item class in `SiteShell` — change `dropdownPanelClass` / `dropdownItemClass` in `App.Alpine` so both menus move together." Added in commit `aa08b6a` alongside the actual fix.

## Comments

From a `/grill-me` retrospective (2026-09-09). Raised as an open question during grilling ("should this be written down or left to review?") — checked the docs before filing and found it already answered: `aa08b6a`'s own commit message ("Both disclosures now share one Daisy recipe so item class and panel width cannot drift independently") shows the convention was codified in the same commit as the fix. Closing on arrival rather than re-opening what's already resolved.
