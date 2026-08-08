<!-- Human-facing process doc — agents: skip unless explicitly asked to work on process/docs. -->

<!-- Human-facing process doc — agents: skip unless explicitly asked to work on process/docs. -->

# Handoff

**Update this file at the end of each significant work session.** `git log`
shows WHAT changed; this file shows WHY and WHAT'S NEXT. If a session ended
with an open question, it belongs here — not only in your head.

## Active conventions (as of 2026-08-03)

- **HTML** is built with the `App.Html` ADT — never string-concatenated.
  Gate-banned `raw` outside the 5 allowlisted modules; ADR-001.
- **Forms** go through `App.Form` — `decodeX` per form, honeypot = silent
  success ALWAYS, decoding total (property-tested). No inline form parsing in
  `Main.purs`. ContractSpec + FormSpec enforce.
- **Two feature templates**: Contact (static: `Page` + `View`) and Posts
  (data-backed: `Types`/`Service`/`Page`/`View`). No third shape without an ADR.
- **Auth** goes through `src/App/Auth.purs` — a stub with the full interface
  (`requireAuth`, `createSession`, `destroySession`) and honest
  always-unauthenticated bodies. **Not yet implemented.** ADR-002 fixes the shape.
- **FFI** follows `docs/ffi-taming-guide.md` (ADR-003): priority order,
  dispatch pattern, `Foreign` decode at the boundary, allowlist entry. **None
  in `src/` yet** — `FFI_ALLOWLIST_GREP` is empty.

## Recent decisions

The current decision set lives in `docs/adr/` — read before proposing
architecture:

- **ADR-000** — no custom browser JS (Alpine only)
- **ADR-001** — hand-rolled `Html` ADT, not Halogen/Smolder
- **ADR-002** — auth shape (PS-first assembly, session cookies, Bun-native defaults)
- **ADR-003** — FFI taming recipe

Decided / won't do (don't re-litigate without a new ADR): `docs/IMPROVEMENTS.md`
"Decided / won't do" table.

## Open architectural questions

- **Persistence backend: not yet chosen.** ADR-002 records the defaults:
  `bun:sqlite` for small apps, `Bun.sql` or `yoga-postgres` for Postgres.
  Land with the first persistence-backed feature (`App.Db` stub, backlog #24).
- **Search and real-time are deliberately un-stubbed.** Their interface
  depends on the implementation choice; a premature stub locks in the wrong
  shape. Don't propose stubbing them without an ADR.

## What the next agent should NOT do

- Don't add browser JS (script tags, inline scripts) — Alpine only (ADR-000).
- Don't replace `App.Html` or hand-roll a page shell — every page flows
  through `Layout.Page` (ADR-001, ContractSpec).
- Don't add FFI without an allowlist entry + ADR + `Foreign` decode; don't use
  `unsafe*`/partial functions (gate).
- Don't inline form parsing or "fix" the honeypot to return errors — extend
  `App.Form`; silent success is the contract (ContractSpec, property tests).
- Don't hand-roll session checks or fetch outside `App.Data.Fetch`; don't
  import sibling feature modules (ADR-002, ContractSpec).
