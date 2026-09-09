# 08: Dedupe the repeated `flagName <> boolLit` shape in `xDataSiteChrome`

**What to build:** `App.Alpine`'s `xDataSiteChrome` builds its Alpine `x-data` object literal by inlining the same `flagName X <> ": " <> boolLit b` shape twice (once per flag), echoing `xDataFlag`'s single-field version just above it. Extract a small helper (e.g. `field name b = flagName name <> ": " <> boolLit b`) and join both fields with `", "` so the shape exists once.

**Blocked by:** None (can start immediately)

**Status:** done (2026-09-09), commit `9fdd516` on branch `master`

- [x] `xDataSiteChrome` no longer repeats the `flagName _ <> ": " <> boolLit _` literal inline
- [x] Behaviour unchanged (same rendered `x-data` string) — covered by existing `ContractSpec`/`ShellSpec` assertions
- [x] `make gate && make test` pass

## Comments

Found by the Standards-axis code review of `dadcfe3..HEAD` (5 post-push commits on `master`, reviewed 2026-09-09). Judgement-call smell (Duplicated Code), not a hard standards violation.
