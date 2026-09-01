# Site chrome checklist

Read this **before** editing navbar, drawer, footer, or theme controls.
Shell chrome is **not** feature code — it lives only in `App.Ui.Templates.SiteShell`.

Full recipe: `docs/superpowers/specs/2026-08-30-shell-recipe.md`.

## Where things live

| Concern | Module | Never in |
|---|---|---|
| Navbar, drawer, footer, theme menu | `App.Ui.Templates.SiteShell` | Feature `View.purs` |
| Route-aware nav links | `App.Alpine.navLink` + `navLinkClasses` | Hand-rolled `<a>` in features |
| Theme persistence / `data-theme` | `App.Theme`, `App.Alpine.setTheme` | Inline `html.dark` or raw JS |
| Alpine flags (menus, drawer) | `App.Alpine.Flag`, typed builders | Raw `x-data` strings |

## Adding or changing a nav item

1. **Route** — add constructor + codec in `Data.Route.purs` (every language in `allLangs` compile-checks).
2. **Copy** — add label in `Data.I18n` (`nav.*` or feature-specific) for each language in `allLangs`.
3. **Shell labels** — if the label is new to chrome, extend `ShellLabels` / `shellLabels` in `SiteShell.purs`.
4. **Wire links** — in `renderHeader` (desktop `desktopNavLink`), `renderDrawerSide` (`mobileNavLink`), and `renderFooter` (`footerLink`). Use the existing helpers; do not invent class strings.
5. **Tests** — run `make test` (`ShellSpec`, `ContractSpec`). If markers or structure change, update e2e selectors.

## Active route indicator (do not hand-roll)

`navLink` always sets `aria-current="page"` when `target == current` and skips hover prefetch on the active route.

Visual state comes from **`navLinkClasses`** — pick the surface:

| Surface | `NavChrome` | Active DaisyUI class |
|---|---|---|
| Desktop navbar | `NavDesktop` | `btn-active` on `btn btn-ghost btn-sm` |
| Mobile drawer menu | `NavMobile` | `menu-active` on `btn btn-ghost justify-start` |
| Footer | `NavFooter` | `link link-hover` (semantic only via `aria-current`) |

```purescript
navLink { lang, current, target }
  [ class_ (navLinkClasses NavDesktop (target == current)) ]
  [ text label ]
```

Never duplicate `btn-active` / `menu-active` logic in `SiteShell` — extend `navLinkClasses` if a new chrome surface appears.

## Theme switcher

- Themes: `pohjola` / `pohjola-dark` in `css/input.css`; `system` omits `data-theme`.
- Desktop: Alpine disclosure (`ThemeMenuOpen`) + Daisy `dropdown`, real `<button>`.
- Mobile drawer: flat theme buttons via `themeMenuItem`.
- Active theme: `classWhenTheme "btn-active"` — already wired; do not reinvent.

## Language switcher

- Desktop: `join join-horizontal` with `btn-active` on current lang.
- Mobile: `join join-vertical` in drawer.
- Uses plain `href` (full reload) — not `navLink` SPA swap.

## Pre-ship checks

- [ ] Changes only in `SiteShell.purs` (or `App.Alpine` if adding a seam).
- [ ] Nav links use `navLink` + `navLinkClasses`, not bespoke active classes.
- [ ] `Contract.marker` attributes unchanged unless intentional.
- [ ] `make gate` + `make test` pass.
- [ ] Eval: `make eval EVAL=11-edit-chrome --check` after nav/chrome edits.
