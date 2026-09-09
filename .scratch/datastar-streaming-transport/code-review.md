# /code-review: spike/datastar-shell-nav-port vs master

Fixed point: `master` (merge-base `9996f17`). Reviewed at branch tip `5ce1a8a`
(before the post-review fixes below landed). Spec: `spec.md` + `issues/02`–`05`.

## Standards

Framing accepted by both reviewers: throwaway comparison spike, not merging.
Judged accordingly — English-only "GH" label, minimal error handling on
Home/About-only paths, and lack of i18n for Datastar-only chrome were **not**
flagged as in-scope cuts.

**Hard violation — fixed:** `App.Server.sseEventResponse` hardcoded the
literal `"datastar-request"` for its `Vary` header instead of importing
`Datastar.datastarRequestHeader`, the constant `App.Main` correctly uses for
the same value — two independent code paths setting the same header, one
via a named constant, one via a copy-pasted literal.

**Judgement calls, real smells — fixed:**
- `App.DatastarShell` re-duplicated three class-string literals
  (`text-primary font-semibold` active-nav treatment, the dropdown panel
  class, the dropdown item class) that `App.Alpine` already centralizes
  (`navLinkClasses`, `dropdownPanelClass`, `dropdownItemClass`) "so shell
  edits cannot forget them" — the same rationale applied here.
- `footerLink lang _ target label` discarded its `current` param, silently
  dropping `aria-current="page"` while a comment claimed markup-shape parity
  with `SiteShell.footerLink` (which sets it via `navLink`).
- `contentTarget = "content"` was independently redefined in `App.Datastar`,
  unused, while `App.DatastarShell` hardcoded `"content"` directly instead
  of importing either constant.

All four fixed post-review; see `findings.md`'s update note.

## Spec

**Missing, now fixed:** Ticket 02's checkbox claimed `datastar.js` was
"vendored... self-hosted and checksummed like the existing Alpine assets" —
it wasn't. The file was fetched from a moving `@main` ref with no entry in
`static/assets/SHA256SUMS` and no `make assets-check` coverage. Fixed: pinned
to a specific commit SHA (`ab49c21...`) via jsdelivr's `gh` provider, added
to `SHA256SUMS`, and added `assets-datastar-spike`/`assets-check-datastar-spike`
Makefile targets (kept separate from the production Alpine `assets`/
`assets-check` targets, which stay untouched).

**Missing, now fixed — the important one:** nav links to `Guarantees`/`Docs`
(explicitly out of scope per spec.md) were rendered with `dsNavGet` anyway,
inherited from `shellLabels`' full four-link set. `handleDatastarFragment`
has no route guard, and `datastarInnerContent`'s catch-all is `text ""` — so
clicking either link from the `?ds=1` shell patched `#content` to empty
instead of navigating. `findings.md`'s original parity checklist never
exercised this path. Fixed: `isDatastarPortedRoute` gates `dsNavGet` to
`Home`/`About` only; every other nav target is now a real, unadorned link
that falls through to a normal full-page load.

**Confirmed correct (no changes needed):**
- The three bugs `findings.md` claimed as fixed (`type="module"`, the
  `'\\n\\n'` escape, the `Vary` headers) are genuinely present and correct
  in the diff.
- `isDatastarRequest`/`isFragmentRequest` are kept properly separate in
  `App.Main`, matching ticket 02's "never conflated" requirement.
- `SiteShell.purs` and `Alpine.purs` are confirmed absent from the diff
  entirely — the Alpine baseline is genuinely untouched.
- No Datastar Pro-tier attributes anywhere in the diff.

**Noted, not a real issue:** `src/App/Layout/Styles.purs` (the embedded
Tailwind/DaisyUI CSS bundle) regenerated wholesale in this branch's commits.
This is the same automatic `make build`/`make run` byproduct that has
regenerated alongside every class-string change all session — not a
hand-edited scope-creep change, just the mechanical output of running the
build after touching classes DatastarShell also happens to use.

## Summary

Standards: 4 findings (1 hard violation, 3 judgement calls) — all fixed.
Worst issue: the hardcoded header literal duplicating a named constant right
next to the correctly-imported Alpine equivalent.

Spec: 2 findings (both "claimed done, wasn't") — both fixed. Worst issue:
the Guarantees/Docs dead-link bug — a real, reachable regression the
original verification pass never exercised, caught only by this review.

Branch re-verified after all fixes (`make gate` 20/20, `make test` 229/229,
live playwright-core recheck of the full parity checklist plus the
previously-untested Guarantees-link path) before this report was written.
