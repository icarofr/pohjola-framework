# 03: Write the real Home page

**What to build:** The actual homepage content, on top of the frame ticket 02 built. Fresh hero (what Pohjola is, who it's for, inside one screen), a pillars/features section stating Pohjola's real differentiators as concrete checkable claims (compile-time guarantees, Bun-native speed, no-custom-JS Alpine seams — not marketing adjectives), and a CTA — structurally inspired by homepages of comparably-scoped frameworks (Astro, SvelteKit, Phoenix/LiveView, htmx, Elm-lang.org: tone and structure only, nothing copied), DaisyUI-styled through `App.Ui` primitives. Zero sentences carried over from the deleted `Home`/`About`/`Contact` copy.

**Blocked by:** 02

**Status:** done (2026-09-09), commit `6bfb7c3` on branch `clean-sheet-homepage`

- [x] Hero states what Pohjola is and who it's for, readable within one screen.
- [x] Every differentiator claim on the page is checkable against `GUARANTEES.md`/an ADR (same "sell it well but be realistic" discipline already established in this repo's copy).
- [x] Primary CTA (e.g. view the repository) and a secondary CTA present.
- [x] Real, native-reading translations for `en`/`fr`/`pt` — not literal machine ports of the English.
- [x] DaisyUI component classes visibly used through `App.Ui` wrappers — not raw utility soup, not hand-rolled CSS.
- [x] Idiomatic PureScript — this page's own code didn't need new logic (it's slot-filling through `landingSlots`/`landingFeatures`), so there was nothing to apply the guard/ExceptT idiom to; no `if`/`then`/`else` or staircases were introduced.
- [x] `make dev`: manually viewed in a browser across all three language paths — headline, pillars, and CTA all render correctly.
- [x] `make gate && make test` pass (19/19, 205/205). `make check`'s `generator-policy` step still fails in this sandbox only, for the pre-existing `/tmp noexec` reason recorded on ticket 02 — unrelated to this ticket's content.

## Comments

Spec: `.scratch/clean-sheet-homepage/spec.md`.
