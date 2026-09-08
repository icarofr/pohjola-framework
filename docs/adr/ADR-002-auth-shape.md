# ADR-002: Auth shape — PS-first assembly behind App.Auth

**Status:** Accepted — session lifecycle implemented (`App.Auth`, 2026-09-08). CSRF (ADR-005) is a separate, still-pending ADR; see GUARANTEES.md's "Sessions (App.Auth) — implemented, CSRF is not" section before wiring `requireAuth` into any mutating route. No users table, registration, or login UI exists (out of this ADR's scope — see module header of `App.Auth`).
**Date:** 2026-08
**Amended:** 2026-09-08 — session-token/expiry model replaced with Lucia's pattern, adopted in full (see "Amendment" below); implemented same day.

## Context

Auth is the domain where parallel implementations accumulate fastest ("10
auth wrappers"): the first agent to need auth defines the shape every later
agent inherits. The shape was therefore fixed BEFORE the first
implementation, originally by a legacy in-memory stub
(`src/App/Auth/Scaffold.purs`, deleted 2026-09-08 once the real
implementation landed). Deployment is 100% Bun (vendored 1.4.0 source
verified for the native APIs below).

**Amendment context (2026-09-08):** rather than hand-roll a session-token design,
every Pohjola-based project standardizes on
[Lucia's session pattern](https://auth.pilcrowonpaper.com/sessions) — a
maintained, widely-reviewed reference design (the Lucia npm package itself is
deprecated in favor of copy-paste reference code;
[`code/auth_session.ts`](https://github.com/lucia-auth/lucia/blob/main/code/auth_session.ts)
in the `lucia-auth/lucia` repo is the canonical reference, explicitly framed by
its own README as "a complete, single-file replacement for the NPM package").
Adopted in full, no compromises: the id/secret token split and sliding
renewal below are both taken as specified, not partially adopted.

## Decision

**Interface (fixed):** all auth flows go through `App.Auth` —
`requireAuth :: Maybe String -> Aff (Either AppError Session)`,
`createSession`, `destroySession`, `UserId` / `SessionId` / `Session`.
No inline session checks in `Main.purs` or feature modules. Session cookies
over JWT: an SSR MPA fits server-side sessions; revisit only if a second
(API) client appears.

**Implementation (implemented — `App.Auth`, 2026-09-08):**

| Concern | Options | Default |
|---|---|---|
| Password hashing | `Bun.password` (native argon2, zero-dep) / `node:crypto` scrypt (portable) | **`Bun.password`** |
| Session store | PostgreSQL rows through `Bun.sql` | **required** |
| Session token | Lucia's id/secret split (see Amendment) in a `__Host-ps_session` cookie; only the secret's hash is stored, keyed by id | **required** |
| Expiry and revocation | Lucia's sliding renewal (see Amendment) and an explicit revoked state | **required** |
| Alternative | `yoga-better-auth` (registry, rowtype-yoga — PS bindings to better-auth) | **evaluate BEFORE hand-rolling** |

Secure random generation, token hashing, and password operations use the
existing approved Bun boundary, subject to the allowlist in
`docs/ffi-taming-guide.md`; add a new explicitly justified allowlist entry
only if the implementation requires one (it should not — see Amendment).

## Amendment (2026-09-08): full adoption of Lucia's session pattern

Supersedes the original single-opaque-token, fixed-24h-expiry design below.
This project standardizes on Lucia's model exactly, so that every Pohjola-based
project shares one tried-and-tested auth approach rather than each fork
re-deriving its own token/expiry policy. OAuth (Arctic's reference pattern)
is adopted as a tracked follow-on to sessions, not a blocker.

**Full pattern detail, Bun-native mapping, and OAuth/Arctic reference:**
see [`docs/conventions/auth-lucia-arctic.md`](../conventions/auth-lucia-arctic.md).
This ADR records the decision; that doc records the how.

The two changes versus the original Decision table above, in one line each:
- **Token:** id/secret split (was: single opaque token) — the `id` half is
  new surface area, taken on purpose for future session-reference/revocation
  value, not because a specific feature needs it yet.
- **Expiry:** sliding 10-day renewal (was: fixed 24h) — an active session
  effectively never expires while in use; an idle one expires 10 days after
  its last use.

FFI: every primitive the amendment needs already exists in
`App.Bun`/`App.ServerBun`/`App.Data.SQL` — no new FFI module or allowlist
entry required.

`App.Auth`'s functions connect via `App.Data.SQL` per-call (`Config.databaseUrl`),
the same pattern already established by `App.Features.Posts.Service` — not
the one application-lifetime handle ADR-009 Phase 3B still has pending.
Session persistence is not an in-memory `Ref (Map ...)` in production
(explicitly rejected, see below). Authentication failures return
`Unauthorized` (401); a distinct `Forbidden` (403) for authenticated callers
lacking permission is not yet needed (nothing in this codebase does
authorization beyond authentication) and is not implemented.

## Explicitly rejected

- Inline auth logic in `Main.purs` handlers — creates the 10-wrappers pattern.
- `Ref (Map SessionId Session)` in-memory store — dev-only, breaks in prod
  silently; `bun:sqlite` is the same effort and actually persists.
- JWT / stateless tokens — no second client; revocation matters more.
- Taming `better-auth` directly without evaluating `yoga-better-auth` first.

## Consequences

- `AppError`'s `Unauthorized` variant (→ 401) is added; `errorStatus` in
  `Main.purs` maps it.
- Protected routes: wrap the protected branches of `pageRenderer` with
  `requireAuth` (errors-as-values pattern; no middleware framework). No
  route does this yet — no protected page exists in the current feature set.
- Any deviation from this ADR requires amending it first.
