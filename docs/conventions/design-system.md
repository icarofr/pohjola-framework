# Pohjola — Design System & UI Generation Guide

Pohjola uses a 3-tier architecture with **Slot-Based Layout Archetypes** to guarantee that AI-generated user interfaces remain brand-consistent, structurally non-deformed, and accessible without visual drift or "utility soup".

---

## 1. The 3-Tier Architecture

1. **Tier 1: UX Strategy & Hard Gates (Layr)**:
   - Surface playbooks define UX heuristics (Hick's Law, single primary CTA, scan time < 3s, recoverable form errors).
   - The 85/100 evidence-based scorecard audits every UI change before completion.
2. **Tier 2: Design Tokens & Single Source of Truth (`DESIGN.md`)**:
   - Google Labs `DESIGN.md` format defines exact colors, typography scales, radii, and spacing in YAML.
   - Built-in linting validates WCAG AA contrast (4.5:1 text-on-surface).
   - Exported directly to Tailwind CSS v4 `@theme` in `css/input.css`.
3. **Tier 3: Rigid Slot-Based Templates & Primitives (`App.Ui.Layout.*` & `App.Ui.*`)**:
   - High-level layout archetypes (`Hero`, `SectionHeader`, `Grid`, `ActionCard`, `ConversionCta`) that enforce rigid slots.
   - Encapsulates box model, margin rhythm, and baseline alignment so agents only pass typed data records.

---

## 2. Core Design Rules

* **Zero Layout Soup in Views**: Feature views (`Features/*/View.purs`) MUST NOT author raw layout utility chains (`flex`, `space-y-*`, `grid`, `gap-*`, `py-*`). Views must compose slot-based templates from `App.Ui.Layout.*`.
* **Single Primary Action Rule**: Every screen/view must have at most ONE primary button (`Button.Primary`). All secondary actions must use `Button.Secondary`, `Button.Outline`, or `Button.Ghost`.
* **At Most One Eyebrow**: Section headers and cards may have at most ONE single eyebrow tag. Chaining multiple badges above a title is strictly forbidden.
* **Contrast Floor**: All body text must achieve at least 4.5:1 contrast against its background container (WCAG AA).
* **Target Size**: All interactive click targets must be $\ge 40\times 40\text{px}$ on desktop and $\ge 44\times 44\text{px}$ on mobile.

---

## 3. Slot-Based Layout Archetypes (`src/App/Ui/Layout/`)

| Module | Template Function | Role |
|---|---|---|
| [`App.Ui.Layout.Hero`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Layout/Hero.purs) | `hero HeroProps` | Standardized landing hero with pinned headline scale, single primary action, and optional secondary target. |
| [`App.Ui.Layout.SectionHeader`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Layout/SectionHeader.purs) | `sectionHeader SectionHeaderProps` | Unbreakable section title with max 1 eyebrow tag, proportional subtitle line height, and matched container width. |
| [`App.Ui.Layout.Grid`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Layout/Grid.purs) | `grid2`, `grid3`, `grid4` | Responsive grid containers with fixed 24px/32px gaps and full-height `items-stretch` alignment. |
| [`App.Ui.Layout.ActionCard`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Layout/ActionCard.purs) | `actionCard ActionCardProps` | Feature card with locked vertical flex slots: top tag + title, middle description, and pinned bottom action button baseline. |
| [`App.Ui.Layout.ConversionCta`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Layout/ConversionCta.purs) | `conversionCta ConversionCtaProps` | High-contrast conversion banner with locked centered alignment and padded geometry. |

---

## 4. Component Dictionary (`src/App/Ui/`)

| Module | Constructor / Type | Usage |
|---|---|---|
| [`App.Ui.Button`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Button.purs) | `buttonLink`, `buttonLinkExternal` | `Primary`, `Secondary`, `Outline`, `Ghost`, `Inverted` |
| [`App.Ui.Card`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Card.purs) | `card`, `cardImage`, `cardBody` | Standardized surface containers with 10px radius and subtle border |
| [`App.Ui.Badge`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Badge.purs) | `badge Variant String` | Monospace status indicators (`Primary`, `Secondary`, `Tertiary`, `Success`, `Warning`, `Error`, `Neutral`) |
| [`App.Ui.Alert`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Alert.purs) | `alert Variant String` | Accessible feedback banners with `role="status"` / `role="alert"` (`Info`, `Success`, `Warning`, `Error`) |
| [`App.Ui.Stat`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Stat.purs) | `statCard`, `statGrid` | Telemetry metric cards for dashboards and landing pages |
| [`App.Ui.EmptyState`](file:///Users/user/projects/pohjola-framework/src/App/Ui/EmptyState.purs) | `emptyState` | Actionable empty state panels with guidance and CTA |
| [`App.Ui.Modal`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Modal.purs) | `renderModal` | Accessible dialogs with focus trap and escape dismiss |
| [`App.Ui.Tabs`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Tabs.purs) | `renderTabs` | Accessible tablist and tabpanels |
| [`App.Ui.Accordion`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Accordion.purs) | `renderAccordion` | Expandable disclosure items with ARIA controls |

---

## 5. Pre-Ship UI Scorecard (Hard Gates)

Before finalizing any UI feature, verify these hard gates:
1. [ ] Only ONE primary CTA exists on the screen.
2. [ ] Views compose slot templates from `App.Ui.Layout.*` (zero manual `space-y-*` or `flex-col justify-between` soup in feature modules).
3. [ ] At most one eyebrow tag is present per section.
4. [ ] Text contrast meets WCAG AA standards (`bun x designmd lint DESIGN.md`).
5. [ ] All click targets meet the $44\times 44\text{px}$ touch target minimum.
6. [ ] Keyboard focus states and ARIA roles are present on interactive elements.
7. [ ] Empty and error states are handled gracefully via typed primitives.
