# Auth reference — Lucia (sessions) + Arctic (OAuth)

Full technical reference for the patterns `ADR-002`'s Amendment (2026-09-08)
adopts in full. This doc holds the pattern detail; `ADR-002` holds the
decision and rationale. Implementation tracked in `.scratch/founding-premise/`
tickets `08` (sessions — implemented) and `09` (OAuth — not started).

Every Pohjola-based project standardizes on this pattern. No compromises,
no partial adoption.

## Why these two, not a library

Neither Lucia nor Arctic is an installable package anymore. Both were
deprecated by their author (pilcrowOnPaper) in favor of single-purpose
reference files you copy and adapt — Lucia's README calls `auth_session.ts`
"a complete, single-file replacement for the NPM package"; Arctic's README
says the same of its `code/` directory. "Build on Lucia/Arctic" means port
the documented pattern to Bun-native primitives, not add a dependency.

- Lucia: [github.com/lucia-auth/lucia](https://github.com/lucia-auth/lucia), sessions guide at [auth.pilcrowonpaper.com/sessions](https://auth.pilcrowonpaper.com/sessions)
- Arctic: [github.com/pilcrowonpaper/arctic](https://github.com/pilcrowonpaper/arctic)

## Lucia's session pattern

Source: [`code/auth_session.ts`](https://github.com/lucia-auth/lucia/blob/main/code/auth_session.ts)

**Token shape — `id.secret`:**
- `id`: 16 random bytes (`crypto.getRandomValues`), each byte's top 5 bits
  (`byte >> 3`) mapped through a 32-char human-readable alphabet
  (`abcdefghijkmnpqrstuvwxyz23456789` — no `l`/`o`/`0`/`1`, to avoid visual
  ambiguity). Verified against Lucia's literal `generateRandomId` source,
  not paraphrased — 80 bits of entropy (5 bits × 16 bytes), not 128, since
  3 bits per byte are discarded. The session's public reference. Safe to
  log, safe to show in an admin revocation UI.
- `secret`: 32 random bytes (`crypto.getRandomValues`), standard base64
  (`secret.toBase64()` in Lucia's source) — the actual bearer
  credential. Never stored; only its SHA-256 hash is persisted.

**Storage schema** (Lucia's reference; Pohjola's will live in
`migrations/NNN_create_sessions.sql` per `App.Migration`):

```
auth_session(id, user_id, secret_hash BLOB, token_last_verified_at, created_at)
```

**Validation:**
1. Split the incoming token on `.` into `id` and `secret`.
2. Look up the row `WHERE id = $1`.
3. Hash the incoming `secret` (SHA-256), compare against the stored
   `secret_hash`.
4. Reject on missing row, hash mismatch, or expiry.

Lucia's reference does this comparison at the app level and calls out that
it must be constant-time (timing-attack surface on a byte-by-byte compare).
**Pohjola's implementation does not need this step**: looking the row up by
indexed `id` equality and letting Postgres compare the stored hash is not
the same operation as an app-level manual compare over attacker-controlled
input — there's no app-level branch-on-secret-content path to time. This is
a real, positive divergence from a literal port, not a corner cut.

**Renewal — sliding, Lucia's exact parameters:**
If ≥1 hour has passed since `token_last_verified_at`, bump it. This extends
a 10-day window without reissuing a token. No sliding-window renewal means a
session dies exactly at issuance + fixed duration regardless of activity;
Lucia's model (adopted here) means an active session effectively never
expires while in use, and an idle one expires 10 days after its last use.

**Known limitation: cookie lifetime vs. server-side sliding validity.**
Server-side session validity is genuinely sliding (above). The *cookie's own*
`Max-Age` is not: `App.Auth.formatSessionCookie` sets it once, to 864000
seconds (10 days), at issuance, and nothing currently re-issues `Set-Cookie`
to refresh it. In practice this means an active session's server-side record
stays valid indefinitely while used, but the browser will still drop the
cookie itself 10 days after the *original* login regardless of activity in
between — the cookie doesn't slide even though the session does. The real
fix is having whatever wraps `requireAuth` in a protected route re-issue
`Set-Cookie` when `checkSession` returns `SessionValid` after a renewal;
that needs a protected-route caller to exist first (none does yet — see
"Not built" below), so it isn't wired in. Don't describe the cookie itself
as "sliding" until this is fixed.

**Cookie:** `__Host-ps_session` when `Config.secureCookies` is true
(production default). In `DEV_ALLOW_INSECURE_COOKIES=true` dev mode the
name changes to plain `ps_session` — a browser silently drops any cookie
named with the `__Host-` prefix that isn't `Secure`, so the prefix itself
has to be conditional, not just the flag (see `Config.secureCookies`'s doc
comment). Otherwise: `Path=/`, `Secure` (when applicable), `HttpOnly`,
`SameSite=Lax`.

**CSRF is not optional alongside this.** Lucia's own docs state it plainly:
a cookie-carried session token needs CSRF protection regardless of
`SameSite`. `ADR-005` (amended 2026-09-09 to match Lucia's actual
hierarchy — `Sec-Fetch-Site` primary, `Origin` secondary, a token demoted
to an explicit legacy-browser fallback, not a requirement) must land
alongside or before real session auth ships — not after. Neither layer
is implemented right now — `sameOriginOk`, which covered the secondary
`Origin` layer, was removed along with the last mutating route it
guarded (see `ADR-005`'s note on this); the primary `Sec-Fetch-Site`
check was never added. Both need building before wiring
`requireAuth` into any mutating route.

## Arctic's OAuth pattern

Source: [`code/` directory](https://github.com/pilcrowonpaper/arctic/tree/main/code) — six reference files:

- `authorization_request.ts` / `authorization_request-pkce.ts`
- `authorization_code_exchange.ts` / `authorization_code_exchange-pkce.ts`
- `refresh_request.ts`
- `token_revocation_request.ts`

Use the **PKCE variants** as the default (`authorization_request-pkce.ts`,
`authorization_code_exchange-pkce.ts`) — PKCE should not be opt-in for a new
implementation. Only port `refresh_request.ts`/`token_revocation_request.ts`
if a provider integration actually needs long-lived access-token refresh
(e.g. calling the provider's API beyond initial login) — don't build unused
surface.

These files are provider-agnostic (generic OAuth 2.0 endpoints, not a
per-provider SDK — `GOOGLE_OAUTH_CLIENT_ID` in the reference is a naming
example, not a hardcoded dependency) and framework-agnostic (explicit
`todo.getRequestURLQueryParameter`/`todo.setResponseStatusCode`-style
placeholders for request/response glue you fill in with `App.ServerBun`).

**The integration seam is structural, not documented anywhere as an API.**
`authorization_code_exchange-pkce.ts` ends the moment it has
`accessToken`/`refreshToken` from the provider — it does not create a
session. That's deliberate: OAuth's only job is proving who the user is.
The callback handler's next line, after a successful exchange, is the exact
same `App.Auth.createSession` that password login calls. One session
mechanism, two ways to arrive at it.

## Bun-native mapping

Every primitive below already exists in this codebase — this is wiring, not
new capability:

| Pattern piece | Bun-native primitive | Where |
|---|---|---|
| Random `secret` bytes, base64 | `crypto.getRandomValues` | `randomBase64`, `src/App/Bun.purs` — same primitive as the CSP-nonce generator, `src/App/ServerBun.js:70` |
| Random `id` bytes, Lucia's exact alphabet | `crypto.getRandomValues` | `randomLuciaId`, `src/App/Bun.purs`/`.js` — a literal port of Lucia's `generateRandomId`, not the same encoder as `secret` |
| `secret` hash for storage/lookup | SHA-256 | `sha256Hex`, `src/App/Bun.purs:47` (currently used for migration checksums) |
| Password hashing (login password — different concern from token hashing) | `Bun.password` | `hashPassword`/`verifyPassword`, `src/App/Bun.purs:81-96` |
| Session store | `Bun.sql` | `App.Data.SQL` (`ADR-009`) — needs a sessions table + repository, no new FFI |
| Cookie read | `Bun.CookieMap` | `src/App/ServerBun.js:35-36` |
| Cookie write | Plain header string | `Set-Cookie` needs no FFI — see the header-tuple pattern in `withCsp`, `src/App/Server.purs:163-164` |
| OAuth token exchange | `fetch` | Already the pattern for outbound HTTP in `App.Data.Fetch` |

No new `foreign import` module, no new `ffiAllowlist` entry. Everything
above lands inside the already-approved `App.Bun`/`App.Data.SQL` boundary.

## Users table (App.Users) — implemented 2026-09-08

`migrations/003_create_users_and_oauth.sql` + `src/App/Users.purs`. Separate
module from `App.Auth` on purpose — `App.Auth` owns session lifecycle only;
`App.Users` owns who a user *is* (password registration/login, OAuth account
linking). `App.Auth.UserId` is reused, not duplicated.

**Schema:**

```
users(id, email UNIQUE, password_hash NULL, email_verified, created_at)
oauth_accounts(provider, provider_user_id, user_id -> users.id, created_at)
  PRIMARY KEY (provider, provider_user_id)
```

`password_hash` is nullable — an OAuth-only account is valid.
`oauth_accounts` is a separate table (not columns on `users`) so linking a
new provider later needs no schema change, and multiple providers can link
to one account. `sessions.user_id` (migration 002) gets a real FK to
`users.id` in this migration, `ON DELETE CASCADE` — deleting a user logs
them out everywhere.

**Password hashing parameters** (`App.Bun.hashPasswordImpl`): Argon2id,
`memoryCost: 16384` (16 MiB, KiB), `timeCost: 3` — Lucia's own stated
minimum from the Passwords chapter (`auth.pilcrowonpaper.com/passwords`):
*"Argon2id with at least 16MiB of memory, 3 iterations."* `Bun.password.verify`
reads these back out of the stored hash string itself; they don't need to be
passed again at verify time — confirmed against Bun's own docs, not assumed.

**`App.Users`'s functions** (all require a live DB, `Config.databaseUrl`):
`createUser`, `findUserByEmail`, `verifyUserPassword` (the full login check:
uniform `Nothing` for "no such user" / "no password set" / "wrong password"
— never distinguish which in a response, same principle as
`App.Auth.requireAuth`), `linkOAuthAccount`, `findUserByOAuthAccount`
(Arctic's callback seam — resolves a `UserId` from a provider identity; the
caller decides whether to create a new user on a first-time OAuth login).

**Rate-limiting a future login handler:** Lucia's own guidance —
*"A rate limit of 1 attempt per minute per user is a good starting point...
use a token bucket algorithm"*, explicitly **against** account lockouts,
exponential throttling, or strict IP-based limits. `App.RateLimit.shouldAllow`
(fixed-window, already implemented) is the equivalent mechanism already in
this codebase — a login handler should call it keyed by email/user, not IP.

**Not built:** any HTTP route, registration form, or login form. No
live-database test coverage (none available in this environment) — the one
pure, DB-independent piece (`decodeLoginCandidate`) is directly tested in
`test/UsersSpec.purs`.

## What's NOT decided yet

- OAuth provider(s) to support first — not picked, don't guess (ticket `09`).
- Whether `refresh_request.ts`/`token_revocation_request.ts` are needed at
  all depends on that provider choice and what the app actually does with
  the access token after login.
