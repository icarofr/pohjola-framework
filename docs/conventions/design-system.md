# Pohjola — Design System & UI Generation Guide

Pohjola uses DaisyUI 5 + **closed page templates** so agents fill typed slots instead of inventing layout. These conventions guide consistency; they are not a pixel-perfect guarantee of every visual outcome.

---

## 1. The 3-Tier Architecture

1. **Tier 1: UX heuristics** (scorecard in §5 below):
   - Single primary CTA, scan time, recoverable form errors — manual review until automated.
2. **Tier 2: Design Tokens (`DESIGN.md`)**:
   - Colors, typography, radii, spacing. Daisy themes `pohjola` / `pohjola-dark` in `css/input.css` (primary `#047857`).
3. **Tier 3: DaisyUI templates & primitives**:
   - **Pages:** `App.Ui.Templates.*` — closed `PageTemplate` ADT + `renderPage`. Agents fill slot records only.
   - **Primitives:** `App.Ui.Button`, `Card`, `Badge`, … — DaisyUI class recipes used *inside* Templates.

---

## 2. Core Design Rules

* **DaisyUI boundary**: Templates and `App.Ui` primitives own class strings. Feature views pass slots only; no `class_`.
* **Single Primary Action Rule**: At most ONE primary button (`ButtonPrimary`) per screen. Other actions use outline/ghost/link.
* **At Most One Eyebrow**: At most one badge/eyebrow per section.
* **Contrast Floor**: Aim for WCAG AA (4.5:1); manual review until automated.
* **Target Size**: Interactive targets ≥ 44×44px on mobile.

---

## 3. Page composition — Templates only

Feature views **must not** compose primitives. Call `renderPage` with one `PageTemplate` variant and a slot record.

| Page purpose | Template | Exemplar |
|---|---|---|
| Marketing landing | `Landing` | `Home/View.purs` |
| Hub / link grid | `Hub` | `Contact/View.purs` |
| Long-form editorial | `Editorial` | `About/View.purs` |
| Content feed / list | `Feed` | `Posts/View.purs` (list) |
| Article detail | `Article` | `Posts/View.purs` (detail) |
| Scaffold default | `Editorial` | `make new-feature` |

**ADR-012:** feature `View.purs` / `Components/` must not call `class_` or import primitive modules — enforced by `make gate`.

Contract markers: `App.Ui.Templates.Contract` (`data-template="…"`). Shell chrome: `App.Ui.Templates.SiteShell`.

---

## 4. Component dictionary (`src/App/Ui/`)

| Module | Constructor | Daisy |
|---|---|---|
| `App.Ui.Button` | `buttonLink`, `buttonLinkExternal` | `btn` + variant/size |
| `App.Ui.Card` | `card`, `cardBody`, `cardTitle`, … | `card` + `card-border` |
| `App.Ui.Badge` | `badge` | `badge` + color |
| `App.Ui.Alert` | `alert` | `alert` + color |
| `App.Ui.Prose` | `prose`, `proseLg` | `prose` |
| `App.Ui.Form` | `textField`, … | `fieldset` + `input` / `textarea` |
| `App.Ui.Container` | `container` | `container` + width utilities |
| `App.Ui.TextTone` | `toneClass` | `text-base-content` opacities |
| Templates | `renderPage`, `PageTemplate`, slots | site shell + page sections |

---

## 5. Pre-Ship UI Scorecard

1. [ ] Only ONE primary CTA on the screen.
2. [ ] Views use `App.Ui.Templates.renderPage` — **no `class_`** (`make gate`).
3. [ ] At most one eyebrow per section.
4. [ ] Text contrast reviewed for WCAG AA.
5. [ ] Click targets meet 44×44px minimum.
6. [ ] Keyboard focus / ARIA on interactive elements.
7. [ ] Empty and error states handled via typed slots/primitives.
8. [ ] Muted text uses `App.Ui.TextTone` (or Daisy opacity utilities *inside* Templates) — no raw `text-base-content/N` in features.
