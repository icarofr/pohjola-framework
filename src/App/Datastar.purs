-- | Datastar integration — the single seam between server-rendered HTML and
-- | browser interactivity (ADR-000, superseded 2026-09-09 to name this module
-- | instead of App.Alpine; ADR-011, superseded the same day to name Datastar
-- | as the bedrock shell transport instead of Alpine AJAX). Every unescaped
-- | `data-signals`/`data-show`/`data-on:`/`data-class`/`data-bind`/`data-text`
-- | string lives only here; `Test.Policy.GateSpec`'s hand-rolled-attribute
-- | gate enforces that.
-- |
-- | Every constructor here is closed over a typed domain value (ThemeMode,
-- | DsFlag, Route/Lang) rather than an unstructured String — the same
-- | "closed by construction, not convention" property ADR-000's CSP threat
-- | model addendum requires: an invalid theme, flag, or route is a compile
-- | error, never a runtime string that could carry injected expression
-- | syntax.
module App.Datastar
  ( datastarRequestHeader
  , dataPageTitleAttr
  , dataPageLangAttr
  , contentTarget
  , DsFlag(..)
  , flagName
  , dsSignalsInit
  , dsShowFlag
  , dsShowNotFlag
  , dsToggleFlag
  , dsSetFlag
  , dsBindFlag
  , dsClassWhenFlag
  , dsClassWhenTheme
  , dsShowTheme
  , dsNavGet
  , dsSpaLink
  , dsNavLinkRecord
  , dsLangLink
  , dsPrefetchHover
  , dsOnClickOutside
  , dsOnKeydownEscape
  , dsSetTheme
  ) where

import Prelude

import App.Html (Attr, Html, attr, el, href)
import App.Theme (ThemeMode(..), themeDarkName, themeLightName, themeModeName, themeStorageKey)
import Data.Route (Route, routeUrl)
import Data.I18n (Lang)

-- ============================================================================
-- Constants
-- ============================================================================

-- | Sent automatically by every Datastar @get/@post call — the server-side
-- | signal for "is this a Datastar action", entirely separate from any other
-- | request-shape detection the server does.
datastarRequestHeader :: String
datastarRequestHeader = "datastar-request"

dataPageTitleAttr :: String
dataPageTitleAttr = "data-page-title"

dataPageLangAttr :: String
dataPageLangAttr = "data-page-lang"

-- | The `id` every page's shell wrapper carries and every SSE patch targets
-- | — the one element Datastar's `datastar-patch-elements` event morphs on
-- | navigation, and what `App.Layout.Scripts`' `dsShellRouterScript` reads
-- | `data-page-title`/`data-page-lang` off of after a patch.
contentTarget :: String
contentTarget = "content"

-- ============================================================================
-- DsFlag — the closed set of boolean signal names the shell chrome needs
-- ============================================================================

data DsFlag
  = DsThemeMenuOpen
  | DsLangMenuOpen
  | DsDrawerOpen

derive instance eqDsFlag :: Eq DsFlag

flagName :: DsFlag -> String
flagName = case _ of
  DsThemeMenuOpen -> "_themeOpen"
  DsLangMenuOpen -> "_langOpen"
  DsDrawerOpen -> "_drawerOpen"

-- | Client-only theme preference. Underscore so Datastar's default GET
-- | filter omits it from `?datastar=`. localStorage key stays `theme`.
themeSignalName :: String
themeSignalName = "_theme"

-- ============================================================================
-- Signals — data-signals:name="value" (Datastar's data-signals syntax,
-- verified against data-star.dev/docs.md)
-- ============================================================================

-- | Initializes every flag the shell chrome needs, all false, plus the
-- | `_theme` signal read from localStorage (App.Theme.themeStorageKey).
dsSignalsInit :: Attr
dsSignalsInit =
  attr "data-signals"
    ( "{"
        <> themeSignalName
        <> ": (localStorage.getItem('"
        <> themeStorageKey
        <> "') || 'system'), "
        <> flagName DsThemeMenuOpen
        <> ": false, "
        <> flagName DsLangMenuOpen
        <> ": false, "
        <> flagName DsDrawerOpen
        <> ": false}"
    )

dsShowFlag :: DsFlag -> Attr
dsShowFlag f = attr "data-show" ("$" <> flagName f)

dsShowNotFlag :: DsFlag -> Attr
dsShowNotFlag f = attr "data-show" ("!$" <> flagName f)

