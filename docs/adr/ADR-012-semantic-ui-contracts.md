# ADR-012: Semantic UI contracts (DaisyUI + slot templates)

**Status:** Accepted  
**Date:** 2026-08-30

## Context

ADR-008 defined file-structure seams (`Features/Components/`, `App.Ui/`,
`Container`, `TextTone`). Feature views still accumulated Tailwind utility
soup — especially Posts — because only **one** styling dimension (foreground
opacity) had mechanical enforcement.

The StyleX / agent-ergonomics research (captured in
`docs/superpowers/specs/2026-08-30-text-tone-design.md`) does **not** argue
for adopting StyleX or React. It argues for:

1. **Semantic contracts** that shrink valid choices (roles, not raw tokens).
2. **Mechanical enforcement** so hallucinated classes fail a check, not a review.
3. **Typed page APIs** — records in, HTML out — so agents compose rather than
   invent layout.

DaisyUI is the **component vocabulary** inside `App.Ui`; it is not the
contract itself. The contract is: feature modules never emit `class_`.

## Decision

### Three UI seams (all class strings live here)

| Seam | Location | Agent-facing API |
|---|---|---|
| Primitives | `App.Ui.*` | `buttonLink`, `card`, `badge`, `emptyState`, … |
| Layout archetypes | `App.Ui.Layout.*` | `landingPage`, `editorialPage`, `articlePage`, `pageLayout`, `actionCard`, … |
| Semantic tokens | `App.Ui.TextTone` | `toneClass`, `interactiveSoftClass` |

Feature `View.purs` and `Components/*.purs` **must not** call `class_` or
assemble DaisyUI/Tailwind class strings. They pass localized strings and
routes into `App.Ui` blueprints only.

### DaisyUI's role

- DaisyUI semantic classes (`btn`, `card`, `badge`, `hero`, `avatar`, …) are
  used **only** inside `App.Ui` modules. Class strings must match
  `research/daisyui/packages/daisyui/src/components/*.css` and the official
  component docs — no parallel Tailwind dialect.
- Tailwind layout utilities (`space-y-*`, `flex`, `grid`, …) are allowed
  **only** inside `App.Ui` and `App.Layout` (shell).
- `css/input.css` defines custom DaisyUI themes `pohjola` / `pohjola-dark` from
  `DESIGN.md` tokens. `scripts/verify-theme.js` fails if compiled CSS omits primary
  `#047857`.
- **Closed class vocabulary in `App.Ui`:** `policy/manifest.json`
  `uiClassPolicy.allowedTokens` is the only set of class tokens `App.Ui` may
  quote. New utilities require a manifest edit (review), not a silent string.
- **No `extraClass` on `buttonLink`.** Button chrome is variant + size only.

### Reference feature implementations

| Pattern | Exemplar | Blueprint |
|---|---|---|
| Landing | `Home/View.purs` | `landingPage` |
| Hub / links | `Contact/View.purs` | `hubPage` + `actionCard` grid |
| Editorial | `About/View.purs` | `editorialPage` + `editorialParagraphs` |
| List + teasers | `Posts/View.purs` (list) | `feedPage` + `teaserCard` |
| Article detail | `Posts/View.purs` (detail) | `articlePage` |

### Enforcement ladder

| Level | Mechanism | What it covers |
|---|---|---|
| Compiler | Closed ADTs (`TextTone`, `ButtonVariant`, blueprint records) | Invalid variant names |
| `policy/manifest.json` | Single source of truth for structural policy lists | FFI, banned fns, feature-view forbidden patterns, theme names |
| `make gate` | `scripts/verify-policy.js` reads the manifest | Fast pre-compile structural checks (same rules as PolicySpec scans) |
| `make test` → `PolicySpec` | Manifest-driven scans + rendered reference-page archetypes | Behavioral UI policy, cross-feature imports, theme script strings |
| `make design-policy` | `generator-policy` + `scripts/verify-theme.js` | Generator/`App.Ui` boundary + compiled CSS primary token |
| `ContractSpec` | CSP, Alpine seam, cache, security headers | Security + runtime contracts only |
| Eval 10 | Thin wrapper: `make gate` + `verify-theme.js` + `make test` | Agent regression after UI tasks |
| Convention | `design-system.md` scorecard (primary CTA, contrast) | UX — not yet automated |

`make generator-policy` validates generator wiring and compile; it is **not**
a CSS boundary proof.

### Explicit debt (non-goals for this ADR)

- Responsive card grids use Tailwind `grid` inside `App.Ui.Layout.Grid` — DaisyUI has no grid primitive.
- Automated pixel/screenshot regression is not yet in CI (structural HTML + theme checks only).

## Consequences

- **Agent loop**: a feature view with `class_` fails `make gate`; repair is
  "pick a blueprint or primitive."
- **Posts migration** becomes the template for data-backed UIs — list and
  detail without raw cards/buttons in features.
- **Generator** scaffolds `pageLayout` / `editorialPage`, not raw `container`.
- **ADR-008** remains the file-structure ADR; this ADR owns styling contracts
  and DaisyUI placement.

## Related

- ADR-008 — component file structure, Container, TextTone amendment
- `docs/conventions/design-system.md` — recipes and scorecard
- `docs/superpowers/specs/2026-08-30-text-tone-design.md` — research principle
