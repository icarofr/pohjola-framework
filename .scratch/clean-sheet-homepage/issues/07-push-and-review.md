# 07: Final cleanup, push, and code review

**What to build:** The branch in a genuinely shippable state, pushed, and reviewed. Folds in the small cross-cutting cleanup items the spec flagged as too small to warrant their own ticket.

**Blocked by:** 03, 04, 05, 06

**Status:** ready-for-agent

- [ ] `CLAUDE.md`'s `## Task → one doc` exemplar line ("Exemplars: About (static), Posts (data)") updated to point at real files in the rebuilt tree (e.g. `Home`/`About` as the static exemplars — `Posts` no longer exists, note that a data-feature exemplar is currently absent rather than pointing at nothing).
- [ ] `Data.Content` trimmed of any constant none of the four new pages reference (e.g. `issuesUrl`/`discussionsUrl` if nothing uses them); anything still referenced (e.g. `bookingUrl`, the `Service` list backing Home's pillars) kept.
- [ ] `evals/evals/12-add-ui-component`'s dependency on `About`/`Contact` resolved one way or the other: if `check.sh` doesn't actually depend on those pages, leave a note; if it does, fix the eval so it isn't silently broken by this branch.
- [ ] Full verify ladder passes on the final state: `make gate && make test && make format-check && make check`.
- [ ] Branch pushed.
- [ ] `/code-review` run with the fixed point set to `master`'s tip as of this spec (`02ba58e`), reviewing the whole purge+rebuild diff as one unit against both axes (this spec, and this repo's documented standards + Fowler smell baseline).
- [ ] Findings from the review either fixed or explicitly deferred with a stated reason — not silently dropped.

## Comments

Spec: `.scratch/clean-sheet-homepage/spec.md`. This ticket is the final gate before the branch is considered done.
