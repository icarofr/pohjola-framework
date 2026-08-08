# ADR-004: Sessions – cookie shape pinned

**Status:** Accepted
**Date:** 2026-08-04

## Context

No session layer currently exists in the starter. A grep of `src/` for "set-cookie" or "Set-Cookie" returns no matches (none found today). Future apps will need sessions for login, carts, or multi‑step flows, and we want a fixed shape before each app invents its own.

## Decision (pin, no implementation)

* A dedicated module `src/App/Session.purs` will own all encode/decode/verify logic.
* Cookie name: `ps_session`.
* Cookie attributes: `HttpOnly; Secure; SameSite=Lax; Path=/` (no `Domain`).
* Payload format: URL‑safe base64 of a JSON payload, followed by a `.` and an HMAC‑SHA256 signature (`payload.signature`).
* The secret key comes from the `SESSION_SECRET` environment variable; the server must fail fast at boot if sessions are used and the secret is absent.
* The payload type is a closed ADT defined per app, e.g. `data SessionData = …`. Encoding uses the existing Argonaut JSON library; no self‑describing or JS‑into‑cookie format.
* No sliding expiration in v1 – a fixed TTL of 24 h is set via the `Expires` attribute.

## Consequences

* Implementing sessions becomes a matter of a few hours rather than weeks; the security review of `Session.purs` covers all cookie handling.
* Revocation of compromised sessions is left as a future concern (e.g. server‑side deny‑list) and can be added without breaking the pinned shape.
