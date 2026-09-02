# DaisyUI & App.Ui component checklist

Read this **before** adding UI capability, wrapping a DaisyUI component, or extending a page template.

**Page intent first:** [`docs/superpowers/specs/2026-08-31-page-architectures.md`](../superpowers/specs/2026-08-31-page-architectures.md) — pick `PageTemplate` before touching daisyUI.

**Component syntax:** `vendor/daisyui/skills/daisyui/components/<name>.md` (vendored with `make deps`) — use when adding `App.Ui` primitives, not when authoring feature pages.

Shell chrome (navbar, drawer, footer) → [`chrome-checklist.md`](chrome-checklist.md).

## Decision tree

```
Need UI on a feature page?
├─ Yes → Does a PageTemplate slot cover it?
│        ├─ Yes → Fill slots via renderPage (eval 10)
│        └─ No  → Extend App.Ui.Templates.* slot record + render inside template
└─ Need a new DaisyUI primitive?
         → App.Ui.* module (this checklist §3)
```

Feature `View.purs` and `Components/*.purs` **never** call `class_` or import `App.Ui.*` primitives — enforced by `make gate`.

## 1. Feature pages (agents start here)

| Page purpose | Template | Exemplar | Eval |
|---|---|---|---|
| Marketing landing | `Landing` | `Home/View.purs` | `01-add-page`, `10-ui-archetypes` |
| Hub / link grid | `Hub` | `Contact/View.purs` | `10-ui-archetypes` |
| Long-form editorial | `Editorial` | `About/View.purs` | `10-ui-archetypes` |
| Content feed | `Feed` | `Posts/View.purs` | `02-add-data-page` |
| Article detail | `Article` | `Posts/View.purs` | `02-add-data-page` |
| Match schedule / fixtures | `Schedule` | `Fixtures/View.purs` | `10-ui-archetypes` |
| Signup / contact form | `Form` | slots in View → `Templates/Form` | see `forms.md` |

**Do not** use `Feed` for schedules, calendars, or crest rows — use `Schedule`.
**Do not** import `App.Ui.Form` in features — use the `Form` `PageTemplate`.

```purescript
renderPage lang MyRoute status (Editorial (pageSlots lang))
-- or Hub, Landing, Feed, Article, Schedule, Form — slots only, no class_
```

In-page titles use `PageHeader` inside templates (`page-header`, `page-header-breadcrumbs`, `page-header-body` markers) — features pass `title` / `subtitle` / `breadcrumbs` via slots only.

## 2. Extend a template slot (not a primitive)

When a page type needs new optional UI (breadcrumbs, stats row, aside):

1. Add typed fields to the slot record in `App.Ui.Templates.Types`.
2. Render inside the matching `App.Ui.Templates.*` module using existing `App.Ui` primitives.
3. Add a `Contract` marker if the slot is test-visible.
4. Update exemplar feature view (e.g. `Contact/View.purs` for Hub breadcrumbs).
5. Extend `TemplateContractSpec` if marker counts change.
6. Run `make eval EVAL=12-add-ui-component CHECK=1`.

## 3. Add an App.Ui primitive

When a DaisyUI pattern is reused across templates:

1. Read the vendor recipe: `vendor/daisyui/skills/daisyui/components/<name>.md` (`make deps` initializes submodule).
2. Create `src/App/Ui/<Name>.purs` — follow `App.Ui.Button.purs` or `App.Ui.Breadcrumbs.purs`:
   - Module header cites vendor doc path
   - Typed variants (not raw class strings at call sites outside App.Ui)
   - Export render functions only; classes stay inside the module
3. Use **only** from `App.Ui.Templates.*` or other `App.Ui.*` — never from features.
4. Add row to `docs/conventions/design-system.md` §4 and run `make ui-coverage`.
5. Run `make gate && make test`.

Do **not** add to `App.Ui.purs` barrel unless multiple templates need re-export — features must not import the barrel anyway.

## 4. Chrome-only patterns

These DaisyUI patterns live in `App.Ui.Templates.SiteShell` only:

| Pattern | DaisyUI | Location |
|---|---|---|
| Drawer + overlay | `drawer`, `drawer-overlay` | `renderDrawerSide` |
| Navbar | `navbar` | `renderHeader` |
| Theme dropdown | `dropdown` | `renderThemeDropdown` |
| Mobile menu | `menu`, `menu-active` | `renderDrawerSide` |

Use `navLink` + `navLinkClasses` for route links — see chrome checklist.

## 5. Coverage map

Run `make ui-coverage` to regenerate `docs/conventions/ui-coverage.md` (App.Ui ↔ vendor doc index).

## Pre-ship checks

- [ ] Feature views: `renderPage` + slots only; no forbidden imports (`make gate`).
- [ ] New classes only in `App.Ui` / Templates; extend `Policy.Contract` closed sets if adding modules.
- [ ] Both `En` and `Fr` copy in `Data.I18n` when user-visible strings change.
- [ ] `make gate && make test && make test/e2e` pass.
- [ ] Eval: `make eval EVAL=12-add-ui-component CHECK=1` after component/template UI work.
