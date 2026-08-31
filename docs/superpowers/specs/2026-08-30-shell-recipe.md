# Shell recipe (DaisyUI site chrome)

**Status:** Active (supersedes App.Ui.Shell / Layout Header delegates)  
**Date:** 2026-08-31

Chrome is **template library code**, not feature code. Agents never invent navbar/footer markup.

## Module

| Module | Role | Markers (`Contract`) |
|---|---|---|
| `App.Ui.Templates.SiteShell` | Sticky navbar, mobile menu, footer | `site-header`, `site-footer` |

`renderPage` always wraps body content in `sitePage`. Feature views do not call SiteShell directly.

## Theme

- Themes: Daisy `pohjola` / `pohjola-dark` in `css/input.css` (`data-theme` on `<html>`).
- Persistence: `themeInitScript` applies stored preference before paint; `system` omits `data-theme` (Daisy `prefersdark`).
- Navbar switcher: DaisyUI `dropdown` + real `<button>` + Alpine `ThemeMenuOpen` (toggle, outside click, Escape) + `setTheme`.

## Changing chrome

Edit `SiteShell.purs`, then update `ShellSpec` / e2e selectors if markers or structure change. Never put chrome in feature views.

## Tests

- `test/ShellSpec.purs` — header/main/footer markers
- `test/ContractSpec.purs` — full page + fragment shell shape
- `test/TemplateContractSpec.purs` — page section markers

See also: `docs/conventions/design-system.md`, ADR-012.
