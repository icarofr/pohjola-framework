# Site chrome checklist

Read this **before** editing navbar, drawer, footer, or theme controls.
Shell chrome is **not** feature code — it lives only in `App.DatastarShell`.

Full recipe: `docs/superpowers/specs/2026-08-30-shell-recipe.md`.

Chrome color: `DESIGN.md`'s Elevation & Depth **Level 2 (Dock / Terminal)**
— navbar and footer are always the secondary/obsidian surface
(`bg-secondary text-secondary-content`, `data-theme="pohjola-dark"`
scoped on the element), never `base-*`. One color, no light/dark variant:
Level 2 doesn't follow the page's own theme toggle.

## Where things live

| Concern | Module | Never in |
|---|---|---|
| Navbar, drawer, footer, theme menu | `App.DatastarShell` | Feature `View.purs` |
| Route-aware nav links | `App.Datastar.dsNavLinkRecord` + `dsActiveNavClass` | Hand-rolled `<a>` in features |
| Theme persistence / `data-theme` | `App.Theme`, `App.Datastar.dsSetTheme` | Inline `html.dark` or raw JS |
| Datastar flags (menus, drawer) | `App.Datastar.DsFlag`, typed builders | Raw `data-signals` strings |

## Adding or changing a nav item

1. **Route** — add constructor + codec in `Data.Route.purs` (every language in `allLangs` compile-checks).
2. **Copy** — add label in `Data.I18n` (`nav.*` or feature-specific) for each language in `allLangs`.
3. **Shell labels** — if the label is new to chrome, extend `ShellLabels` / `shellLabels` in `DatastarShell.purs`.
4. **Wire links** — in `renderHeader` (desktop `desktopNavLink`), `renderDrawerSide` (`mobileNavLink`), and `renderFooter` (`footerLink`). Use the existing helpers; do not invent class strings.
5. **Tests** — run `make test` (`ShellSpec`, `ContractSpec`). If markers or structure change, update e2e selectors.

## Active route indicator (do not hand-roll)

`dsNavLinkRecord` always sets `aria-current="page"` when `target == current` and skips hover prefetch on the active route.

Visual state comes from **`dsActiveNavClass`** — pick the base class for the surface:

| Surface | Base class | Active class |
|---|---|---|
| Desktop navbar | `btn btn-ghost btn-sm` | `text-primary font-semibold` |
| Mobile drawer menu | `btn btn-ghost justify-start` | `text-primary font-semibold` |
| Footer | (fixed, ignores active state) | `link link-hover hover:text-primary` (semantic only via `aria-current`) |

`text-primary` (the brand color), not `btn-active`/`menu-active` — both resolve
to a flat neutral-gray fill in this theme, indistinguishable enough from an
unselected item that "active" carried almost no visible signal.

```purescript
dsNavLinkRecord { lang, current, target }
  [ class_ (dsActiveNavClass "btn btn-ghost btn-sm" (target == current)) ]
  [ text label ]
```

Never duplicate this active-state logic in `DatastarShell` — extend `dsActiveNavClass` if a new chrome surface appears.

## Theme switcher

- Themes: `pohjola` / `pohjola-dark` in `css/input.css`; `system` omits `data-theme`.
- Desktop: Datastar disclosure (`DsThemeMenuOpen`) + Daisy `dropdown`, real `<button>`.
- Mobile drawer: the same `themeMenuItem` list, no popover to close.
- Active theme: `dsClassWhenTheme "btn-active"` on `dsDropdownItemClass` — already wired; do not reinvent.

## Language switcher

- Desktop: Datastar disclosure (`DsLangMenuOpen`) + the **same** Daisy `dropdown` recipe as theme (`dsDropdownTriggerClass`, `dsDropdownPanelClass`, `dsDropdownItemClasses`).
- Mobile drawer: flat language links via `langMenuItem` — same `dsDropdownItemClasses` as the theme rows beside them.
- Uses `dsLangLink` (Datastar `@get` action), not a full reload. Active language: `dsDropdownItemClasses (target == current)`.

Never hand-roll a second dropdown width or item class in `DatastarShell` — change `dsDropdownPanelClass` / `dsDropdownItemClass` in `App.DatastarShell` so both menus move together.

## Pre-ship checks

- [ ] Changes only in `DatastarShell.purs` (or `App.Datastar` if adding a seam).
- [ ] Nav links use `dsNavLinkRecord` + `dsActiveNavClass`, not bespoke active classes.
- [ ] `Contract.marker` attributes unchanged unless intentional.
- [ ] `make gate` + `make test` pass.
- [ ] Eval: `make eval EVAL=11-edit-chrome CHECK=1` after nav/chrome edits.
