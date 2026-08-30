# Pohjola — Design System & UI Generation Guide

Pohjola uses a 3-tier architecture with **Slot-Based Layout Archetypes** to guide AI-generated user interfaces toward brand consistency, accessible structure, and less "utility soup". These conventions are not a structural guarantee of every visual or accessibility outcome.

---

## 1. The 3-Tier Architecture

1. **Tier 1: UX heuristics** (scorecard in §5 below):
   - Single primary CTA, scan time, recoverable form errors — manual review until automated.
2. **Tier 2: Design Tokens & Single Source of Truth (`DESIGN.md`)**:
   - Google Labs `DESIGN.md` format defines exact colors, typography scales, radii, and spacing in YAML.
    - WCAG contrast is a design intent checked through manual review; automated token linting is pending.
    - Direct export to Tailwind CSS v4 `@theme` is a planned integration, not current repository tooling.
3. **Tier 3: DaisyUI semantic recipes & rigid templates (`App.Ui.Layout.*` & `App.Ui.*`)**:
   - High-level layout archetypes (`Hero`, `SectionHeader`, `Grid`, `ActionCard`, `ConversionCta`) that enforce rigid slots.
   - Encapsulates box model, margin rhythm, and baseline alignment so agents only pass typed data records.

---

## 2. Core Design Rules

* **DaisyUI boundary**: `App.Ui` owns semantic component recipes and their Tailwind/DaisyUI classes. Feature views consume those recipes; Tailwind layout utilities are allowed only inside `App.Ui`.
* **Single Primary Action Rule**: Every screen/view must have at most ONE primary button (`ButtonPrimary`). All other actions use `ButtonOutline`, `ButtonGhost`, or `ButtonLink`.
* **At Most One Eyebrow**: Section headers and cards may have at most ONE single eyebrow tag. Chaining multiple badges above a title is strictly forbidden.
* **Contrast Floor**: Aim for at least 4.5:1 contrast against the background (WCAG AA); verify this through manual review until automated tooling is available.
* **Target Size**: All interactive click targets must be $\ge 40\times 40\text{px}$ on desktop and $\ge 44\times 44\text{px}$ on mobile.

---

## 3. Page composition — closed blueprints only

Feature views **must not** compose primitives (`hero`, `card`, `page`, `grid3`, …). Pick **one** blueprint and pass a record. Slot builders (`actionCard`, `teaserCard`, `grid3`, `editorialParagraphs`) are allowed only inside blueprint slot fields.

| Page purpose | Blueprint | Exemplar |
|---|---|---|
| Marketing landing | `landingPage` | `Home/View.purs` |
| Hub / link grid | `hubPage` + `actionCard` records | `Contact/View.purs` |
| Long-form editorial | `editorialPage` + `editorialParagraphs` | `About/View.purs` |
| Content feed / list | `feedPage` + `teaserCard` items | `Posts/View.purs` (list) |
| Article detail | `articlePage` | `Posts/View.purs` (detail) |
| Generic static (scaffold default) | `editorialPage` | `make new-feature` |

**ADR-012:** feature `View.purs` and `Components/` must not call `class_` or import `App.Ui.Card` / `App.Ui.Prose` / … — enforced by `make gate` (`policy/manifest.json`).

Full agent recipe: `docs/superpowers/specs/2026-08-30-ui-blueprint-recipe.md`.

---

## 4. Component dictionary (`src/App/Ui/`)

| Module | Constructor | Daisy |
|---|---|---|
| `App.Ui.Button` | `buttonLink`, `buttonLinkExternal` | `btn` + `btn-primary` / `btn-outline` / `btn-ghost` / `btn-neutral` / `btn-link` |
| `App.Ui.Card` | `card`, `cardBody`, `cardTitle`, `cardText`, `cardActions` | `card` + `card-border` + parts |
| `App.Ui.Hero` | `hero` | `hero` + `hero-content` |
| `App.Ui.Badge` | `badge` | `badge` + color |
| `App.Ui.Alert` | `alert` | `alert` + color, `role="alert"` |
| `App.Ui.Prose` | `prose`, `proseLg` | `prose` |
| `App.Ui.Form` | `textField`, `formContainer`, … | `fieldset` + `input` / `textarea` |
| `App.Ui.Container` | `container` | `container` + width utilities |
| `App.Ui.TextTone` | `toneClass` | `text-base-content` opacities only here |
| Shell | `App.Layout.Header` / `Footer` / `Page` | `navbar`, popover `dropdown`, `drawer`, `footer` |

---

## 5. Pre-Ship UI Scorecard (Hard Gates)

`make generator-policy` validates the canonical generator's `App.Ui` boundary;
it is not a full CSS/type-system proof, and existing feature views may still
require migration.

Before finalizing any UI feature, verify these hard gates:
1. [ ] Only ONE primary CTA exists on the screen.
2. [ ] Views compose slot templates from `App.Ui.Layout.*` — **no `class_` in feature `View.purs` or `Components/`** (`make gate`, ADR-012).
3. [ ] At most one eyebrow tag is present per section.
4. [ ] Text contrast has been manually reviewed against WCAG AA standards (automated linting is pending).
5. [ ] All click targets meet the $44\times 44\text{px}$ touch target minimum.
6. [ ] Keyboard focus states and ARIA roles are present on interactive elements.
7. [ ] Empty and error states are handled gracefully via typed primitives.
8. [ ] Muted foreground text uses `App.Ui.TextTone` variants — no raw `text-base-content/N` opacity strings.
