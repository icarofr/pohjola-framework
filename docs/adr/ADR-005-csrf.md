# ADR-005: CSRF – token strategy tied to sessions

**Status:** Accepted
**Date:** 2026-08-04

## Context

Current CSRF mitigations are the Origin gate (`sameOriginOk` in
`src/App/Main.purs`) and a honeypot field. A supplied non-same-origin Origin is
rejected; an absent Origin is not itself treated as a cross-origin request.
That is distinct from credentialed cross-origin requests, which are never
accepted. Current auth/session code is legacy scaffolding, not production.

## Decision

* While the app does **not** have session cookies, the existing Origin‑gate + honeypot remains the complete CSRF story – no per‑request CSRF tokens are required.
* When session support (ADR‑004) is added and authenticated state‑changing actions appear, a per‑session CSRF token must be introduced:
  * The token is generated once per session and stored with the server-side session row.
  * It is sent to the client via a custom header (e.g. `X‑Csrf‑Token`) on the initial HTML response and mirrored in a hidden form field using the existing `App.Form` hidden‑field pattern.
  * The server validates the header or hidden field on any state‑changing request.
* No per-request one-time tokens will be invented; credentialed cross-origin
  requests are never accepted. Absent Origin remains a separate case.

## Consequences

* No additional code is required today – the trigger is binary: **if sessions exist, CSRF tokens are required**. This is a pending implementation requirement, not a claim about current source.
* Future implementations can reuse the `App.Form` hidden‑field mechanism and the session module from ADR‑004, keeping the surface area small and auditable.
