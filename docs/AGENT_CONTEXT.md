<!-- Human-facing process doc — agents: skip unless explicitly asked to work on process/docs. -->

# Agent Context — load these files before writing code

How to work on this repo. Read the section matching your task BEFORE editing.
Enforcement is real: `make gate` + `make test` + CI reject violations of the
contracts below. `docs/GUARANTEES.md` lists every guarantee and its check.

## Always load

1. `AGENTS.md` — architecture, commands, guardrails, task→doc map
2. `src/App/Html.purs` — the HTML ADT. Build HTML through this; string
   concatenation bypasses escaping.
3. `src/App/Error.purs` — the error ADT. Add variants here; return `Either`,
   never throw.
4. `src/Data/Route.purs` — route codec. Update BOTH languages (compiler
   enforces).
5. `src/Data/I18n.purs` — dictionary. Update BOTH languages (compiler
   enforces).
6. `Makefile` (`gate` target) — what's banned: `unsafeCoerce`/
   `unsafePerformEffect`/`unsafePartial`, partial-function modules, `fromJust`,
   FFI outside `FFI_ALLOWLIST_GREP`, `raw` outside `RAW_ALLOWLIST_GREP`.

## When adding a page or feature

7. `src/App/Features/Contact/` — the STATIC template (`Page.purs` + `View.purs`)
8. `src/App/Features/Posts/` — the DATA template (`Types`/`Service`/`Page`/`View`)
9. `src/App/Data/Fetch.purs` — all HTTP fetching goes through `fetchJson`.
    Feature modules stay isolated from siblings (ContractSpec enforces).
10. `docs/adr/` — read before proposing any architectural change.

## When adding a form

11. `src/App/Form.purs` — the form contract. Extend with a new `decodeX`
    following `decodeContact`/`decodeNewsletter`. Parse form bodies through
    `App.Form`, never inline in `Main.purs`. Honeypot = silent success,
    ALWAYS (property-tested).

## When touching auth

12. `src/App/Auth.purs` — the stub. ALL auth flows go through this module.
13. `docs/adr/ADR-002-auth-shape.md` — the implementation shape. Follow it or
    amend it first.

## When adding a JS library via FFI

14. `docs/ffi-taming-guide.md` — the recipe (target priority, vetting,
    boundary rules). Required reading before any `foreign import`.
15. `docs/examples/Crypto.purs` + `Crypto.js` — the boundary template.

## Guardrails (each enforced by a check)

- Build HTML through the `Html` ADT — string-concatenated HTML bypasses
  escaping (ADR-001, `make gate`).
- Output bundles to `dist-server/` — `dist/` is the public static root only.
- Keep CSP at the pinned policy — widenings need an ADR (ContractSpec
  exact-string assertion).
- Keep `raw` and FFI inside the Makefile allow-list — additions need an ADR
  (`make gate`).
- Express interactivity through `App.Alpine` constructors — raw Alpine
  strings fail ContractSpec.
- Route HTTP through `App.Data.Fetch` — feature modules fetch via
  `fetchJson` only (ContractSpec).
- Keep features isolated — import only from shared modules, never from a
  sibling feature (ContractSpec).
- Flow every page through `Layout.Page` — hand-rolled page shells fail
  ContractSpec.
- Extend `App.Form` for form parsing — inline parsing in handlers fails
  ContractSpec / property tests.
- Keep the honeypot silent — a filled honeypot returns 303 success after
  the rate gate, always (property tests).
- Use `App.Auth.requireAuth` for auth checks — hand-rolled session checks
  bypass the auth contract (ADR-002).
- Reference external scripts via local assets only — `<script src="http…">`
  fails CSP + ContractSpec.
