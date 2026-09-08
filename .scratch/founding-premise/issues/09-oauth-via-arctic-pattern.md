# 09: OAuth/social login — port Arctic's reference flow, feed into the same session path

**What to build:** `App.Auth` OAuth support, following the same "port the reference pattern, Bun-native" approach as ticket 08 — this is a separate porting effort, not part of the core session work.

## What exists (verified, not assumed)

Lucia itself has no OAuth story — the Auth Book (`auth.pilcrowonpaper.com`, same docs site as the sessions guide) has no OAuth chapter. The actual reference is a separate project by the same author: [Arctic](https://github.com/pilcrowonpaper/arctic) (1.7k★, MIT/Zero-Clause BSD, active as of 2026-08). Arctic followed Lucia's exact same path — deprecated as an installable package in favor of reference code under `code/`:

- `authorization_request.ts` / `authorization_request-pkce.ts`
- `authorization_code_exchange.ts` / `authorization_code_exchange-pkce.ts`
- `refresh_request.ts`
- `token_revocation_request.ts`

These are provider-agnostic (works against any OAuth 2.0 provider's endpoints, not a per-provider SDK) and framework-agnostic (explicit `todo.*` placeholders for request/response glue) — covers the full authorization-code flow with and without PKCE, refresh, and revocation.

## The integration seam

Not a documented API, but structural: `authorization_code_exchange-pkce.ts` ends immediately after obtaining `accessToken`/`refreshToken` from the provider — no session is created inside it. OAuth's job is authentication only; the natural next step is calling the *same* `createSession` that password login uses (ticket 08). This keeps `App.Auth`'s session-creation path singular regardless of how the user authenticated — exactly the "no inline session checks, one shape" principle `ADR-002` already establishes for password auth.

## Plan

1. [x] Land ticket 08 first (session creation must exist before OAuth has anywhere to hand off to) — done.
2. [x] **Done further than planned:** the user-resolution side of the seam is already built — `App.Users.linkOAuthAccount`/`findUserByOAuthAccount` (`oauth_accounts` table, `migrations/003_create_users_and_oauth.sql`). What remains for this ticket is narrower than originally scoped: only the actual Arctic token-exchange porting (step 2 below), not the "where does the resulting identity go" question.
3. Port `authorization_request-pkce.ts` + `authorization_code_exchange-pkce.ts` (PKCE variants, not the non-PKCE ones — PKCE should be the default, not opt-in, for a new implementation) into a new module, using Bun-native primitives for the pieces Arctic's reference leaves as generic `fetch`/crypto calls.
4. Decide which provider(s) to support first (not yet decided — flag back to the user rather than guessing).
5. OAuth callback handler: exchange the code (step 3) → `App.Users.findUserByOAuthAccount` → if found, `App.Auth.createSession` with that `UserId`; if not found, create a new user (`App.Users.createUser`-adjacent — a password-less user, or prompt for an email — a real product decision, not yet made) → `App.Users.linkOAuthAccount` → `App.Auth.createSession`. Same session table, same cookie as password login — no parallel session mechanism.
6. Port `refresh_request.ts`/`token_revocation_request.ts` only if a provider integration actually needs long-lived access tokens refreshed (e.g. calling a provider's API beyond initial login) — don't build unused surface.

**Blocked by:** ~~08~~ — resolved, unblocked.

**Status:** needs-triage — user-resolution side done (2026-09-08); Arctic token-exchange porting not started; provider choice still not made

## Comments

Filed alongside ticket 08 per the same 2026-09-08 research pass; `ADR-002`'s Amendment section now documents this as a tracked follow-on, not a blocker to the core session work.
