# 11: Make `githubLink` reuse `dropdownTriggerClass` instead of hand-writing the same literal

**What to build:** Ticket `07-push-and-review.md`'s deferred item 8 declined to fix `SiteShell.purs`'s `githubLink` hand-writing `class_ "btn btn-ghost btn-sm"`, reasoning `navLinkClasses` didn't fit (it encodes active/inactive route state, which an external link doesn't have). That reasoning still holds against `navLinkClasses` — but commit `aa08b6a` (post-review) introduced `dropdownTriggerClass = "btn btn-ghost btn-sm"` in `App.Alpine`, which is *exactly* the same literal, has no active-state coupling, and is already the established trigger-button style for the theme/lang dropdowns sitting right next to `githubLink` in the navbar. Change `githubLink` (`SiteShell.purs:234,273`) to use `dropdownTriggerClass` instead of its own copy of the string.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] `githubLink`'s two call sites (desktop navbar, mobile drawer) use `dropdownTriggerClass` instead of a hand-written `"btn btn-ghost btn-sm"` literal
- [ ] No visual change (same rendered classes)
- [ ] `make gate && make test` pass

## Comments

Found by the Spec-axis code review of `dadcfe3..HEAD` (5 post-push commits on `master`, reviewed 2026-09-09): the deferred item 8 rationale in `07-push-and-review.md` no longer fully holds now that a fitting constant exists.
