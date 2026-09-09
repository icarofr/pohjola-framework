# 18: Decide whether to-spec/to-tickets should force an explicit anti-bias justification

**What to build:** About kept `Editorial`, the same template v1's About used, despite this effort's explicit "no bias from what exists" instruction — and no mechanical check would have caught "defaulted to the existing thing instead of re-deriving it," because the choice wasn't wrong on its own terms, just unoriginal. Candidate fix: when a spec/ticket explicitly says "no bias from existing X," `to-spec`/`to-tickets` require one sentence justifying every template/content choice against that instruction, so silently defaulting has to become a stated decision instead of an omission.

**Blocked by:** None (can start immediately)

**Status:** ready-for-human

- [ ] Decide: is this worth doing at all, or is it fundamentally a "hold it via review, no mechanism" problem with no real fix?
- [ ] If yes, write the rule into the `to-spec`/`to-tickets` skill files (also outside this repo, like ticket 17)

## Comments

From a `/grill-me` retrospective (2026-09-09). This is the one point in the retrospective with no confident recommended answer — flagged during grilling as "genuinely unsure," leaning toward writing the rule anyway since it at least converts a silent default into a reviewable sentence, without believing it fully solves the underlying judgment problem. Left open for the user's call.
