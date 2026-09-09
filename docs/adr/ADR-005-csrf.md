# ADR-005: CSRF – header-based rejection, tied to sessions

**Status:** Accepted
**Date:** 2026-08-04
**Amended:** 2026-09-09 — the token requirement is replaced with Lucia's actual header-based hierarchy (`Sec-Fetch-Site` primary, `Origin` secondary); a token is demoted to an explicit, optional legacy-browser fallback, not a requirement. See "Amendment" below before implementing anything from the original Decision as written.

## Context

Current CSRF mitigations are the Origin gate (`sameOriginOk` in
`src/App/Main.purs`) and a honeypot field. A supplied non-same-origin Origin is
rejected; an absent Origin is not itself treated as a cross-origin request.
That is distinct from credentialed cross-origin requests, which are never
accepted. Real sessions now exist (`App.Auth`, `ADR-002`'s Amendment,
2026-09-08) — the "legacy scaffolding, not production" auth code this
paragraph originally referred to is deleted.

## Amendment (2026-09-09): Lucia's header-based hierarchy replaces the token requirement

The original Decision below made a per-session token the mandatory mechanism
once sessions existed. Verified directly against Lucia's own CSRF guidance
(`auth.pilcrowonpaper.com/csrf`) — the pattern this project standardizes on
per `ADR-002`'s Amendment — the actual recommended hierarchy has the
opposite emphasis:

1. **Primary: `Sec-Fetch-Site` header.** Reject any non-GET/mutating request
   unless the header is present and equals `same-origin`. Sent by all
   modern browsers (Chrome/Edge since ~2020, Firefox 90+, Safari 16.4+);
   client-side JavaScript cannot forge it — it's a forbidden request header.
2. **Secondary: `Origin` header** (the existing `sameOriginOk` check) — for
   older browsers that don't send `Sec-Fetch-Site`, or to deliberately
   allow requests from subdomains if that's ever needed.
3. **Tertiary, explicitly optional: an anti-CSRF token.** Lucia's own
   framing: "the oldest way to prevent CSRF," recommended only for
   legacy-browser compatibility — not a requirement for a normal modern
   deployment. `SameSite` cookies alone are insufficient on their own (they
   don't block subdomain-to-subdomain requests, and legacy browsers ignore
   the attribute entirely), which is why the header checks above still
   matter — but a token is not required on top of them unless this project
   ever needs to support browsers old enough to lack `Sec-Fetch-Site`.

**Pohjola's own architecture strengthens the case for header-rejection over
a token, specifically:** the server and the website are the same origin —
there is no separate API domain, no legitimate cross-origin caller (no
mobile app, no third-party integration hitting an authenticated endpoint
from elsewhere). Rejecting anything that isn't `same-origin` therefore
costs nothing: there is no real client this project needs to accommodate
that a strict same-origin check would ever break.

**What's actually missing today is the `Sec-Fetch-Site` check itself.**
`sameOriginOk` only implements the secondary (`Origin`) layer — the primary
layer doesn't exist yet. Adding it is real, outstanding implementation
work; this amendment fixes the *decision*, not the code (see Consequences).

## Decision (superseded by the Amendment above where they conflict)

* While the app does **not** have session cookies, the existing Origin‑gate + honeypot remains the complete CSRF story – no per‑request CSRF tokens are required.
* ~~When session support (ADR‑004) is added and authenticated state‑changing actions appear, a per‑session CSRF token must be introduced~~ — superseded; see Amendment. Sessions now exist (`App.Auth`, `ADR-002`'s Amendment); the required mechanism is the `Sec-Fetch-Site`/`Origin` header hierarchy above, not a token.
* No per-request one-time token is required as the baseline mechanism; credentialed cross-origin requests are never accepted regardless. Absent `Origin` remains a separate case (see `sameOriginOk`) — the `Sec-Fetch-Site` check, once added, narrows this further since it doesn't depend on `Origin` being present at all.

## Consequences

* Real, outstanding work: add a `Sec-Fetch-Site` check (reject non-GET
  requests unless the header equals `same-origin`) alongside the existing
  `Origin` check, gating any future authenticated, state-changing route the
  same way `handleContact` already gates unauthenticated form submissions
  today. This is what `GUARANTEES.md`'s "CSRF is not optional... must land
  alongside or before real session auth ships" actually refers to — a
  header check, not a token build-out.
* A per-session token remains available as a documented fallback, not dead
  weight — if this project ever needs to support a browser old enough to
  lack `Sec-Fetch-Site`, add it then, scoped to that specific need, rather
  than building it speculatively now against a requirement that may never
  arrive.
* Future implementation reuses the existing `sameOriginOk` shape (extend it,
  or add a sibling check in `src/App/Main.purs`) — no new module, no new
  FFI boundary, no change to the FFI allowlist.
