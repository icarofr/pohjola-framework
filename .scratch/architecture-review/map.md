# Architecture review follow-through

## Destination

Resolve the two open findings from the 2026-09-15 `/improve-codebase-architecture` review that need a human design decision rather than a mechanical fix: the auto-scaffold generator's lack of a real seam into the types it wires, and `App.Layout.Page`'s duplicated (not dead) document-shell construction in `renderErrorPage`. Destination reached when both have either a chosen design or an explicit "not now."

## Notes

- Ground both in `codebase-design` vocabulary (module/interface/seam/depth) and `CONTEXT.md`.
- Neither candidate is currently gated by an ADR; check `docs/adr/` again before finalizing in case one is warranted on the way out (per `domain-modeling`'s ADR criteria).
- The report itself: `/tmp/architecture-review-20260915-150902.html` (this machine, may not survive a reboot — re-run `/improve-codebase-architecture` if gone).

## Decisions so far

- [Delete dead renderShellOpen/renderShellClose from App.Layout.Page](https://github.com/icarofr/pohjola-framework/commit/b5534ed44485b3fd64db16b6f1a548cad0682126): zero production call sites confirmed via grep; deleted along with the two ContractSpec tests that only asserted on the dead functions' own output. CI green.
- [renderErrorPage head merge](issues/02-error-page-head-merge.md): kept the two head contents separate (legitimate difference, not a bug) but extracted the shared doctype/html/body/scripts skeleton into one `renderShell` seam. Commit `373b471`.

## Not yet specified

- Whether `renderErrorPage`'s deliberately-minimal head (no canonical/hreflang/OG — error pages have no single canonical Route) should stay a hand-built second construction, or whether `renderDocumentExtraHead` should grow a "minimal head" mode it can opt into. Not yet ticketed: needs a look at every other `renderHead` caller first to judge whether a mode-switch cheapens that seam for everyone else.

## Out of scope

(none yet)
