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

If you rename any of these, grep the whole repo: `App.Alpine`, `Main.purs`,
`Layout/Page.purs`, and the inline head scripts all participate.

## Typed constructors

Every Alpine attribute is a named constructor in `App.Alpine`:

### Attributes

| Constructor | Produces |
|---|---|
| `xDataFlag MenuOpen false` | `x-data="{ menuOpen: false }"` |
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
| `themeToggle` | flips the `dark` class on `<html>` and persists it |

So a menu button is `onClick (toggleFlag MenuOpen)`, its panel is
`xShowFlag MenuOpen` with `onClickOutside (setFlag MenuOpen false)`.

### Adding an interaction

A new boolean UI state is a new `Flag` constructor. A new interaction shape is
a new builder in `App.Alpine`, plus an assertion in ContractSpec's "generated
expressions" block. There is deliberately no escape hatch — the same decision
the `Html` ADT makes about unescaped HTML (ADR-001).

If an interaction cannot be expressed as a named builder, that is a signal the
behavior belongs on the server, not that the seam needs loosening.

## SPA navigation

- **`spaLink`** — bakes `x-target.push` + `prefetchHover` + real href. The
  prefetch sends `alpineRequestHeader` so the server returns a fragment the
  browser caches; the click hits cache with zero round-trip. Degrades to a
  normal `<a>` without JS.
- **Language toggles are plain anchors** — `<html lang>`, canonical/hreflang,
  and head metadata require a full reload. See `Layout/Header.purs` module
  header.
- **`renderFragment`** — shared fragment builder (`Page.purs` + `Main.purs`).
  Fragments never stream (small, already fast).

## Scopes

One `x-data` per component, one concern per scope. `xDataFlag` holds exactly
one boolean, which is the intended ceiling: once a scope needs several fields
that must agree with each other, you have a state machine, and Alpine flags are
the wrong representation. Move the work to the server.
