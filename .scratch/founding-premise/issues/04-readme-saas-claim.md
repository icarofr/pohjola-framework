# 04: Scope down (or keep) the README's "SaaS/commerce" fit claim

**What to build:** Depends on the decision. If scoping down: a small `README.md` edit to the "When Pohjola is the Right Fit" list. If keeping: no code, just a recorded reason.

`docs/GUARANTEES.md` is unusually honest everywhere it self-limits (named exemptions for the streaming shell, the `el (`-scan hole, the FFI marshalling exemption). The README doesn't match that standard in one place: "When Pohjola is the Right Fit" lists "commerce, and SaaS platforms," while there is no auth, no sessions, no CSRF, and no billing/tenancy primitive anywhere in `src/` today (see ticket 03 — this is a real, not hypothetical, gap).

Two honest options, not one right answer:

- **(a)** Scope the line down to what's true today (content/dashboard hypermedia sites) and re-add "commerce, SaaS" the day ADR-002/004/005 actually ship — matches the audit's own praise for this project ("honest where the repo says it's honest").
- **(b)** Keep the claim as a stated aspiration, since ADR-002/004/005 already fix the target shape (this isn't vague hand-waving, it's a concrete pending spec) — but if so, the README should say so explicitly ("commerce/SaaS: target shape fixed by ADR-002, implementation pending") rather than reading as already-shipped capability.

Recommended answer from the grilling session: (a), or (b)-with-explicit-caveat if the user prefers not to lose the forward-looking claim entirely. Either way, silent overselling is the one thing to avoid, since it's the one spot where the README doesn't live up to the rest of the repo's own documented standard.

**Blocked by:** 01 (purpose) — resolved.

**Status:** resolved

- [x] Decision recorded here
- [x] `README.md`'s "When Pohjola is the Right Fit" section edited accordingly

## Answer

(a), effectively — user confirmed the blocker is precisely auth (plus sessions/CSRF, the same "implementation pending" trio) when asked directly: "is the blocker the lack of auth?" Combined with ticket 03's resolution (auth deferred but must stay a *documented* gap, not silently implied), the README claim needed to move.

Landed: "Content, dashboard, commerce, and SaaS platforms" split into "Content and dashboard platforms" (kept in Right Fit) plus a new "Not yet a fit" line naming commerce/SaaS explicitly, pointing at ADR-002/004/005, with an explicit "this line moves up once that lands" — matches (b)-with-caveat from the original option set: the aspiration isn't deleted, it's stated as pending rather than implied as shipped.

## Comments
