# ADR-013: Compiler-first policy (typed contract, no JSON manifest)

## Status

Accepted — 2026-09-01

## Context

Structural policy was encoded in `policy/manifest.json` and enforced by
`scripts/verify-policy.js`. That worked but had drawbacks:

- **Bespoke config** — agents could edit JSON to widen policy without touching types.
- **Whack-a-mole UI tokens** — `uiClassPolicy.allowedTokens` grew with every new
  Tailwind class; it did not stop agents from inventing components from memory.
- **Duplication** — the same lists lived in JSON, JS gate, and PureScript tests.
- **Wrong language** — this codebase is PureScript; policy belongs in types and tests.

[IHP](https://ihp.digitallyinduced.com/) enforces architecture through Haskell
typeclasses, closed view surfaces, and `nix flake check` — not parallel config files.

## Decision

1. **`Policy.Contract` is the single source of truth** (`src/Policy/Contract.purs`).
   All allowlists, forbidden patterns, and closed module sets are typed PureScript
   values.

2. **`make gate` runs `Test.Gate`** — a fast PureScript test module that scans the
   filesystem using `Test.Policy.Scan` and asserts against `Policy.Contract`.
   No JSON, no Node policy script.

3. **Kill `uiClassPolicy`** — class token allowlists are gone. Instead:
   - **Closed `App.Ui` primitive set** — new `src/App/Ui/*.purs` files fail the gate.
   - **Closed `App.Ui.Templates` set** — new template files fail the gate.
   - **Feature views** fill `PageTemplate` slots via `renderPage` only; forbidden
     imports and calls are scanned from `Policy.Contract`.
   - **DaisyUI** — styling lives in primitives and templates; agents compose slots,
     they do not scaffold Tailwind from memory.

4. **`Test.PolicySpec` is behavioral only** — reference-page archetype markers
   (landing hero, hub cards, feed grid). Structural scans moved to `Test.Gate`.

5. **Theme build check** — `scripts/verify-theme.js` reads `--color-primary` from
   `css/input.css`, not a manifest field.

## Consequences

### Positive

- Policy changes are code review + compiler, not silent JSON edits.
- Extending the UI surface requires updating `Policy.Contract` (and usually an ADR).
- One enforcement path for structural policy (`make gate`).
- Aligns with ADR-012 semantic UI contracts without token gardening.

### Negative

- `make gate` requires a Spago build (~slower than raw Node scan). Acceptable:
  gate still runs before full `make test` in `make fast`.
- Apps that fork the framework must carry their own `Policy.Contract` deltas or
  override gate tests — same as before with per-app policy lists.

## Enforcement map

| Concern | Module | Command |
|---------|--------|---------|
| Structural scans | `Test.Gate` + `Policy.Contract` | `make gate` |
| Reference page archetypes | `Test.PolicySpec` | `make test` |
| CSP, Alpine seam, headers | `Test.ContractSpec` | `make test` |
| Types (routes, i18n, handlers) | Compiler | `spago build` |

## Extending the contract

To add a new page template or UI primitive:

1. Implement the module under `App.Ui.Templates` or `App.Ui`.
2. Add its path to `uiTemplateModules` or `uiPrimitiveModules` in `Policy.Contract`.
3. Wire it into `PageTemplate` / `renderPage` if it is a template.
4. Run `make gate` and `make test`.

## Related

- ADR-012 — semantic UI contracts (slot-filling, no `class_` in features)
- ADR-003 — FFI allowlist (now `Policy.Contract.ffiAllowlist`)
