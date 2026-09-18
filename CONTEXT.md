# Pohjola

PureScript 0.15.16 + Bun SSR multi-page app. Alpine AJAX swaps the SiteShell drawer's `#content` region for same-origin navigation; there is no custom browser JavaScript beyond the pinned inline scripts.

## Language

**Feature**:
A route-rendering unit under `src/App/Features/<Name>/`, either static (`Page.purs` + `View.purs`) or data-backed (adds `Types.purs` + `Service.purs`).
_Avoid_: Module, page component

**Page**:
A feature's static entry point (`Page.purs`, `staticPage`) that assembles a `PageTemplate` from dictionary copy and hands it to `App.Ui.Templates.Render.renderPage`.
_Avoid_: Controller, handler

**View**:
A feature's `View.purs` — pure functions that fill a template's slot record from copy and route context. Feature views may only call slot constructors: no styling calls, no `class_`, no hardcoded text.
_Avoid_: Component, presenter

**Slot**:
A named field in a `PageTemplate` variant's record (e.g. `LandingHeroSlots.headline`) that a feature view fills. Slots are the only surface a feature view writes to.
_Avoid_: Prop, field (when talking about a template's public surface)

**Fixed-arity slot**:
A slot whose cardinality is a named record (`ValueSextuple`, `FeatureTriple`, `ImageTriple`, `HubCardTriple`) rather than an `Array`, so a wrong item count is a compile error instead of a silent runtime fallback. Adding a seventh item is a type change — a new field — not an array append.
_Avoid_: List slot, array slot

**PageTemplate**:
The closed algebra of page shapes a feature may render: `Landing | Editorial | Hub | Feed | Schedule | Article | Form`. Every `View.purs` imports `App.Ui.Templates.Render`; adding an eighth constructor requires extending `Policy.Contract.uiTemplateModules` plus an ADR.
_Avoid_: Layout, page type

**Route**:
A constructor of the `Route` ADT (currently `Home | About | Guarantees | Docs`) with one bidirectional codec per language — `print` and `parse` share the same codec, so a route missing from either language's URL space is a compile error, not a routing bug.
_Avoid_: Path, URL

**Chrome**:
The site-wide UI outside a feature's own content — nav, drawer, footer, close/menu labels — rendered by `App.Ui.Templates.SiteShell` and neighboring modules rather than by any feature. Chrome labels are meant to come from `Data.I18n`'s dictionary, not be hardcoded, but that rule is only mechanically enforced for feature views (see Content firewall).
_Avoid_: Layout chrome, shell (ambiguous with the `SiteShell` module itself)

**DocumentChrome**:
How a document delivers CSS and whether live-reload is on. Production inlines CSS and omits live-reload; `make dev` links the stylesheet file and emits the live-reload HeadScript.
_Avoid_: Chrome (that's nav/drawer/footer), theme

**Content firewall**:
`Policy.Contract`'s compile-time scan (part of `make gate`) that rejects hardcoded English-looking string literals (`text "..."`) in feature code and shared templates, forcing copy through `Data.I18n`. Glob: `src/App/Features/*/{Page,View}.purs` and `src/App/Ui/Templates/*.purs`.
_Avoid_: Copy gate, i18n gate — the firewall is one check among several `make gate` runs

**Statusful** (fragment or page):
A response carrying a `FormStatus` — a form submission's success/error result — rather than plain navigation. Statusful responses get `Cache-Control: no-store`; non-statusful ones get a short private cache. Both full pages and AJAX fragments share this policy via the `htmlOk` helper.
_Avoid_: Stateful — different meaning; this is about response cache policy, not application state

**Fragment**:
The `#content`-only HTML Alpine AJAX swaps in for same-origin navigation, as opposed to a full page (document, head, and chrome) served on direct navigation or reload.
_Avoid_: Partial, island — island names the not-yet-implemented ADR-010 browser-island runtime

**Gate**:
`make gate` — the structural policy scan (`Test.Gate` against `Policy.Contract` and `Policy.Law`): banned unsafe imports, the FFI allowlist, the content firewall, the closed template set, the feature-view contract, and catalog sync for every `Law`. Distinct from `make test` (behavioral specs) and `make check` (the full local verification ladder).
_Avoid_: Lint, policy check — several checks exist; "gate" names this specific structural one

**Law**:
A named constructor of `Policy.Law` whose `catalogNeedle` must appear in `docs/GUARANTEES.md`. Names which guarantees exist. The compiler forces a needle per constructor; `make gate` fails if the catalog omits one. Scan-config lists live in `Policy.Contract`; `Test.Policy.Scan` is the filesystem adapter.
_Avoid_: Guarantee (the catalog title), policy (the scan lists)
