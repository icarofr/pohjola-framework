# Pohjola — Agent Guide

**Framework**: PureScript 0.15.16 + Bun runtime, SSR MPA with Alpine.js interactivity.

### Safety floor
- `dist/` → public static root; `dist-server/` → private server bundle (never serve from `dist/`).
- Interactivity via Alpine typed constructors in `App.Alpine` only — no custom JavaScript (ADR-000).
- Server FFI is restricted to 4 allowlisted modules (ADR-003/007). See `Makefile` `FFI_ALLOWLIST_GREP`.
- `make gate` enforces exhaustive pattern matching, no unsafe imports, allowlisted FFI, and no general-purpose HTML escape hatch.
- CSP is pinned byte-exact in `test/ContractSpec.purs`. Widening demands justification.

### Commands (daily use)
| Target | Description |
|---|---|
|`make deps`|Install Spago/Bun and Alpine assets |
|`make dev`|Tailwind + static sync + Spago build |
|`make run`|Build and run with Bun |
|`make build`|Produce production CSS & bundle (output to `dist-server/`) |
|`make test`|Unit + property + ContractSpec (runs under Bun) |
|`make test/integration`|Venom integration tests |
|`make test/e2e`|Playwright end-to-end |
|`make gate`|Banned-fn / FFI / HTML-escape checks |
|`make check`|gate + build + test + format-check |
|`make new-feature`|Scaffold a feature (NAME=X [TYPE=data] [SLUG_FR=x] [WIRE=1]) |
|`make gen-sql`|Generate PureScript types & codecs from SQL Schema |

### Task → doc trigger map
- Adding a page → `docs/conventions/adding-pages.md`, `docs/adr/ADR-008-component-architecture.md`
- Forms → `docs/conventions/forms.md`
- Data fetching → `docs/conventions/data-layer.md`
- Server internals → `docs/conventions/server.md`
- Alpine seams → `docs/conventions/alpine-contracts.md`
- Writing tests → `docs/conventions/testing-recipes.md`
- Scaffolding a feature → `docs/conventions/generators.md`
- FFI → `docs/ffi-taming-guide.md`
- Idiomatic PureScript / clean code → `docs/conventions/idiomatic-purescript.md`
- Sessions / CSRF / middleware shape → `docs/adr/ADR-004-sessions.md`, `ADR-005-csrf.md`, `ADR-006-middleware-shape.md`
- Guarantees/claims → `docs/GUARANTEES.md`

### Architecture (6-10 lines)
- MPA rendered by PureScript server using the `Html` ADT.
- Routes per language via `routing-duplex` codecs in `Data/Route.purs`.
- Page view split: static pages (`Page.purs`) and data-backed pages (`View.purs`) using `App.Data.Fetch`.
- Forms follow `App.Form` contract with honeypot and same-origin checks.
- Errors are values (`App.Error` → `Either`) never thrown.
- Alpine.js provides client interactivity through typed constructors in `App.Alpine`.

### Content & i18n discipline
- Text copy lives in `Data.I18n.Dictionary`; `Data.Content` holds only metadata. Both languages must have entries.

### Human-only docs
`docs/SETUP.md` is a human-facing setup guide — agents skip unless asked.

### Exemplar modules
`docs/examples/Crypto.purs`, `Example.purs`, `Snake.purs` are teaching artifacts, not imported.

### Default agent rules
- Before adding a feature, read the relevant convention doc (task→doc map above). **If you skip this, state why.**
- Before adding FFI, read `docs/ffi-taming-guide.md`. **If you skip this, state why.**
- Before proposing auth, read `docs/adr/ADR-002-auth-shape.md`. **If you skip this, state why.**
- Before committing, run `make check`. **If you skip this, state why.**
- When verification method is unclear, ask the user before proceeding.

### Context-efficient workflows
- Grep first to find line numbers, then read targeted ranges — don't read entire large files.
- Capture test/build output to a file once (`make test 2>&1 | tee /tmp/test.log`), then analyse — don't re-run.
- Batch related edits across files, then run one build — not build-per-edit.
- Use `make gate` (~2s) for quick checks; `make check` (~60s) before committing.

### Agent evals
- `evals/` contains prompt + assertion pairs that test whether an agent follows our conventions.
- Run `make eval EVAL=01-add-page --check` after implementing an eval prompt to verify.
- Before changing a convention doc, run the related eval to see what it asserts.

### Guardrails (each enforced by a check)
- Build HTML through the `Html` ADT — string-concatenated HTML bypasses escaping (ADR-001, `make gate`).
- Output bundles to `dist-server/` — `dist/` is the public static root only.
- Keep CSP at the pinned policy — widenings need an ADR (ContractSpec exact-string assertion).
- The `Html` ADT has no general-purpose unescaped constructor; script/style contexts and `doctype` are explicit (`make gate`).
- Express interactivity through `App.Alpine` constructors — raw Alpine strings fail ContractSpec.
