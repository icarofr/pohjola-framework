# UI blueprint recipe (GLM-safe)

**Status:** Active  
**Date:** 2026-08-30

## Problem

Agents can follow Daisy class names and still ship ugly pages, because **components ≠ layout**. Removing `App.Ui.Layout.*` left feature views composing primitive soup with no frozen `DESIGN.md` rhythm.

## Solution: two layers, one door

| Layer | Location | Who touches it |
|---|---|---|
| **Primitives** | `App.Ui.Button`, `Card`, `Badge`, … | `App.Ui.Layout.*` and shell only |
| **Blueprints** | `App.Ui.Layout.*` | Feature `View.purs` / `Components/` |

Feature code imports `App.Ui as Ui` and calls **blueprints + slot builders** only.

## Page-type → blueprint (pick one)

| If the page is… | Call | Slot builders |
|---|---|---|
| Marketing home / landing | `Ui.landingPage { … }` | `Ui.grid3`, `Ui.actionCard` in section `content` |
| Hub of links / cards | `Ui.hubPage { … }` | `actionCard` records in `cards` |
| About / legal / essay | `Ui.editorialPage { … }` | `Ui.editorialParagraphs` in `body` |
| List + empty/error | `Ui.feedPage { … }` | `Ui.teaserCard` per item (via `Components/`) |
| Article detail | `Ui.articlePage { … }` | — |

Scaffold default for new static pages: `editorialPage`.

## Forbidden in feature views (`make gate`)

**Imports:** `App.Ui.Card`, `Container`, `Hero`, `Prose`, `Alert`, `Badge`, `Form`, …

**Calls:** `Ui.page`, `Ui.hero`, `Ui.card`, `Ui.stack`, `Ui.proseLg`, `cardBody`, `pageLayout`, …

**Always:** `class_`, raw `text-base-content/`, hardcoded English `text "…"`.

**Allowed:** `Ui.buttonLink` / `buttonLinkExternal` inside `feedPage` empty-state `action` only; `import App.Ui.Button (ButtonVariant(..))` for editorial CTA variant.

## Exemplar files (copy shape, not paste)

- `src/App/Features/Home/View.purs` — `landingPage`
- `src/App/Features/Contact/View.purs` — `hubPage`
- `src/App/Features/About/View.purs` — `editorialPage`
- `src/App/Features/Posts/View.purs` — `feedPage` / `articlePage`
- `src/App/Features/Posts/Components/PostCard.purs` — `teaserCard`

## Enforcement ladder

1. **`make gate`** — forbidden imports/calls in feature paths (`scripts/verify-policy.js`)
2. **`make test` → `UiSpec`** — frozen class recipes per blueprint module
3. **`make test` → `PolicySpec`** — reference pages render expected recipes
4. **`make eval EVAL=10-ui-archetypes --check`** — agent regression after UI work
5. **`make generator-policy`** — scaffold emits blueprints, not `Ui.page`

## Adding a new page (agent checklist)

1. Read this file + `docs/conventions/design-system.md` §3.
2. Choose blueprint from table above.
3. `View.purs`: one top-level blueprint call; i18n via `dict lang` only.
4. `Components/`: map domain → `teaserCard` or `actionCard` only.
5. Run `make gate && make test`.

## Changing the look

Edit frozen recipes in `App.Ui.Layout.*` (and `PolicySpec` / `UiSpec` assertions). **Never** widen layout in feature views.
