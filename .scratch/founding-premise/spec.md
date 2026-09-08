# Founding-premise grilling: does Pohjola justify existing as a bespoke framework?

Origin: a `/grill-with-docs` session (2026-09-08) interrogating Pohjola's core concept against its own docs (README, CONTEXT.md, GUARANTEES.md, ADR-002, ADR-013, the deep-audit report) and against IHP — which turns out to have repositioned itself in 2026 for the exact "agent-safe framework" niche Pohjola claims, while already shipping working auth/ORM/scaffolding that Pohjola still lacks.

Status as of 2026-09-08 (updated): 8 of 9 resolved/mostly-done, 1 open. Real code now exists in `src/`: `App.Auth` (session lifecycle, Lucia pattern) is implemented and verified (`make check` green, 262/262 tests). No login UI, no protected route, and no CSRF (ADR-005) yet — see ticket 08's two remaining open items.

## Tickets

1. `01-purpose-and-mandate.md` — **resolved.** Pohjola is the foundation for the user's own apps, open-sourced, positioned specifically as a safety layer for AI-agent-driven ("vibe coded") development, not a generic production framework.
2. `02-ihp-stance.md` — **resolved.** PureScript+Bun over Haskell+IHP is terminal (Nix/GHC friction + npm interop are real reasons; switching cost of abandoning a working app is the strongest reason). IHP treated as a design reference for auth, not a fork target.
3. `03-auth-urgency.md` — **resolved.** Nothing currently blocked on missing auth; deferred deliberately, but must stay a documented gap, not silently implied — superseded by ticket 08 actually landing real code.
4. `04-readme-saas-claim.md` — **resolved, landed.** README's "Right Fit" list no longer claims commerce/SaaS fit outright; scoped with an explicit "not yet, here's why, here's what unblocks it" line.
5. `05-auth-gate-hole.md` — **resolved, closed by ticket 08.** The empirically-verified gate hole is moot now that real `App.Auth` exists to import instead of hand-rolling; the obsolete "ban all App.Auth imports" check was removed (it would otherwise block the real, correct usage).
6. `06-readme-pitch-and-audience.md` — **resolved, landed.** Single doc (not split), opening pitch rewritten to lead with "the safest way to vibe code," plus the empirical evidence grounding a sharper, more defensible version of the original "slop" critique.
7. `07-license-reconsideration.md` — **resolved, landed.** AGPL → Apache 2.0 (the real, checkable license); `LICENCE.md`'s joke text kept, only the referenced model name changed.
8. `08-implement-adr-002-lucia-pattern.md` — **mostly done, implemented 2026-09-08.** Real `App.Auth` module: id/secret split, sliding 10-day renewal, Bun-native primitives throughout (no Node-compat), 14 new passing tests for the pure logic. `ADR-002` amended and marked implemented; full pattern reference at `docs/conventions/auth-lucia-arctic.md`. Two items deliberately left open: no protected route wired yet (nothing to protect), and CSRF (ADR-005) — a real, flagged gap, not a formality.
9. `09-oauth-via-arctic-pattern.md` — **open, unblocked.** Sessions (08) and now the users/OAuth-linking table (`App.Users`, `oauth_accounts`) both exist. What's left is narrower: porting Arctic's actual token-exchange code and picking a provider — not yet started, don't guess the provider.

## Grounding (for whoever picks these up without full session context)

- README's "Landscape Comparison" table already addresses IHP by name, rejecting it on Nix/GHC-overhead grounds — not on missing features.
- ADR-013 (compiler-first policy) cites IHP explicitly as the philosophical precedent for "policy lives in types/compiler, not a JSON manifest" — the *idea* was borrowed, the *stack* was not.
- ADR-002/004/005 (auth/sessions/CSRF) are all "Accepted — implementation pending," fixing target shape before any implementation, specifically to avoid a "10 auth wrappers" drift pattern.
- Git history (`56e2ab4`, `2b4b140`) shows at least one private app was forked from this base, then scrubbed from the public tree — this is not a hypothetical audience.
- Live web check (2026-09-08): IHP's own site now reads "IHP is the Haskell web framework for agentic engineering. Your agent writes the code; typed SQL, generated schema types and compile-checked views prove it works" — i.e. IHP now makes Pohjola's exact "Built for AI Agents" pitch, plus ships working ORM/schema-designer/codegen/auth that Pohjola doesn't have yet.
