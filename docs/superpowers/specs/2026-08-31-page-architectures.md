# Page architectures (agent decision guide)

**Status:** Active  
**Date:** 2026-08-31

**Prerequisite:** `docs/superpowers/specs/2026-08-30-ui-blueprint-recipe.md` (layers + `renderPage`).

This is Pohjola's answer to "which layout?" — a small, enforced catalog instead of freestyle daisyUI in feature views. For exact component syntax when extending `App.Ui` or `Templates`, read `vendor/daisyui/skills/daisyui/components/<name>.md` (`make deps`).

## Workflow (mandatory order)

1. **Classify the page intent** using the table below — do not guess from training-data landing pages.
2. **Pick `PageTemplate`** and slot builders from `App.Ui.Templates.Types`.
3. **Fill slots only** in `View.purs`. `Page.purs` is the handler.
4. **Wire** with `make new-feature NAME=X WIRE=1` when adding a route.
5. **If no row fits** → extend `App.Ui.Templates.*` + `Types.purs` slots; never add `class_` in features.

Site chrome (navbar, drawer, footer) stays in `SiteShell` — not in page templates.

## Intent → template

| User / product intent | Template | Slot builders | Exemplar |
|---|---|---|---|
| Marketing home, hero + features + CTA | `Landing` | `landingSlots`, `landingFeatures` | `Home/Page.purs` |
| Link grid, contact options, hub | `Hub` | `hubSlots`, `hubCardTriple` | `Contact/View.purs` |
| Long-form static content, mission/values | `Editorial` | `editorialSlots`, `valuesSlotsFromArray` | `About/View.purs` |
| Blog / post teasers, author cards | `Feed` | `feedSlots` + `FeedCard` | `Posts/View.purs` |
| Single article / detail page | `Article` | `articleSlots` | `Posts/View.purs` |
| Match list, fixtures, calendars, crests | `Schedule` | `scheduleSlots` + `ScheduleMatch` | `Fixtures/View.purs` |

Entry: `App.Ui.Templates.Render.renderPage lang Route (Constructor slots)`.

## Shared header rhythm

`PageHeader` (`App.Ui.Templates.PageHeader`) owns in-page headers for every inner page:

| Variant | Used by | Marker |
|---|---|---|
| `render` | Hub, Editorial, Feed, Schedule | `data-template="page-header"` |
| `renderDetail` | Article detail (badge prefix) | `data-template="page-header-detail"` |

All inner pages use the same DaisyUI recipe: `breadcrumbs` + left-aligned `h1` + optional subtitle + `divider`. **Landing (Home) is the only `hero`** — marketing promo block, not reused on inner routes.

Do not duplicate `<h1>` / lead copy in feature views — pass `title` / `subtitle` / `breadcrumbs` through slot records.

## Anti-patterns (common agent mistakes)

| Wrong | Why | Use instead |
|---|---|---|
| `Feed` for sports schedules / match rows | Feed is post teasers; ignores crests and kickoff shape | `Schedule` |
| `Hub` for long prose | Hub is card grid, not article body | `Editorial` |
| `Editorial` for marketing hero + feature grid | Missing landing sections | `Landing` |
| `class_` or `App.Ui.Card` in features | Breaks ADR-012; fails `make gate` | Slots + templates |
| Freestyle daisyUI from model memory | Stale syntax, drift | Vendor skill doc → `App.Ui.*` primitive |
| New page type without new template | Forces wrong archetype | Extend `Templates.*` + `Policy.Contract` closed set |

## When to extend the system

| Need | Action |
|---|---|
| New optional field on existing page type | Extend slot record in `Types.purs`, render in matching `Templates.*` |
| New page archetype (e.g. dashboard table) | New `Templates.*` module + `PageTemplate` variant + `Contract` markers + checklist row |
| Reused daisyUI pattern across templates | New `App.Ui.*` primitive (see `component-checklist.md` §3) |

## Verification

- `make gate` — no `class_` in features, closed template surface
- `make test` — `TemplateContractSpec` structural markers
- `make eval EVAL=10-ui-archetypes --check` — policy + doc presence
- `make eval EVAL=12-add-ui-component --check` — after template/primitive changes

## Related

- Scaffold: `make new-feature` → `docs/conventions/generators.md`
- DaisyUI primitives: `docs/conventions/component-checklist.md`
- Shell chrome: `docs/superpowers/specs/2026-08-30-shell-recipe.md`
