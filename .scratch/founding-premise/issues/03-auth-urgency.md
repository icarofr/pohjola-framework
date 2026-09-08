# 03: Is the missing auth/sessions/CSRF trio actually blocking anything?

**What to build:** Depends on the answer. If blocking: this stops being a ticket and becomes the real next implementation project (ADR-002/004/005, currently "Accepted — implementation pending"). If not blocking: no code, just a note confirming the deferral is still free.

`ADR-002` defers auth *implementation* on purpose, to fix the target shape before anyone needs it and avoid a "10 auth wrappers" drift pattern — a defensible reason to defer design. But git history (`56e2ab4`, `2b4b140`) confirms a private app already exists off this base. Is *that app* currently:

- blocked on login (working around it with something external — a third-party auth provider, a manual/no-auth admin path — or just not shipped yet because of this), or
- genuinely not needing a session yet, making the deferral free?

Recommended answer from the grilling session: probably not blocked yet — the scrubbed-references commits read like a marketing/portfolio move, not a "ship a feature" move. But this is the one fact in the whole batch only the user has; nothing in this repo's history proves it either way.

**Blocked by:** None (can start immediately) — but the answer here determines whether tickets exist past this point for auth work, so treat it as gating for any future auth-related ticket, not for 01/02/04.

**Status:** resolved

- [x] Answer recorded here or in a follow-up comment
- [x] Not blocked — deferred on purpose, documented as a known gap rather than silently implied

## Answer

Deferred, deliberately: "we ll defer auth now but keep it as a documented gap." Not urgent — nothing currently needs it — but the deferral must stay visible rather than implicit.

**Two concrete follow-throughs this implies:**
1. Ticket 05's gate-hole fix (make the gate's failure message name ADR-002) should land regardless of the bigger (a)/(b) enforcement decision there — it's the cheap part of "documented gap," making the one thing the gate does catch actually point somewhere.
2. Ticket 04 (README SaaS claim) should scope down rather than keep the claim as silent aspiration — "documented gap" and "README still claims SaaS fit with no caveat" are in tension; see ticket 04's resolution.

## Comments
