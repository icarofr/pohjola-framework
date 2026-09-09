# Shell recipe (DaisyUI site chrome)

**Status:** Active (supersedes App.Ui.Shell / Layout Header delegates; App.Ui.Templates.SiteShell itself superseded 2026-09-09 by App.DatastarShell — ADR-011)  
**Date:** 2026-08-31

Chrome is **template library code**, not feature code. Agents never invent navbar/footer markup.

## Module

| Module | Role | Markers (`Contract`) |
|---|---|---|
| `App.DatastarShell` | Sticky navbar, mobile menu, footer | `site-header`, `site-footer` |

`renderPage` always wraps body content in `dsSitePage`. Feature views do not call DatastarShell directly.

## Theme

- Themes: Daisy `pohjola` / `pohjola-dark` in `css/input.css` (`data-theme` on `<html>`).
- Persistence: `themeInitScript` applies stored preference before paint; `system` omits `data-theme` (Daisy `prefersdark`).
- Navbar switcher: DaisyUI `dropdown` + real `<button>` + Datastar `DsThemeMenuOpen` (toggle, outside click, Escape) + `dsSetTheme`.

## Navigation links

- Route-aware links: `App.Datastar.dsNavLinkRecord` (Datastar `@get` action + prefetch guard + `aria-current="page"`).
- Visual active state: `dsActiveNavClass` — **never** hand-roll `btn-active` / `menu-active` in `DatastarShell`.
- Theme + language disclosure items: `dsDropdownItemClass` / `dsDropdownItemClasses` / `dsDropdownPanelClass` in `App.DatastarShell` — **never** a second Daisy recipe in `DatastarShell`.
- Agent checklist: `docs/conventions/chrome-checklist.md`.
- Eval: `make eval EVAL=11-edit-chrome`.

## Changing chrome

Edit `DatastarShell.purs`, then update `ShellSpec` / e2e selectors if markers or structure change. Never put chrome in feature views.

## Tests

- `test/ShellSpec.purs` — header/main/footer markers
- `test/ContractSpec.purs` — full page + fragment shell shape
- `test/TemplateContractSpec.purs` — page section markers

See also: `docs/conventions/design-system.md`, ADR-012.
