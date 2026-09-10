# Datastar contracts — typed attribute seams

Datastar attributes are typed constructors in `App.Datastar`. Two distinct
rules, with two different enforcement mechanisms — worth keeping straight:

- **Attribute names** — should only be built inside `App.Datastar`. Enforced
  by the gate (`Test.Policy.Scan.findRawDatastarOutsideDatastar`), which scans
  `src/` for `attr "data-signals`, `attr "data-show`, `attr "data-on:`,
  `attr "data-bind`, `attr "data-class`, and `attr "data-text` (both the
  bare-literal and parenthesized-literal forms) outside that module. This is
  scoped to Datastar's own reactive vocabulary, not a blanket `data-*` ban —
  Pohjola has plenty of unrelated `data-*` attributes (`data-theme`,
  `data-form-status`, `data-page-title`, `data-template`, …) that have nothing
  to do with Datastar. **This is a literal-text scan and it has a limit:** a
  non-literal construction such as `let k = "data-show" in attr k …` evades
  it, because `App.Html.attr` is exported unrestricted. Treat it as a guard
  against accident, not against intent.
- **Expression payloads and identifiers** — closed over typed domain values
  wherever Pohjola controls the shape: `dsSetTheme`/`dsShowTheme`/
  `dsClassWhenTheme` take `App.Theme.ThemeMode` (a closed sum type), and
  `dsShowFlag`/`dsToggleFlag`/`dsSetFlag`/`dsClassWhenFlag` take
  `App.Datastar.DsFlag` (a closed sum type) rather than an unstructured
  `String` identifier. A string literal in either position is a type error.
  This is the same "closed by construction, not convention" property ADR-000
  requires — see its CSP threat-model addendum for the full argument.

## The contract surface

Four constants bind the server-render layer to the Datastar client layer:

- **`contentTarget`** — the DOM ID Datastar's SSE patch morphs on navigation
  (`"content"`). Pinned by ContractSpec: every rendered page must contain it.
- **`datastarRequestHeader`** — the request header Datastar's client sends
  automatically on every `@get`/`@post` action (`"datastar-request"`). The
  server returns an SSE patch when this header is present —
  `App.Main.isDatastarRequest` — and every HTML response carries
  `Vary: datastar-request` so caches split full documents from patches.
- **`data-page-title`** — attribute on the `#content` wrapper. The shell-router
  script (`App.Layout.Scripts.dsShellRouterScript`) reads it to sync the
  document title after a patch. ContractSpec pins its presence in rendered
  output.
- **`data-page-lang`** — attribute on the same `#content` wrapper. The
  shell-router script also sets `document.documentElement.lang` after a
  patch, including language switches.

Deliberately just these two. SEO/social metadata (description, Open Graph,
Twitter, canonical, `og:locale` alternates, `hreflang` links) is never synced
client-side — every consumer of those fields (crawlers, link unfurlers)
fetches the URL fresh via SSR and never executes the shell-router script, so
client-side syncing would serve no observer. The server-rendered `<head>`
(`App.Layout.Head.renderHead`) emits all of it correctly on every direct
request; only the patch payload was trimmed to what a browser tab actually
observes.

`contentTarget`, `datastarRequestHeader`, `dataPageTitleAttr`, and
`dataPageLangAttr` are constants in `App.Datastar` — `App.DatastarShell` and
the shell-router script in `Layout/Scripts.purs` reference these exports
rather than restating the literals, so a rename is a single-file,
compiler-checked change instead of a repo-wide grep. The inline script's
JS-side `dataset` field names (e.g. `d.pageTitle`) still read as prose
matching each attribute name — that transformation is the DOM's own
spec-defined kebab-case → camelCase `dataset` mapping, not a second
hand-typed copy of the name.

## Typed constructors

Every Datastar attribute is a named constructor in `App.Datastar`:

### Attributes

| Constructor | Produces |
|---|---|
| `dsSignalsInit` | `data-signals="{_theme: …, _themeOpen: false, _langOpen: false, _drawerOpen: false}"` |
| `dsShowFlag DsThemeMenuOpen` | `data-show="$_themeOpen"` |
| `dsShowNotFlag DsThemeMenuOpen` | `data-show="!$_themeOpen"` |
| `dsShowTheme ThemeLight` | `data-show="$_theme === 'light'"` |
| `dsClassWhenFlag "dropdown-open" DsLangMenuOpen` | `data-class:dropdown-open="$_langOpen"` |
| `dsClassWhenTheme "btn-active" ThemeDark` | `data-class:btn-active="$_theme === 'dark'"` |
| `dsPrefetchHover` | `data-on:mouseenter` fetch of `el.href` + `?datastar={}` |

