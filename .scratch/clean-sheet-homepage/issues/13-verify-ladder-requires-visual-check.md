# 13: CLAUDE.md's Verify section requires visual verification for UI changes

**What to build:** CLAUDE.md's `## Verify` section (currently: "make gate after the first compile. make test if you touched Alpine, cache, forms, templates, or Main. make check before commit.") names no step that ever renders a page. `make test`/`make check` never include Playwright e2e — `test/e2e` is a separate Makefile target, explicitly excluded even from `ci-equivalent`. Add an explicit line: for any change touching `App.Ui.Templates/*`, `SiteShell.purs`, or feature `View.purs` visual output, render the changed route(s) and screenshot via raw `playwright-core` (not `make test/e2e`, which hangs in this sandboxed environment — see the `diagnosing-bugs` investigation referenced in this session) before calling the change done.

**Blocked by:** None (can start immediately)

**Status:** done (2026-09-09), commit `9fdd516` on branch `master`

- [x] CLAUDE.md's Verify section names the visual-check step explicitly, including the "use raw playwright-core, not `make test/e2e`" caveat and why
- [x] The step is scoped (which file globs trigger it), not a blanket "always screenshot everything"

## Comments

From a `/grill-me` retrospective (2026-09-09) on why the clean-sheet homepage rebuild shipped a crowded/broken navbar, a lang dropdown that never opened, a footer that never reached viewport bottom, a Docs page narrower than its siblings, and a theme icon that never changed — none of these are visible in a `git diff`, and nothing in the documented verify ladder ever rendered a page. Recommended answer during grilling: yes, write it down — this alone would have caught 5 of 8 defects on the first pass.