dsToggleFlag :: DsFlag -> Attr
dsToggleFlag f = attr "data-on:click" ("$" <> flagName f <> " = !$" <> flagName f)

dsSetFlag :: DsFlag -> Boolean -> Attr
dsSetFlag f value =
  attr "data-on:click" ("$" <> flagName f <> " = " <> if value then "true" else "false")

-- | Two-way binds a form element's value to a flag's signal — verified
-- | against the vendored datastar.js source (the "bind" plugin's checkbox
-- | case: `e.checked = ...` / `i = (f) => f.checked`). Bare signal name, no
-- | `$` prefix (unlike every other constructor here, which builds a JS
-- | expression string) — `data-bind` identifies which signal to bind, it
-- | doesn't evaluate an expression.
-- |
-- | Real bug this closed: the mobile drawer's checkbox toggled its own
-- | `:checked` state purely via native `<label for>` clicks, entirely
-- | independent of `DsDrawerOpen` — so `dsOnKeydownEscape DsDrawerOpen`
-- | correctly set `$drawerOpen = false` on Escape, but nothing observed
-- | that signal, and the drawer stayed open. Caught live: the checkbox's
-- | `.checked` DOM property was still `true` after pressing Escape.
dsBindFlag :: DsFlag -> Attr
dsBindFlag f = attr "data-bind" (flagName f)

-- | Active-item highlight for a boolean flag's signal (e.g. current theme
-- | menu item) — data-class:CLASS="expr", per docs.md's data-class syntax.
dsClassWhenFlag :: String -> DsFlag -> Attr
dsClassWhenFlag className f = attr ("data-class:" <> className) ("$" <> flagName f)

-- | Active-item highlight for the theme dropdown's currently-selected entry.
-- | Takes ThemeMode, not an unstructured String, so the same closure ADR-000 requires
-- | for Alpine's Flag/Expr types holds here too.
dsClassWhenTheme :: String -> ThemeMode -> Attr
dsClassWhenTheme className mode =
  attr ("data-class:" <> className) ("$" <> themeSignalName <> " === '" <> themeModeName mode <> "'")

-- | Icon visibility keyed off the *selected* theme preference, not the
-- | resolved color scheme — see App.Ui.Templates.SiteShell's sunIcon/
-- | moonIcon/systemIcon doc for why (the active menu item and the visible
-- | icon must always agree, both read off the same `theme` signal).
dsShowTheme :: ThemeMode -> Attr
dsShowTheme mode = attr "data-show" ("$" <> themeSignalName <> " === '" <> themeModeName mode <> "'")

-- ============================================================================
-- Shell nav — hand-rolled on top of @get, since Datastar has no built-in
-- pushState/history (its own docs point to plain <a>). The pushState/
-- popstate wrapper itself lives in App.Layout.Scripts' dsShellRouterScript,
-- listening for the real "datastar-fetch" {type:"finished"} event Datastar
-- dispatches after every @get/@post.
-- ============================================================================

-- | evt.preventDefault() keeps the real href as a working no-JS fallback;
-- | @get(url) is Datastar's real, verified action syntax (data-star.dev/docs.md).
-- | Clears the mobile drawer first: DaisyUI's drawer is a checkbox inside
-- | #content, and Datastar's morph preserves input checked state, so a tab
-- | switch would otherwise leave the hamburger panel open.
dsNavGet :: Lang -> Route -> Attr
dsNavGet lang route =
  attr "data-on:click"
    ( "evt.preventDefault(); $"
        <> flagName DsDrawerOpen
        <> " = false; @get('"
        <> routeUrl lang route
        <> "', {payload: {}})"
    )

-- | Warm the browser's HTTP cache on hover. Bare `fetch` with the transport
-- | header, response discarded — Datastar `@get` would apply the patch, which
-- | is wrong on mouseenter. `el` (no `$`): `$el` compiles to a signal lookup.
-- |
-- | The query param is the empty object, not `JSON.stringify($)`. `@get` with
-- | `{payload: {}}` (and `_`-prefixed chrome) serializes to `?datastar={}`;
-- | stringify of the live store would include locals Datastar's `filtered()`
-- | drops. Hover, click, and popstate must share that identity or the click
-- | cannot reuse the hover's `private, max-age=180` response.
dsPrefetchHover :: Attr
dsPrefetchHover =
  attr "data-on:mouseenter"
    ( "var u = new URL(el.href); u.searchParams.set('datastar', '{}'); fetch(u.href, {headers: {'"
        <> datastarRequestHeader
        <> "': 'true'}})"
    )

