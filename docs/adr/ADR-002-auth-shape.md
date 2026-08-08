# ADR-002: Auth shape — PS-first assembly behind App.Auth

**Status:** Accepted (interface fixed by stub; implementation pending)
**Date:** 2026-08

## Context

The starter ships no auth. Auth is the domain where parallel implementations
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

**Implementation (defaults marked; choose at implementation time):**

| Concern | Options | Default |
|---|---|---|
| Password hashing | `Bun.password` (native argon2, zero-dep) / `node:crypto` scrypt (portable) | **`Bun.password`** |
| Session store | `bun:sqlite` (embedded, zero-dep) / `Bun.sql` (native Postgres client, zero-dep) / `yoga-postgres` (PS-first, portable) | **`bun:sqlite`** for small apps; **`Bun.sql`** or **`yoga-postgres`** when Postgres exists |
| Session token | HMAC-signed random `uuidv4` in an `HttpOnly; Secure; SameSite=Strict` cookie | yes |
| Expiry | `datetime` + `now`; server-side expiry in the store | yes |
| Alternative | `yoga-better-auth` (registry, rowtype-yoga — PS bindings to better-auth) | **evaluate BEFORE hand-rolling** |

FFI required: exactly one small tamed module (hashing + HMAC), targeting
Bun-native per `docs/ffi-taming-guide.md`. Allowlist entry + this ADR satisfy
the taming recipe.

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
