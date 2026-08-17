# Pohjola — Design System & UI Generation Guide

Pohjola uses a 3-tier architecture to guarantee that AI-generated user interfaces remain brand-consistent, accessible, and high-converting without visual drift or "utility soup".

---

## 1. The 3-Tier Architecture

1. **Tier 1: UX Strategy & Hard Gates (Layr)**:
   - Surface playbooks define UX heuristics (Hick's Law, single primary CTA, scan time < 3s, recoverable form errors).
   - The 85/100 evidence-based scorecard audits every UI change before completion.
2. **Tier 2: Design Tokens & Single Source of Truth (`DESIGN.md`)**:
   - Google Labs `DESIGN.md` format defines exact colors, typography scales, radii, and spacing in YAML.
   - Built-in linting validates WCAG AA contrast (4.5:1 text-on-surface).
   - Exported directly to Tailwind CSS v4 `@theme` in `css/input.css`.
3. **Tier 3: Typed Semantic Components (`App.Ui.*` + DaisyUI)**:
   - High-level, typed PureScript primitives (`Button`, `Card`, `Badge`, `Alert`, `Stat`, `EmptyState`, `Modal`, `Tabs`, `Accordion`).
   - Encapsulates utility strings so agents only assemble semantic types.

---

## 2. Core Design Rules

* **Single Primary Action Rule**: Every screen/view must have at most ONE primary button (`Button.Primary`). All secondary actions must use `Button.Secondary`, `Button.Outline`, or `Button.Ghost`.
* **No Raw Utility Soup**: Never assemble 15+ ad-hoc Tailwind utility classes in feature views. Compose building blocks from `App.Ui.*` or use DaisyUI semantic classes (`card`, `btn`, `badge`, `stat`, `alert`).
* **Contrast Floor**: All body text must achieve at least 4.5:1 contrast against its background container (WCAG AA).
* **Target Size**: All interactive click targets must be $\ge 40\times 40\text{px}$ on desktop and $\ge 44\times 44\text{px}$ on mobile.

---

## 3. Component Dictionary (`src/App/Ui/`)

| Module | Constructor / Type | Usage |
|---|---|---|
| [`App.Ui.Button`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Button.purs) | `buttonLink`, `buttonLinkExternal` | `Primary`, `Secondary`, `Outline`, `Ghost`, `Inverted` |
| [`App.Ui.Card`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Card.purs) | `card`, `cardImage`, `cardBody` | Standardized surface containers with 16px radius and subtle ring |
| [`App.Ui.Badge`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Badge.purs) | `badge Variant String` | Status indicators (`Primary`, `Secondary`, `Success`, `Warning`, `Error`, `Neutral`) |
| [`App.Ui.Alert`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Alert.purs) | `alert Variant String` | Accessible feedback banners with `role="status"` / `role="alert"` (`Info`, `Success`, `Warning`, `Error`) |
| [`App.Ui.Stat`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Stat.purs) | `statCard`, `statGrid` | Clean metric cards for dashboards and landing pages |
| [`App.Ui.EmptyState`](file:///Users/user/projects/pohjola-framework/src/App/Ui/EmptyState.purs) | `emptyState` | Actionable empty state panels with guidance and CTA |
| [`App.Ui.Modal`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Modal.purs) | `renderModal` | Accessible dialogs with focus trap and escape dismiss |
| [`App.Ui.Tabs`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Tabs.purs) | `renderTabs` | Accessible tablist and tabpanels |
| [`App.Ui.Accordion`](file:///Users/user/projects/pohjola-framework/src/App/Ui/Accordion.purs) | `renderAccordion` | Expandable disclosure items with ARIA controls |

---

## 4. Surface Playbooks & Heuristics

### Dashboards & Operational Views
- Put the most decision-relevant data first using `Stat.statGrid`.
- Cover all data states: Empty (`EmptyState.emptyState`), Loading, Error (`Alert.alert`), Partial, Success.
- Tables or dense lists must remain usable across responsive breakpoints.

### Forms & Settings
- Group inputs logically; place the submit action at the natural end of the flow.
- Form validation errors must be actionable and identifiable via `Form.purs` and `Alert.alert`.
- Destructive actions must require explicit confirmation.

### Landing & Public Pages
- Instant value proposition above the fold with a single primary CTA.
- Use `Card.card` for feature highlights and `Badge.badge` for metadata.
- Ensure semantic heading hierarchy (`h1` $\rightarrow$ `h2` $\rightarrow$ `h3`).

---

## 5. Pre-Ship UI Scorecard (Hard Gates)

Before finalizing any UI feature, verify these hard gates:
1. [ ] Only ONE primary CTA exists on the screen.
2. [ ] Text contrast meets WCAG AA standards (`bun x designmd lint DESIGN.md`).
3. [ ] All click targets meet the $44\times 44\text{px}$ touch target minimum.
4. [ ] Keyboard focus states and ARIA roles are present on interactive elements.
5. [ ] Empty and error states are handled gracefully.
6. [ ] UI is composed from `App.Ui.*` rather than raw ad-hoc utility strings.
