# 07: Final cleanup, push, and code review

**What to build:** The branch in a genuinely shippable state, pushed, and reviewed. Folds in the small cross-cutting cleanup items the spec flagged as too small to warrant their own ticket.

**Blocked by:** 03, 04, 05, 06

**Status:** done (2026-09-09), commits `5e94d6a` (cleanup) + a follow-up fix commit on branch `clean-sheet-homepage`

- [x] `CLAUDE.md`'s `## Task → one doc` exemplar line updated — points at Home/About (Landing/Editorial templates), states plainly no data-backed exemplar exists in the tree right now.
- [x] `Data.Content` trimmed: `issuesUrl`/`discussionsUrl` (Contact-only), the entire ~90-line Tottenham Hotspur fixtures section (Fixtures-only), the unused `Image` type, and `SiteInfo`'s never-read `description`/`email`/`facebookUrl`/`instagramUrl` fields are all gone. `bookingUrl`/`services`/`siteInfo.title`/`siteInfo.themeColor` kept — genuinely used.
- [x] `evals/evals/12-add-ui-component`'s `check.sh` repointed from the deleted `Contact` page to `Guarantees` (same breadcrumb pattern). Noted (not fixed, explicitly out of scope): the eval's actual premise — "About needs breadcrumbs added" — is now moot, since About/Guarantees/Docs all already carry them via the shared Editorial pattern. A real fix needs a different target scenario, which is a bigger task than this ticket's cleanup scope.
- [x] Full verify ladder: `make gate` (19/19), `make test` (214/214), `make format-check` all green. `make check`'s `generator-policy` step still fails in this sandbox only — confirmed to be this machine's `/tmp` mounted `noexec`, blocking any binary run from the fixture's temp copy; the other three design-policy scripts, `make assets-check`, and the real scaffolder (run three times against the actual tree in ticket 02) all pass. Documented on ticket 02, not re-litigated per page.
- [x] Branch pushed (`origin/clean-sheet-homepage`).
- [x] `/code-review` run. **Correction to this ticket's own instruction:** the fixed point named here, `02ba58e`, was stale — three more commits landed on `master` (`783dd6e`, `4327599`, `8bcd1ec`, `b444947`) between when the spec was drafted and when this branch actually forked. Verified the real fork point empirically (`git merge-base master clean-sheet-homepage` = `b444947` = `master`'s current tip) before reviewing, rather than trusting the stale note. Reviewed `git diff master...HEAD` (16 commits) instead.
- [x] Findings fixed or explicitly deferred — see below.

## Code review findings and disposition

Both axes (Standards, Spec sub-agents) converged on the same top finding independently, which is a strong signal it was real.

**Fixed:**
1. **Untranslated nav labels (real bug, both axes flagged it).** `nav.about`/`nav.guarantees`/`nav.docs` were the literal English strings in `fr`/`pt` — the scaffolder inserts the PascalCase name verbatim for every language by default, and none of tickets 03-06 (which translated page-body copy) touched the separate `nav` block. Now translated (fr: À propos/Garanties/Docs (bientôt); pt: Sobre/Garantias/Docs (em breve)). First attempted fix silently no-op'd (matched stale placeholder text from an earlier commit instead of the real content) — caught by re-running the verify ladder, not assumed fixed.
2. **`test/I18n/I18nSpec.purs`'s localization test was too weak to catch #1** — it only ever compared `nav.home` across languages, never the other three nav keys. Strengthened to check all four `nav` fields against both `fr` and `pt`.
3. **Wholesale test deletion contradicted the spec's own instruction.** Spec/ticket 01 said "trimmed... rather than deleted wholesale" for the route-generic test suites; `TemplateContractSpec.purs`, `ShellSpec.purs`, and `PolicySpec.purs` were deleted outright in ticket 01 (correctly, at the time — nothing survived the zero-route state) but never restored once Home/About existed again in tickets 02-04. Restored all three, trimmed to Home/About only (Contact/Posts/Fixtures assertions stay gone), re-wired into `test/Main.purs`. All pass.
4. **Placeholder SEO meta descriptions shipped as final content** (`"SEO for About."` etc., identical across all three languages) — real, distinct one-line descriptions written per page per language.
5. **Stale doc comment** in `App.Main.purs` ("Home only, so far") — updated to name all four current static routes.

**Explicitly deferred (not fixed):**
6. **Localized URL paths for `fr`/`pt`** (`routeCodec`'s About/Guarantees/Docs segments are `"about"`/`"guarantees"`/`"docs"` in every language, not e.g. `a-propos`/`sobre` like the deleted pages had). No spec/ticket line required localized paths — this is polish, not a broken promise. Real follow-up if picked up: needs `--slug-fr`/`--slug-pt` passed at scaffold time (or a manual `routeCodec` edit), plus a RouteSpec/sitemap check.
7. **`pageSlots` duplication** across `About`/`Guarantees`/`Docs` `View.purs` (near-identical `d.mission` → `valuesSlots`/`valueSextuple` → breadcrumbs shape). Three call sites of a short function — doesn't clear this repo's own bar against premature abstraction yet; revisit if a fourth Editorial page shows up.
8. **`SiteShell.purs`'s `githubLink` hand-writes `class_ "btn btn-ghost btn-sm"`** instead of reusing `navLinkClasses`. Not a real fit — `navLinkClasses` encodes active/inactive state for internal current-route highlighting, which an external link doesn't have. Left as-is.

## Comments

Spec: `.scratch/clean-sheet-homepage/spec.md`. This ticket is the final gate before the branch is considered done — now closed.
