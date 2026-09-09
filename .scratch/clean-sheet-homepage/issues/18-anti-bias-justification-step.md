# 18: Decide whether to-spec/to-tickets should force an explicit anti-bias justification

**What to build:** About kept `Editorial`, the same template v1's About used, despite this effort's explicit "no bias from what exists" instruction — and no mechanical check would have caught "defaulted to the existing thing instead of re-deriving it," because the choice wasn't wrong on its own terms, just unoriginal. Candidate fix: when a spec/ticket explicitly says "no bias from existing X," `to-spec`/`to-tickets` require one sentence justifying every template/content choice against that instruction, so silently defaulting has to become a stated decision instead of an omission.

**Blocked by:** None (can start immediately)

**Status:** wontfix (2026-09-09) — decided by the user

- [x] Decided: this is fundamentally a "hold it via review, no mechanism" problem — no rule added to `to-spec`/`to-tickets`.

## Comments

From a `/grill-me` retrospective (2026-09-09). This was the one point in the retrospective with no confident recommended answer during grilling. User's decision (2026-09-09): skip — hold via review only.
