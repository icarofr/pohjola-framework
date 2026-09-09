# 02: Scaffold the four-page site and wire the navbar

**What to build:** The structural skeleton every content ticket fills in. Four pages — `Home`, `About`, `Guarantees`, `Docs` — regenerated through Pohjola's own `make new-feature` pipeline (this is the literal test of the pipeline the user asked for), each compiling, each reachable in all three languages, tied together by a real navbar: Home | About | Guarantees | Docs (labeled as coming-soon, not a dead link), plus an external GitHub link alongside the existing language-switcher/theme-toggle chrome. Content itself is placeholder at this stage — the deliverable is a correct, green, navigable frame.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] `make new-feature NAME=Home TYPE=static WIRE=1 CHROME=1` run, producing a compiling `Home` feature wired into `Data.Route`/`App.Main`/`Data.I18n`.
- [ ] Same for `About`, `Guarantees`, `Docs` (`TYPE=static WIRE=1 CHROME=1` each).
- [ ] For `Home`: decide deliberately whether the existing `Landing` `PageTemplate` (hero + 3-feature grid + CTA) still fits, or a different shape serves it better — a deliberate call either way, noted in the commit.
- [ ] For `About`/`Guarantees`/`Docs`: use whatever simpler static-page template this repo's `TYPE=static` scaffold and conventions already provide, rather than forcing `Landing`'s homepage-specific shape onto non-homepage pages.
- [ ] Navbar renders all four pages in order (Home, About, Guarantees, Docs) plus an external GitHub link, in all three languages, with `Docs` visibly marked as coming-soon (not a plain working link to empty content, and not a broken/dead link either).
- [ ] `make gate && make test && make build` pass with the four pages in their placeholder state.
- [ ] `make dev` serves all four pages, all three language paths, without error (manual spot check).

## Comments

Spec: `.scratch/clean-sheet-homepage/spec.md`. Site structure (four pages, this order) resolved in this session's ticket-planning round, not in the original spec draft.
