# ADR-012: Semantic UI contracts (DaisyUI + page templates)

**Status:** Accepted  
**Date:** 2026-08-30  
**Amended:** 2026-08-31 — live pages use `App.Ui.Templates`; removed Layout blueprints and shadcn registry ingest.

## Context

ADR-008 defined file-structure seams (`Features/Components/`, `App.Ui/`,
`Container`, `TextTone`). Feature views still accumulated Tailwind utility
soup because only **one** styling dimension had mechanical enforcement.

Research (StyleX ergonomics, then a shadcn registry POC) argued for:

1. **Semantic contracts** that shrink valid choices (roles, not raw tokens).
2. **Mechanical enforcement** so hallucinated classes fail a check, not a review.
3. **Typed page APIs** — records in, HTML out — so agents compose rather than invent layout.

DaisyUI is the **component vocabulary** inside `App.Ui` / Templates; it is not
the contract itself. The contract is: feature modules never emit `class_`.

## Decision

### UI seams (all class strings live here)

| Seam | Location | Agent-facing API |
|---|---|---|
| Primitives | `App.Ui.*` | Used inside Templates only |
| Page templates | `App.Ui.Templates.*` | `renderPage` + `PageTemplate` slot records |
| Markers | `App.Ui.Templates.Contract` | `data-template="…"` constants |
| Semantic tokens | `App.Ui.TextTone` | `toneClass` (feature opacity ban) |

Feature `View.purs` and `Components/*.purs` **must not** call `class_` or
assemble DaisyUI/Tailwind class strings. They pass localized strings and
routes into template slot records only.

### DaisyUI's role

- DaisyUI semantic classes (`btn`, `card`, `badge`, `hero`, `navbar`, …) are
  used **only** inside Templates and `App.Ui` primitives.
- `css/input.css` defines Daisy themes `pohjola` / `pohjola-dark` from
  `DESIGN.md` tokens. `scripts/verify-theme.js` fails if compiled CSS omits
  primary `#047857`.
- **Closed class vocabulary:** `policy/manifest.json` `uiClassPolicy.allowedTokens`
  is the only set of class tokens Templates/Ui may quote.
- **No parallel design app:** production UI is PureScript-only. A shadcn POC
  may live under `research/` as evidence; it is not a build or gate input.

### Reference feature implementations

| Pattern | Exemplar | Template |
|---|---|---|
| Landing | `Home/View.purs` | `Landing` |
| Hub / links | `Contact/View.purs` | `Hub` |
| Editorial | `About/View.purs` | `Editorial` |
| List | `Posts/View.purs` (list) | `Feed` |
| Article detail | `Posts/View.purs` (detail) | `Article` |

### Enforcement ladder

| Level | Mechanism | What it covers |
|---|---|---|
| Compiler | Closed ADTs (`PageTemplate`, `ButtonVariant`, slot records) | Invalid shapes |
| `policy/manifest.json` | Structural policy lists | FFI, banned fns, feature-view forbidden patterns |
| `make gate` | `scripts/verify-policy.js` | Fast structural checks |
| `make test` | `PolicySpec`, `TemplateContractSpec`, `ShellSpec` | Markers, reference pages, shell |
| `make design-policy` | generator + `verify-theme.js` | Scaffold boundary + CSS primary |
| `ContractSpec` | CSP, Alpine, security headers | Security / runtime |

### Explicit non-goals

- Automated pixel/screenshot regression is not yet in CI.
- Navbar theme switcher is optional future chrome (not required by this ADR).

## Consequences

- **Agent loop**: a feature view with `class_` fails `make gate`; repair is
  "pick a `PageTemplate` and fill slots."
- **Generator** scaffolds Editorial / Feed via `renderPage`, not primitive soup.
- **ADR-008** remains the file-structure ADR; this ADR owns styling contracts.

## Related

- ADR-008 — component file structure
- `docs/conventions/design-system.md`
- `llms.txt` — compact agent rules
- `docs/superpowers/specs/2026-08-30-ui-blueprint-recipe.md`
