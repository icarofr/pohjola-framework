# 01: Purge every existing feature page, route, and copy

**What to build:** A new branch, off current `master`, on which the entire existing content layer is gone: no `Home`, `About`, `Contact`, `Posts`, or `Fixtures` feature, no routes pointing at them, no `Data.I18n` copy for them, no `Posts`-only migration. The framework kernel (`App.Ui.*`, templates, Alpine, `App.Auth`/`App.Users`/`App.Data.SQL`/`App.Form`/`App.Email`, `Policy.Contract`, the scaffolder) is untouched. This is the one commit in the whole effort that is explicitly allowed to leave the site serving nothing — the point is a clean, legible "everything's gone" checkpoint in the log, not a working app yet.

**Blocked by:** None (can start immediately)

**Status:** done (2026-09-09), commit `f87be3c` on branch `clean-sheet-homepage`

**Finding for ticket 02:** `Route` is now a genuinely zero-constructor sum
type. `routing-duplex`'s `GRouteDuplex` class has no instance for a
zero-constructor Generic rep, so `routeCodec`/`G.sum {}` could not be kept
even as an empty skeleton — it doesn't compile, full stop. That also means
the scaffolder's regex-based route wiring (`scripts/auto-scaffold.js`) has
nothing to match against right now: `make check`'s `generator-policy` step
fails on this commit for exactly that reason (confirmed, not a fixture bug).
Ticket 02 will need to hand-restore `routeCodec`'s skeleton (or write it
fresh) for the first real route before `make new-feature --wire` has
anything to edit — the auto-wiring may not "just work" for the very first
route back from zero; verify this directly rather than assuming.
Nav links, the language switcher, and the footer link row are also gone
from `App.Ui.Templates.SiteShell` (they need real destination routes) —
restoring them is part of ticket 02's navbar work, not a separate task.

- [x] New branch created off current `master` tip (`02ba58e`); commit(s) for this ticket land only on that branch.
- [x] `src/App/Features/{Home,About,Contact,Posts,Fixtures}/` deleted entirely (all five directories).
- [x] Every `Route` constructor (`Home`, `About`, `Contact`, `PostList`, `PostDetail`, `Fixtures`) and its entries in `routeCodec` (all three languages), `routeMeta`, `routeTitle`, `allRoutes` removed from `Data.Route` — `Route` compiles as a zero-constructor sum type.
- [x] Every corresponding call site updated: `App.Main` (route dispatch, cache wiring), `App.Layout.Head`, `App.Ui.Templates.SiteShell` (nav rendering), `App.Sitemap`.
- [x] `Data.I18n`'s `Dictionary` fields `nav`, `hero`, `services`, `cta`, `about`, `contact`, `posts`, `fixtures` and the deleted pages' `seo` description fields removed (all three `en`/`fr`/`pt` values); `footer`/`common` and a minimal `seo` shape kept.
- [x] `migrations/001_create_posts.sql` deleted; `002`/`003` untouched.
- [x] `test/PostsSpec.purs` deleted outright (tests `Posts.Service`, which no longer exists).
- [x] `test/Route/RouteSpec.purs`, `test/ContractSpec.purs`, `test/TemplateContractSpec.purs`, `test/ShellSpec.purs`, `test/PolicySpec.purs` trimmed (literal per-deleted-route assertions removed) so the whole tree still typechecks and their `allRoutes`/`staticRoutes`-generic assertions still run, even though those arrays are now empty.
- [x] `test/FormSpec.purs`, `test/AuthSpec.purs`, `test/UsersSpec.purs` untouched and still compile (they test `App.Form`/`App.Auth`/`App.Users` directly, not through any feature page).
- [x] `spago build --pure` succeeds (src and test) — the tree compiles even though it now serves zero routes.
- [x] `git log`/`git show` on this commit reads as a clean deletion record — prefer `git rm` over silent overwrites.
- [x] Note (don't yet fix) whether `evals/evals/12-add-ui-component`'s `check.sh` depends on `About`/`Contact` existing — carry the finding into ticket 07 if it does.

## Comments

Spec: `.scratch/clean-sheet-homepage/spec.md`.
