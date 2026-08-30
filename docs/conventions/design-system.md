# Pohjola — Design System & UI Generation Guide

Pohjola uses a 3-tier architecture with **Slot-Based Layout Archetypes** to guide AI-generated user interfaces toward brand consistency, accessible structure, and less "utility soup". These conventions are not a structural guarantee of every visual or accessibility outcome.

---

## 1. The 3-Tier Architecture

1. **Tier 1: UX Strategy & Hard Gates (Layr)**:
   - Surface playbooks define UX heuristics (Hick's Law, single primary CTA, scan time < 3s, recoverable form errors).
   - The 85/100 evidence-based scorecard audits every UI change before completion.
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
* **Single Primary Action Rule**: Every screen/view must have at most ONE primary button (`Button.Primary`). All secondary actions must use `Button.Secondary`, `Button.Outline`, or `Button.Ghost`.
* **At Most One Eyebrow**: Section headers and cards may have at most ONE single eyebrow tag. Chaining multiple badges above a title is strictly forbidden.
* **Contrast Floor**: Aim for at least 4.5:1 contrast against the background (WCAG AA); verify this through manual review until automated tooling is available.
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
| [`App.Ui.TextTone`](file:///Users/user/projects/pohjola-framework/src/App/Ui/TextTone.purs) | `toneClass`, `interactiveSoftClass` | Semantic foreground tones (`Ink`, `Copy`, `Meta`) — raw `text-base-content/N` is forbidden outside this module |
| [`App.Ui.Modal`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Modal.purs) | `renderModal` | Accessible dialogs with focus trap and escape dismiss |
| [`App.Ui.Tabs`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Tabs.purs) | `renderTabs` | Accessible tablist and tabpanels |
| [`App.Ui.Accordion`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Accordion.purs) | `renderAccordion` | Expandable disclosure items with ARIA controls |

---

## 5. Pre-Ship UI Scorecard (Hard Gates)

`make generator-policy` validates the canonical generator's `App.Ui` boundary;
it is not a full CSS/type-system proof, and existing feature views may still
require migration.

Before finalizing any UI feature, verify these hard gates:
1. [ ] Only ONE primary CTA exists on the screen.
2. [ ] Views compose slot templates from `App.Ui.Layout.*` (zero manual `space-y-*` or `flex-col justify-between` soup in feature modules).
3. [ ] At most one eyebrow tag is present per section.
4. [ ] Text contrast has been manually reviewed against WCAG AA standards (automated linting is pending).
5. [ ] All click targets meet the $44\times 44\text{px}$ touch target minimum.
6. [ ] Keyboard focus states and ARIA roles are present on interactive elements.
7. [ ] Empty and error states are handled gracefully via typed primitives.
8. [ ] Muted foreground text uses `App.Ui.TextTone` variants — no raw `text-base-content/N` opacity strings.
