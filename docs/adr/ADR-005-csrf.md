# ADR-005: CSRF – token strategy tied to sessions

**Status:** Accepted
**Date:** 2026-08-04

## Context

Current CSRF mitigations are the Origin gate (`sameOriginOk` in `src/App/Main.purs`), a honeypot field, and (once present) SameSite cookies. With no session cookies today this is sufficient for the starter.

## Decision

* While the app does **not** have session cookies, the existing Origin‑gate + honeypot remains the complete CSRF story – no per‑request CSRF tokens are required.
* When session support (ADR‑004) is added and authenticated state‑changing actions appear, a per‑session CSRF token must be introduced:
  * The token is generated once per session and stored in the session payload.
  * It is sent to the client via a custom header (e.g. `X‑Csrf‑Token`) on the initial HTML response and mirrored in a hidden form field using the existing `App.Form` hidden‑field pattern.
  * The server validates the header or hidden field on any state‑changing request.
* No per‑request one‑time tokens will be invented; cross‑origin credentialed requests are never accepted.

## Consequences

* No additional code is required today – the trigger is binary: **if sessions exist, CSRF tokens are required**.
* Future implementations can reuse the `App.Form` hidden‑field mechanism and the session module from ADR‑004, keeping the surface area small and auditable.
