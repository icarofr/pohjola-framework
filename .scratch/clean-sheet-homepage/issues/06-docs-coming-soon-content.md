# 06: Write the real Docs (coming soon) page

**What to build:** An honest coming-soon page for docs — a real headline and a one-line explanation of what's coming, not a dead stub with no content and not a page that pretends docs already exist.

**Blocked by:** 02

**Status:** done (2026-09-09), commit `8200f3a` on branch `clean-sheet-homepage`

- [x] Page clearly communicates docs are coming, not yet available — no broken links, no placeholder lorem ipsum.
- [x] One-line explanation of what the docs will cover once they land.
- [x] Real, native-reading translations for `en`/`fr`/`pt`.
- [x] DaisyUI-styled through `App.Ui` primitives, consistent with the rest of the site.
- [x] Idiomatic PureScript throughout (see ticket 03's idiom checklist).
- [x] `make dev`: manually viewed in a browser across all three language paths.
- [x] `make gate && make test` pass (19/19, 205/205). `make check`'s `generator-policy` step still fails in this sandbox only, for the pre-existing `/tmp noexec` reason recorded on ticket 02.

## Comments

Spec: `.scratch/clean-sheet-homepage/spec.md`.
