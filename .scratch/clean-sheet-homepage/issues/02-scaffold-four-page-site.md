# 02: Scaffold the four-page site and wire the navbar

**What to build:** The structural skeleton every content ticket fills in. Four pages — `Home`, `About`, `Guarantees`, `Docs` — regenerated through Pohjola's own `make new-feature` pipeline (this is the literal test of the pipeline the user asked for), each compiling, each reachable in all three languages, tied together by a real navbar: Home | About | Guarantees | Docs (labeled as coming-soon, not a dead link), plus an external GitHub link alongside the existing language-switcher/theme-toggle chrome. Content itself is placeholder at this stage — the deliverable is a correct, green, navigable frame.

**Blocked by:** 01

**Status:** done (2026-09-09), commits `3080163`, `c3f4eab`, `b59eefb` on branch `clean-sheet-homepage`

**Findings for whoever picks up 03-06:**
- Home was hand-wired (routing-duplex can't bootstrap the first route from
  zero — see ticket 01's finding); About/Guarantees/Docs were wired by the
  real `make new-feature ... WIRE=1 CHROME=1` command, run three times in
  the actual tree, no fixture. Two real bugs in `scripts/auto-scaffold.js`
  were found and fixed along the way (see commit `c3f4eab`): the `data
  Route` anchor broke once purs-tidy collapsed a single constructor to one
  line, and the `seo` record wiring anchored on a closing-brace pattern a
  single-line record doesn't have.
- `Home` uses the `Landing` template; `About`/`Guarantees`/`Docs` use the
  scaffold's default `Editorial` template (heading/body/values-grid) —
  worth reconsidering per-page in tickets 04-06 rather than assumed fixed.
- All copy everywhere right now is placeholder ("Placeholder pillar one",
  "Explore o About.", etc.) — tickets 03-06 replace it per page.
- `make check`'s `generator-policy` step still fails in this sandbox only
  (confirmed: this machine's `/tmp` is mounted `noexec`, blocking any
  binary run from the fixture's temp copy — unrelated to the code, the
  other three design-policy scripts and the real scaffolder all pass).

- [x] `make new-feature NAME=Home TYPE=static WIRE=1 CHROME=1` run, producing a compiling `Home` feature wired into `Data.Route`/`App.Main`/`Data.I18n`.
- [x] Same for `About`, `Guarantees`, `Docs` (`TYPE=static WIRE=1 CHROME=1` each).
- [x] For `Home`: decide deliberately whether the existing `Landing` `PageTemplate` (hero + 3-feature grid + CTA) still fits, or a different shape serves it better — a deliberate call either way, noted in the commit.
- [x] For `About`/`Guarantees`/`Docs`: use whatever simpler static-page template this repo's `TYPE=static` scaffold and conventions already provide, rather than forcing `Landing`'s homepage-specific shape onto non-homepage pages.
- [x] Navbar renders all four pages in order (Home, About, Guarantees, Docs) plus an external GitHub link, in all three languages, with `Docs` visibly marked as coming-soon (not a plain working link to empty content, and not a broken/dead link either).
- [x] `make gate && make test && make build` pass with the four pages in their placeholder state.
- [x] `make dev` serves all four pages, all three language paths, without error (manual spot check).

## Comments

Spec: `.scratch/clean-sheet-homepage/spec.md`. Site structure (four pages, this order) resolved in this session's ticket-planning round, not in the original spec draft.