-- | Internal navigation link — the shell-nav equivalent of App.Alpine's
-- | spaLink, used by shared UI primitives (App.Ui.Button, ActionLink) that
-- | render inside page content, not just chrome.
dsSpaLink :: Lang -> Route -> Array Attr -> Array Html -> Html
dsSpaLink lang route extraAttrs children =
  el "a"
    ( [ href (routeUrl lang route)
      , dsNavGet lang route
      , dsPrefetchHover
      ]
        <> extraAttrs
    )
    children

-- | Record-shaped nav link carrying the current route for aria-current and
-- | skipping prefetch on the page already showing — the shell-nav
-- | equivalent of App.Alpine's navLink, used by App.Ui.Breadcrumbs.
dsNavLinkRecord :: { lang :: Lang, current :: Route, target :: Route } -> Array Attr -> Array Html -> Html
dsNavLinkRecord { lang, current, target } extraAttrs children =
  el "a"
    ( [ href (routeUrl lang target)
      , dsNavGet lang target
      ]
        <> (if target == current then [ attr "aria-current" "page" ] else [])
        <> (if target == current then [] else [ dsPrefetchHover ])
        <> extraAttrs
    )
    children

-- | Like dsNavGet, but for the language switch specifically: closes the lang
-- | dropdown (`_langOpen`), not the mobile drawer (`_drawerOpen`). Regular
-- | nav closes the drawer because it's leaving the current view; a language
-- | switch re-renders the same view in another language, so a visitor
-- | picking a language from inside the open drawer stays in it. Theme
-- | switching (`dsSetTheme`) needs no equivalent carve-out at all: it never
-- | calls `@get` in the first place, so `_drawerOpen` is never touched.
dsLangNavGet :: Lang -> Route -> Attr
dsLangNavGet lang route =
  attr "data-on:click"
    ( "evt.preventDefault(); $"
        <> flagName DsLangMenuOpen
        <> " = false; @get('"
        <> routeUrl lang route
        <> "', {payload: {}})"
    )

-- | Language-switch link — compares Lang, not Route, unlike dsNavLinkRecord
-- | (staying on the same page, switching which language it's rendered in).
-- | The shell-nav equivalent of App.Alpine's langLink.
dsLangLink :: { targetLang :: Lang, currentLang :: Lang, route :: Route } -> Array Attr -> Array Html -> Html
dsLangLink { targetLang, currentLang, route } extraAttrs children =
  el "a"
    ( [ href (routeUrl targetLang route)
      , dsLangNavGet targetLang route
      ]
        <> (if targetLang == currentLang then [ attr "aria-current" "page" ] else [])
        <> (if targetLang == currentLang then [] else [ dsPrefetchHover ])
        <> extraAttrs
    )
    children

dsOnClickOutside :: DsFlag -> Attr
dsOnClickOutside f = attr "data-on:click__outside" ("$" <> flagName f <> " = false")

dsOnKeydownEscape :: DsFlag -> Attr
dsOnKeydownEscape f = attr "data-on:keydown__window__escape" ("$" <> flagName f <> " = false")

-- | Sets the theme signal + localStorage (App.Theme.themeStorageKey) +
-- | document.documentElement's data-theme, then closes the theme menu.
-- | Takes the closed ThemeMode ADT rather than an unstructured String, so an
-- | invalid mode is a compile error, not a silent no-op at runtime.
dsSetTheme :: ThemeMode -> Attr
dsSetTheme mode =
  attr "data-on:click"
    ( "$"
        <> themeSignalName
        <> " = '"
        <> themeModeName mode
        <> "'; localStorage.setItem('"
        <> themeStorageKey
        <> "', '"
        <> themeModeName mode
        <> "'); "
        <>
          ( case mode of
              ThemeSystem -> "document.documentElement.removeAttribute('data-theme')"
              ThemeDark -> "document.documentElement.setAttribute('data-theme', '" <> themeDarkName <> "')"
              ThemeLight -> "document.documentElement.setAttribute('data-theme', '" <> themeLightName <> "')"
          )
        <> "; $"
        <> flagName DsThemeMenuOpen
        <> " = false"
    )
