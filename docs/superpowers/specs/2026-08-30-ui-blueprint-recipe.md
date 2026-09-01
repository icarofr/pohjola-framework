# UI template recipe (agent-safe pages)

**Status:** Active  
**Date:** 2026-08-31

**Prerequisite:** shell chrome per `docs/superpowers/specs/2026-08-30-shell-recipe.md`.

## Layers

| Layer | Location | Agent touches? |
|---|---|---|
| Primitives | `App.Ui.Button`, `Card`, … | No (inside Templates only) |
| Page templates | `App.Ui.Templates.*` | No |
| Shared headers | `App.Ui.Templates.PageHeader` | No |
| Slot types / markers | `Templates.Types`, `Templates.Contract` | Read only |
| Feature views | `App.Features/*/Page.purs` or `View.purs` | **Yes — slot records only** |

**Decision guide:** `docs/superpowers/specs/2026-08-31-page-architectures.md` (intent → template, anti-patterns).

## Page-type → template

| Page purpose | Constructor | Slot builders |
|---|---|---|
| Marketing landing | `Landing` | `landingSlots`, `landingFeatures` |
| Hub / links | `Hub` | `hubSlots`, `hubCardTriple` |
| Editorial | `Editorial` | `editorialSlots`, `valuesSlotsFromArray` |
| Post / content feed | `Feed` | `feedSlots` + `FeedCard` array |
| Article detail | `Article` | `articleSlots` |
| Fixtures / match schedule | `Schedule` | `scheduleSlots` + `ScheduleMatch` array |

Entry point: `App.Ui.Templates.Render.renderPage`.

## Feature view rules (`make gate`)

**Forbidden imports:** `App.Ui.Card`, `Container`, `Hero`, `Prose`, `Alert`, `Badge`, …  
**Forbidden:** `class_`, layout utility soup, calling primitives from features.  
**Allowed:** `renderPage`, `PageTemplate(…)`, slot helpers from `Templates.Types`, `ActionTarget`.

## Exemplars

- `Home/View.purs` → `Landing`
- `Contact/View.purs` → `Hub`
- `About/View.purs` → `Editorial`
- `Posts/View.purs` → `Feed` / `Article`
- `Fixtures/View.purs` → `Schedule` (match rows + crests — not `Feed`)

## Changing the look

Edit frozen modules under `App.Ui.Templates.*` and update `TemplateContractSpec` / `PolicySpec` / e2e as needed. Never widen layout in feature views.
