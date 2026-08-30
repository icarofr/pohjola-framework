# UI blueprint recipe (GLM-safe pages)

**Status:** Active  
**Date:** 2026-08-30

**Prerequisite:** shell chrome per `docs/superpowers/specs/2026-08-30-shell-recipe.md`.

## Two layers, one door

| Layer | Location | Agent touches? |
|---|---|---|
| Primitives | `App.Ui.Button`, `Card`, … | No |
| Page blueprints | `App.Ui.Layout.*` | No |
| Shell blueprints | `App.Ui.Shell.*` | No |
| Feature views | `App.Features/*/View.purs` | **Yes — records only** |

## Page-type → blueprint

| Page purpose | Blueprint | Slot builders |
|---|---|---|
| Marketing landing | `Ui.landingPage` | `Ui.grid3`, `Ui.actionCard` |
| Hub / links | `Ui.hubPage` | `actionCard` records in `cards` |
| Editorial | `Ui.editorialPage` | `Ui.editorialParagraphs` |
| List + empty/error | `Ui.feedPage` | `Ui.teaserCard` in `Components/` |
| Article detail | `Ui.articlePage` | — |

## Feature view rules (`make gate`)

**Forbidden imports:** `App.Ui.Card`, `Container`, `Hero`, `Prose`, `Alert`, `Badge`, …  
**Forbidden calls:** `Ui.page`, `Ui.hero`, `Ui.card`, `cardBody`, `pageLayout`, …  
**Allowed:** `Ui.buttonLink` in `feedPage` empty `action` only; `import App.Ui.Button (ButtonVariant(..))` for editorial CTA.

## Exemplar shapes (copy structure, i18n from `dict lang`)

- `Home/View.purs` → `landingPage`
- `Contact/View.purs` → `hubPage`
- `About/View.purs` → `editorialPage`
- `Posts/View.purs` → `feedPage` / `articlePage`
- `Posts/Components/PostCard.purs` → `teaserCard`

## Ground-up rebuild

```bash
rm -rf src/App/Ui/Shell src/App/Ui/Layout \
  src/App/Features/*/View.purs src/App/Features/*/Components
```

**Order:** Shell (`ShellSpec`) → Layout (`UiSpec`) → Header/Footer delegates → Features (`PolicySpec`).

```bash
make gate && make test
```

## Changing the look

Edit frozen recipes in `App.Ui.Shell.*` / `App.Ui.Layout.*` and update `ShellSpec` / `UiSpec` / `PolicySpec`. Never widen layout in feature views.
