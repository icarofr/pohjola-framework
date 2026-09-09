# 03: Write the real Home page

**What to build:** The actual homepage content, on top of the frame ticket 02 built. Fresh hero (what Pohjola is, who it's for, inside one screen), a pillars/features section stating Pohjola's real differentiators as concrete checkable claims (compile-time guarantees, Bun-native speed, no-custom-JS Alpine seams — not marketing adjectives), and a CTA — structurally inspired by homepages of comparably-scoped frameworks (Astro, SvelteKit, Phoenix/LiveView, htmx, Elm-lang.org: tone and structure only, nothing copied), DaisyUI-styled through `App.Ui` primitives. Zero sentences carried over from the deleted `Home`/`About`/`Contact` copy.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Hero states what Pohjola is and who it's for, readable within one screen.
- [ ] Every differentiator claim on the page is checkable against `GUARANTEES.md`/an ADR (same "sell it well but be realistic" discipline already established in this repo's copy).
- [ ] Primary CTA (e.g. view the repository) and a secondary CTA present.
- [ ] Real, native-reading translations for `en`/`fr`/`pt` — not literal machine ports of the English.
- [ ] DaisyUI component classes visibly used through `App.Ui` wrappers — not raw utility soup, not hand-rolled CSS.
- [ ] Idiomatic PureScript (guarded `case` over nested `if`/`then`/`else`, `ExceptT`-style composition over staircases, ADTs over stringly-typed branching); Haskell-idiom fallback only where PureScript has no equivalent; no procedural style.
- [ ] `make dev`: manually viewed in a browser across all three language paths — looks like a finished homepage, not a wireframe.
- [ ] `make gate && make test && make check` pass.

## Comments

Spec: `.scratch/clean-sheet-homepage/spec.md`.
