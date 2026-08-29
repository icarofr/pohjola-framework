# ADR-002: Auth shape — PS-first assembly behind App.Auth

**Status:** Accepted (target interface fixed; current scaffold is legacy and production implementation pending)
**Date:** 2026-08

## Context

The starter's current auth module is legacy in-memory scaffolding, not a
production session implementation. Auth is the domain where parallel implementations
accumulate fastest ("10 auth wrappers"): the first agent to need auth defines
the shape every later agent inherits. The shape is therefore fixed BEFORE the
first implementation, by the stub at `src/App/Auth.purs`. Deployment is 100%
Bun (vendored 1.4.0 source verified for the native APIs below).

## Decision

**Interface (fixed):** all auth flows go through `App.Auth` —
`requireAuth :: Maybe String -> Aff (Either AppError Session)`,
`createSession`, `destroySession`, `UserId` / `SessionId` / `Session`.
No inline session checks in `Main.purs` or feature modules. Session cookies
over JWT: an SSR MPA fits server-side sessions; revisit only if a second
(API) client appears.

**Implementation (approved shape; implementation pending):**

| Concern | Options | Default |
|---|---|---|
| Password hashing | `Bun.password` (native argon2, zero-dep) / `node:crypto` scrypt (portable) | **`Bun.password`** |
| Session store | PostgreSQL rows through `Bun.sql` | **required** |
| Session token | Opaque random 32-byte value in a `__Host-ps_session` cookie; only its hash is stored | **required** |
| Expiry and revocation | Fixed 24-hour server-side expiry and an explicit revoked state | **required** |
| Alternative | `yoga-better-auth` (registry, rowtype-yoga — PS bindings to better-auth) | **evaluate BEFORE hand-rolling** |

The opaque bearer token does not use HMAC: its security comes from the
cryptographically random 32-byte value, server-side SHA-256 hash lookup, fixed
expiry, and revocation. No new HMAC boundary is required. Secure random
generation, token hashing, and password operations use the existing approved
Bun boundary, subject to the allowlist in `docs/ffi-taming-guide.md`; add a
new explicitly justified allowlist entry only if the implementation requires
one.

The session repository is an injected dependency of the auth/session service;
handlers call that service rather than accessing SQL or a global store. The
repository owns persistence and is not an in-memory `Ref (Map ...)` in
production. Authentication failures remain
`Unauthorized` (401), while authenticated callers lacking permission remain
`Forbidden` (403). The repository uses the one application-lifetime SQL handle
approved by ADR-009. Implementation remains pending.

## Explicitly rejected

- Inline auth logic in `Main.purs` handlers — creates the 10-wrappers pattern.
- `Ref (Map SessionId Session)` in-memory store — dev-only, breaks in prod
  silently; `bun:sqlite` is the same effort and actually persists.
- JWT / stateless tokens — no second client; revocation matters more.
- Taming `better-auth` directly without evaluating `yoga-better-auth` first.

## Consequences

- A new `AppError` variant `Unauthorized` (→ 401) will be needed at
  implementation time; the compiler will enumerate every handler site.
- Protected routes: wrap the protected branches of `pageRenderer` with
  `requireAuth` (errors-as-values pattern; no middleware framework).
- Any deviation from this ADR requires amending it first.
