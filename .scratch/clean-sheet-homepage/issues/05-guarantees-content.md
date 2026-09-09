# 05: Write the real Guarantees page

**What to build:** A dedicated page turning `GUARANTEES.md`'s guarantee table into real, readable site content — Pohjola's most distinctive, checkable claim ("if it compiles and CI is green, production doesn't crash," scoped honestly), presented as content a visitor would actually read, not a dumped markdown table. This page has no predecessor to be biased by or share sentences with — it's new content by construction.

**Blocked by:** 02

**Status:** done (2026-09-09), commit `7434b39` on branch `clean-sheet-homepage`

- [x] Every guarantee presented traces back to a real clause in `GUARANTEES.md` — no invented or embellished claims.
- [x] The page states the claim's honest scope up front (the "not 'no runtime errors' in the absolute" framing `GUARANTEES.md` itself opens with), not just the guarantee list stripped of its caveats.
- [x] Presented as real page content (readable prose/sections/cards as fits the design), not a raw markdown-table dump.
- [x] Real, native-reading translations for `en`/`fr`/`pt`.
- [x] DaisyUI-styled through `App.Ui` primitives, consistent with the rest of the site.
- [x] Idiomatic PureScript throughout (see ticket 03's idiom checklist).
- [x] `make dev`: manually viewed in a browser across all three language paths.
- [x] `make gate && make test` pass (19/19, 205/205). `make check`'s `generator-policy` step still fails in this sandbox only, for the pre-existing `/tmp noexec` reason recorded on ticket 02.

## Comments

Spec: `.scratch/clean-sheet-homepage/spec.md`.
