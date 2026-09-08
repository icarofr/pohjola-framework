# ADR-004: Sessions – cookie shape pinned

**Status:** Accepted — superseded by `ADR-002`'s Amendment (2026-09-08); see "Superseded by ADR-002" below before reading the original decision as current.
**Date:** 2026-08-04

## Superseded by ADR-002 (2026-09-08)

`ADR-002`'s Amendment adopted Lucia's session pattern in full, which pins a
**different, incompatible shape** than the "Decision" section below. Do not
implement anything on this page as written — read `ADR-002` and
`docs/conventions/auth-lucia-arctic.md` instead. Concretely, what changed:

- **Module:** `src/App/Auth.purs` (implemented), not `src/App/Session.purs`
  (this page's original name; never built).
- **Token shape:** an `id.secret` split (16-byte id, 32-byte secret,
  Lucia's exact encoding), not this page's single opaque 32-byte value.
- **Expiry:** sliding 10-day renewal, not this page's fixed 24-hour
  lifetime — the opposite of what this page originally pinned.
- **CSRF:** this page specified "a per-session CSRF token" as part of the
  session row itself. The implemented `sessions` table
  (`migrations/002_create_sessions.sql`) has no such column — CSRF is
  entirely `ADR-005`'s separate, still-pending concern, not bundled into
  session storage. Don't add a CSRF column here to match this page; amend
  `ADR-005` instead if that's ever revisited.
- **Persistence:** `App.Auth` connects per-call via `App.Data.SQL`
  (matching `App.Features.Posts.Service`'s existing pattern), not this
  page's "injected session repository and the application-lifetime SQL
  handle" (`ADR-009` Phase 3B, itself still pending, unrelated to this).

This page is kept for historical context (it's why `ADR-002`'s Amendment
exists at all — the shape needed pinning before implementation, this page
did that first) — treat everything below as superseded, not current.

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
