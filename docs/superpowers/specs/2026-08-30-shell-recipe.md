# Shell recipe (GLM-safe chrome)

**Status:** Active  
**Date:** 2026-08-30

Chrome is **library code**, not page code. Agents never edit shell modules.

## Modules (`App.Ui.Shell.*`)

| Module | Daisy source | Frozen exports (ShellSpec) |
|---|---|---|
| `SiteHeader` | navbar + drawer toggle | `siteHeaderClass` — sticky, blur, `border-b border-base-300` |
| `ThemeControl` | [theme-controller](https://daisyui.com/components/theme-controller/) + swap | `themeSwapClass`, `theme-controller`, `site-theme-toggle` |
| `LangMenu` | popover dropdown | `header-lang-menu` popover (no Daisy locale widget) |
| `SiteFooter` | custom DESIGN dock grid | `siteFooterClass`, `siteFooterLabelClass` — **not** `footer sm:footer-horizontal` |

`App.Layout.Header` / `Footer` are thin delegates: pass i18n + `Route` into shell blueprints only.

## Theme

- UI: Daisy **swap + theme-controller** checkbox, `value="pohjola-dark"` from `App.Theme`.
- Persistence: `darkModeInitScript` in head syncs checkbox + `localStorage` (no Alpine theme popover).
- Do **not** use `header-theme-menu` or Alpine `xSetTheme` in shell.

## Rebuild order (ground-up)

```bash
rm -rf src/App/Ui/Shell src/App/Ui/Layout \
  src/App/Features/*/View.purs src/App/Features/*/Components
```

1. Implement `App.Ui.Shell.*` until `make test` → `ShellSpec` passes.
2. Implement `App.Ui.Layout.*` until `UiSpec` passes (see page recipe).
3. Wire `App.Layout.Header` / `Footer` as delegates.
4. Implement feature views until `PolicySpec` reference pages pass.
5. `make gate && make test`.

## Tests

- `test/ShellSpec.purs` — shell class recipes
- `test/ContractSpec.purs` — rendered Home includes theme-controller + lang popover
- `test/UiSpec.purs` — page blueprints
- `test/PolicySpec.purs` — reference feature pages

See also: `docs/superpowers/specs/2026-08-30-ui-blueprint-recipe.md`.