### The only sources of `data-on:*` expressions

| Builder | Produces |
|---|---|
| `dsSetFlag f b` | `$_themeOpen = true` / `$_themeOpen = false` |
| `dsToggleFlag f` | `$_themeOpen = !$_themeOpen` |
| `dsSetTheme mode` | sets `$_theme`, localStorage, `document.documentElement`'s `data-theme`, and closes the theme menu — exhaustive `case` over `ThemeMode` |
| `dsNavGet lang route` | `evt.preventDefault(); $_drawerOpen = false; @get('/en/about', {payload: {}})` |
| `dsOnClickOutside f` / `dsOnKeydownEscape f` | `$flag = false` on the matching Datastar event modifier |

So a menu button is `dsToggleFlag DsThemeMenuOpen`, its panel is
`dsShowFlag DsThemeMenuOpen` with `dsOnClickOutside DsThemeMenuOpen`.

### Adding an interaction

A new boolean UI state is a new `DsFlag` constructor. A new interaction shape
is a new builder in `App.Datastar`. There is deliberately no escape hatch —
the same decision the `Html` ADT makes about unescaped HTML (ADR-001).

If an interaction cannot be expressed as a named builder, that is a signal the
behaviour belongs on the server, not that the seam needs loosening.

## Shell navigation

- **`dsNavLinkRecord`** — route-aware internal link: `@get` action,
  `aria-current="page"` when `target == current`, hover prefetch only when
  inactive. Use with **`dsActiveNavClass`** for shell surfaces
  (desktop/mobile → `text-primary font-semibold`; footer links use a fixed
  `link link-hover hover:text-primary` regardless of active state). Theme and
  language dropdown **items** use **`dsDropdownItemClasses`** (same
  ghost-button recipe for both menus). See `docs/conventions/chrome-checklist.md`.
- **`dsSpaLink`** — bakes `@get` + `dsPrefetchHover` + real href, for shared UI
  primitives that render inside page content, not just chrome (`App.Ui.Button`,
  `App.Ui.Templates.ActionLink`). The prefetch sends `datastarRequestHeader` so
  the server returns a cacheable patch (`private, max-age=180` plus ETag),
  **and the click hits that cache**: `dsPrefetchHover` and `@get(url, {payload: {}})`
  both send `?datastar={}`, and chrome signals are `_`-prefixed so Datastar's
  default filter would have dropped them anyway. Hover, click, and popstate
  share that identity — see `e2e/prefetch-cache.spec.js` and ADR-015. Degrades to a normal
  `<a>` without JS regardless.
- **`dsLangLink`** — same `@get` action-based navigation as `dsNavLinkRecord`,
  but compares **Lang**, not Route (staying on the same page, switching which
  language it renders in) — a language switch never full-reloads. Only
  `<html lang>` and `document.title` sync client-side afterward (the two
  fields with a real observer — see "Deliberately just these two" above);
  canonical/hreflang/OG stay correct in the server-rendered `<head>` because a
  reload was never needed for them to be right on the *next* direct request.
  Nav chrome lives in `App.DatastarShell`.
- **The shell router (`App.Layout.Scripts.dsShellRouterScript`)** — the one
  piece of hand-written JS this seam needs, because Datastar itself has no
  `pushState`/`popstate` support (its own docs point to plain `<a>` navigation
  instead). Forward nav listens for Datastar's own `datastar-fetch`
  `{type:"finished"}` event (dispatched *after* the SSE patch is already
  applied) and only needs to `pushState` + sync title/lang + scroll to top.
  Back/forward re-fetches as a Datastar request with the same `?datastar={}`
  identity, parses the `data: elements `
  payload out of the SSE body, and replaces `#content` wholesale.

## Scopes

One reactive signal set per page shell, one concern per flag. `DsFlag` holds
exactly one boolean per constructor, which is the intended ceiling: once a
scope needs several fields that must agree with each other, you have a state
machine, and Datastar flags are the wrong representation. Move the work to the
server.

The site shell is the one documented exception: `dsSignalsInit` is a closed
constructor that always emits `_theme`, `_themeOpen`, `_langOpen`, and
`_drawerOpen` together. Do not reopen it as a positional per-flag signal
declaration — that is how `LangMenuOpen` shipped uninitialized in this
project's earlier Alpine-based chrome.
