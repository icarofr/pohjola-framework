# 05: Write the real Guarantees page

**What to build:** A dedicated page turning `GUARANTEES.md`'s guarantee table into real, readable site content — Pohjola's most distinctive, checkable claim ("if it compiles and CI is green, production doesn't crash," scoped honestly), presented as content a visitor would actually read, not a dumped markdown table. This page has no predecessor to be biased by or share sentences with — it's new content by construction.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Every guarantee presented traces back to a real clause in `GUARANTEES.md` — no invented or embellished claims.
- [ ] The page states the claim's honest scope up front (the "not 'no runtime errors' in the absolute" framing `GUARANTEES.md` itself opens with), not just the guarantee list stripped of its caveats.
- [ ] Presented as real page content (readable prose/sections/cards as fits the design), not a raw markdown-table dump.
- [ ] Real, native-reading translations for `en`/`fr`/`pt`.
- [ ] DaisyUI-styled through `App.Ui` primitives, consistent with the rest of the site.
- [ ] Idiomatic PureScript throughout (see ticket 03's idiom checklist).
- [ ] `make dev`: manually viewed in a browser across all three language paths.
- [ ] `make gate && make test && make check` pass.

## Comments

Spec: `.scratch/clean-sheet-homepage/spec.md`.
