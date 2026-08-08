# Alpine contracts — typed attribute seams

Alpine attributes are typed constructors in `App.Alpine`. The compiler and
ContractSpec enforce that no raw Alpine attribute strings live outside that
module. Build with the constructors; reach for `attr` only inside `App.Alpine`.

## The contract surface

Three constants bind the server-fragment layer to the Alpine AJAX layer:

- **`contentTarget`** — the DOM ID Alpine swaps on navigation (`"content"`).
  Pinned by ContractSpec: every rendered page must contain it.
- **`alpineRequestHeader`** — the request header signalling AJAX navigation
  (`"x-alpine-request"`). The server checks it (AND `?_frag=1`) to return a
  fragment. Responses carry `Vary: x-alpine-request` so caches split full
  pages from fragments.
- **`data-page-title`** — attribute on fragment responses. The inline head
  scripts read it to sync the document title on navigation. ContractSpec
  pins its presence in rendered output.

If you rename any of these, grep the whole repo: `App.Alpine`, `Main.purs`,
`Layout/Page.purs`, and the inline head scripts all participate.

## Typed constructors

Every Alpine attribute is a named constructor in `App.Alpine`:

| Constructor | Produces | Use for |
|---|---|---|
| `xData` | `x-data="…"` | Component state (JS object literal) |
| `xShow` | `x-show="…"` | Conditional visibility (JS boolean) |
| `xCloak` | `x-cloak` | Hide until Alpine initializes |
| `xSync` | `x-sync` | Cross-component state sync |
| `xTargetPush` | `x-target.push="…"` | AJAX swap target (DOM ID) |
| `xAutofocus` | `x-autofocus` | Focus management |
| `onClick` | `@click="…"` | Click handler (JS statement) |
| `onClickOutside` | `@click.outside="…"` | Dismiss on outside click |
| `onKeydownEscapeWindow` | `@keydown.escape.window="…"` | Escape-key dismiss |
| `onMouseenter` | `@mouseenter="…"` | Hover events |
| `bindAriaExpanded` | `:aria-expanded="…"` | ARIA state binding |
| `prefetchHover` | `@mouseenter="fetch(…)"` | Hover prefetch (baked-in) |

To add a new Alpine attribute: add a constructor here, use it everywhere.
ContractSpec rejects raw Alpine strings (`x-`, `@`, `:`) outside `App.Alpine`.

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

One `x-data` per component, one concern per scope. Prefer server work when
an `x-data` exceeds 5 fields.
