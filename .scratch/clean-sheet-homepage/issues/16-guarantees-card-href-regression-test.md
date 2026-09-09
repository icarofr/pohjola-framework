# 16: Regression test for the Guarantees card-href bug

**What to build:** ~~All three Guarantees cards ("View the policy gate" / "View the source" / "View the CI config") linked to the same `bookingUrl` (repo root) regardless of which claim they backed.~~ Already fixed and now covered by a real test.

**Blocked by:** None

**Status:** done (2026-09-09), commit `684c525` on branch `master`

- [x] Source fix: commit `1c0c2d2` — each card now links to its own `Data.Content` constant (`policyGateUrl`, `htmlSourceUrl`, `ciConfigUrl`)
- [x] Regression test: commit `684c525` — `TemplateContractSpec`'s guarantees test asserts each of the three hrefs individually, not just card count

Deliberately **not** a generic repo-wide "N items must have pairwise-distinct hrefs" rule (considered and rejected during grilling) — real cases exist where two distinct items correctly share a target (e.g. two nav entries both pointing at Home), so a generic invariant would be wrong on purpose.

## Comments

From a `/grill-me` retrospective (2026-09-09). Closed on filing — both halves (fix + test) were already done earlier in this session.
