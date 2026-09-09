# Alpine contracts — typed attribute seams

Alpine attributes are typed constructors in `App.Alpine`. Two distinct rules,
with two different enforcement mechanisms — worth keeping straight:

- **Attribute names** — should only be built inside `App.Alpine`. Enforced by
  ContractSpec, which scans `src/` for `attr "x-"`, `attr "@"`, `attr ":"`,
  and `flag "x-"` outside that module. **This is a literal-text scan and it has
  a limit:** a non-literal construction such as `let k = "@click" in attr k …`
  evades it, because `App.Html.attr` is exported unrestricted. Treat it as a
  guard against accident, not against intent.
- **Expression payloads and identifiers** — cannot be written by hand at all.
  Enforced by the compiler: handlers take `Expr` (abstract, constructor not
  exported) and builders take `Flag` (a closed sum type). A string literal in
  either position is a type error.

The second rule closes ADR-000's Vector B by construction. Both halves are
needed: an abstract `Expr` alone still lets JavaScript in through the
identifier slot, since `setFlag "x; evil()" true` would render
`x; evil() = true`.

## The contract surface

Three constants bind the server-fragment layer to the Alpine AJAX layer:

- **`contentTarget`** — the DOM ID Alpine swaps on navigation (`"content"`).
  Pinned by ContractSpec: every rendered page must contain it.
- **`alpineRequestHeader`** — the request header signalling AJAX navigation
  (`"x-alpine-request"`). The server returns a fragment when **either** this
  header is present **or** `?_frag=1` is in the query string —
  `App.Main.isFragmentRequest` is a boolean OR, and both signals are supported
  deliberately (ADR-007). Responses carry `Vary: x-alpine-request` so caches
  split full pages from fragments.
- **`data-page-title`** — attribute on fragment responses. The inline head
  scripts read it to sync the document title on navigation. ContractSpec
  pins its presence in rendered output.
- **`data-page-lang`** — attribute on the same `#content` wrapper. The title
  sync script also sets `document.documentElement.lang` after fragment swaps,
  including language switches.

Deliberately just these two. SEO/social metadata (description, Open Graph,
Twitter, canonical, `og:locale` alternates, `hreflang` links) used to be
synced here too, but every consumer of those fields — crawlers, link
unfurlers — fetches the URL fresh via SSR and never executes this script, so
client-side syncing served no observer. The server-rendered `<head>`
(`App.Layout.Head.renderHead`) still emits all of it correctly on every
direct request; only the fragment-swap sync payload was trimmed.

`contentTarget`, `alpineRequestHeader`, `dataPageTitleAttr`, and
`dataPageLangAttr` are constants in `App.Alpine` — `Ui/Templates/SiteShell.purs`
and the inline head-sync script in `Layout/Scripts.purs` reference these
exports rather than restating the literals, so a rename is a single-file,
compiler-checked change instead of a repo-wide grep. The inline script's
JS-side `dataset` field names (e.g. `d.pageTitle`) still read as prose
matching each attribute name — that transformation is the DOM's own
spec-defined kebab-case → camelCase `dataset` mapping, not a second
hand-typed copy of the name.

## Typed constructors

Every Alpine attribute is a named constructor in `App.Alpine`:

### Attributes

| Constructor | Produces |
|---|---|
| `xDataFlag MenuOpen false` | `x-data="{ menuOpen: false }"` |
| `xDataThemeWithFlag ThemeMenuOpen LangMenuOpen false` | `x-data="{ theme: …, themeOpen: false, open: false }"` |
| `xShowFlag MenuOpen` | `x-show="menuOpen"` |
| `xShowNotFlag MenuOpen` | `x-show="!menuOpen"` |
| `ariaExpandedFlag MenuOpen` | `:aria-expanded="menuOpen.toString()"` |
| `xCloak` / `xSync` / `xAutofocus` | boolean attributes |
| `xTargetPush id` | `x-target.push="id"` |
| `prefetchHover` | `@mouseenter="fetch($el.href, …)"` |

### Handlers — each takes an `Expr`, never a `String`

`onClick`, `onClickOutside`, `onKeydownEscapeWindow`, `onMouseenter`.

### The only sources of `Expr`

| Builder | Produces |
|---|---|
| `setFlag f b` | `menuOpen = true` / `menuOpen = false` |
| `toggleFlag f` | `menuOpen = !menuOpen` |
| `themeToggle` | flips `data-theme` between `pohjola` and `pohjola-dark` and persists |

So a menu button is `onClick (toggleFlag MenuOpen)`, its panel is
`xShowFlag MenuOpen` with `onClickOutside (setFlag MenuOpen false)`.

### Adding an interaction

A new boolean UI state is a new `Flag` constructor. A new interaction shape is
a new builder in `App.Alpine`, plus an assertion in ContractSpec's "generated
expressions" block. There is deliberately no escape hatch — the same decision
the `Html` ADT makes about unescaped HTML (ADR-001).

If an interaction cannot be expressed as a named builder, that is a signal the
behaviour belongs on the server, not that the seam needs loosening.

## SPA navigation

- **`navLink`** — route-aware internal link: `x-target.push`, `aria-current="page"` when
  `target == current`, hover prefetch only when inactive. Use with
  **`navLinkClasses`** for shell surfaces (`NavDesktop` → `btn-active`,
  `NavMobile` → `menu-active`, `NavFooter` → `link link-hover`). Theme and
  language dropdown **items** use **`dropdownItemClasses`** (same ghost-button
  recipe for both menus). See `docs/conventions/chrome-checklist.md`.
- **`spaLink`** — bakes `x-target.push` + `prefetchHover` + real href. The
  prefetch sends `alpineRequestHeader` so the server returns a fragment the
  browser caches; the click hits cache with zero round-trip. Degrades to a
  normal `<a>` without JS.
- **`langLink`** — same `x-target.push` fragment-swap navigation as `navLink`,
  not a plain anchor; a language switch never full-reloads. Only `<html lang>`
  and `document.title` sync client-side afterward (the two fields with a real
  observer — see "Deliberately just these two" above); canonical/hreflang/
  OG stay correct in the server-rendered `<head>` because a reload was never
  needed for them to be right on the *next* direct request. Nav chrome lives
  in `App.Ui.Templates.SiteShell`.
- **`renderFragment`** — shared fragment builder (`Page.purs` + `Main.purs`).
  Fragments never stream (small, already fast).
- **Scroll on swap** — `TitleSync` listens for `ajax:merged` (Alpine AJAX
  navigation *and* the popstate restore path, which re-dispatches that event)
  and calls `window.scrollTo({ top: 0 })`. A fragment swap does not otherwise
  move the window, so without this the previous page's scroll would stick.

## Scopes

One `x-data` per component, one concern per scope. `xDataFlag` holds exactly
one boolean, which is the intended ceiling: once a scope needs several fields
that must agree with each other, you have a state machine, and Alpine flags are
the wrong representation. Move the work to the server.
