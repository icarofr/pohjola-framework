# ADR-004: Sessions – cookie shape pinned

**Status:** Accepted (implementation pending)
**Date:** 2026-08-04

## Context

No session layer currently exists in the starter. A grep of `src/` for "set-cookie" or "Set-Cookie" returns no matches (none found today). Future apps will need sessions for login, carts, or multi‑step flows, and we want a fixed shape before each app invents its own.

## Decision (pin, no implementation)

* A dedicated module `src/App/Session.purs` will own all encode/decode/verify logic.
* Cookie name: `__Host-ps_session`.
* Cookie attributes: `HttpOnly; Secure; SameSite=Lax; Path=/` (no `Domain`).
* The cookie contains an opaque, cryptographically random 32-byte value. Only a cryptographic hash of that value is stored in PostgreSQL; session rows contain metadata, expiry, revoked state, and a per-session CSRF token.
* The token is a bearer value, not a signed or HMAC-protected payload. No new
  HMAC FFI boundary is required; secure random generation and SHA-256 hashing
  use the existing approved Bun boundary (with a separately justified
  allowlist entry only if implementation requires one).
* No sliding expiration: the server enforces a fixed 24-hour lifetime. Revocation is checked server-side.
* Session persistence is accessed through an injected session repository and
  the application-lifetime SQL handle; no global session store is introduced.
* One SQL handle is created for the application lifetime after synchronous migrations complete, and is closed during shutdown.

## Consequences

* Implementing sessions becomes a matter of a few hours rather than weeks; the security review of `Session.purs` covers all cookie handling.
* The exact schema and implementation remain pending; they must preserve this shape rather than reintroduce self-contained signed payloads.
