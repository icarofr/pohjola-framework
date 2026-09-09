# 09: Drop `xDataSiteChrome`'s unused `Boolean` parameter

**What to build:** `xDataSiteChrome :: Boolean -> Attr` (`src/App/Alpine.purs`) has exactly one call site, `xDataSiteChrome false` (`SiteShell.purs:137`), and both `ThemeMenuOpen`/`LangMenuOpen` always initialize to the same value the caller passes. The `Boolean` param implies independent per-flag initial state that doesn't exist anywhere in the tree. Either drop the parameter entirely (`xDataSiteChrome :: Attr`, hardcode `false` for both fields) or, if independent init is genuinely wanted later, take two `Boolean`s instead of one shared one — but nothing today calls for that either, so prefer dropping it.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] `xDataSiteChrome` has no parameter it doesn't use meaningfully (either zero-arg, or a signature that matches real variability)
- [ ] Call site in `SiteShell.purs` updated accordingly
- [ ] `make gate && make test` pass

## Comments

Found by the Standards-axis code review of `dadcfe3..HEAD` (5 post-push commits on `master`, reviewed 2026-09-09). Judgement-call smell (Speculative Generality), not a hard standards violation.
