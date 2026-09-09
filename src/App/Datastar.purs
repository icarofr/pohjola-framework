-- | Datastar integration — spike seam between server-rendered HTML and
-- | browser interactivity, mirroring App.Alpine's shape for the pages this
-- | branch ports (Home, About). Every unescaped `data-signals`/`data-show`/
-- | `data-on:`/`data-class`/`data-bind`/`data-text` string lives only here;
-- | `Test.Policy.GateSpec`'s hand-rolled-attribute gate mirrors the
-- | equivalent Alpine rule.
-- |
-- | Spike scope only (see .scratch/datastar-streaming-transport/spec.md):
-- | just the constructors ticket 03 (shell-nav) and ticket 04 (theme/lang
-- | dropdowns, mobile drawer) actually need. Not a full port of every
-- | App.Alpine constructor.
module App.Datastar
  ( datastarRequestHeader
  , dataPageTitleAttr
  , dataPageLangAttr
  , DsFlag(..)
  , flagName
  , dsSignalsInit
  , dsShowFlag
  , dsShowNotFlag
  , dsToggleFlag
  , dsSetFlag
  , dsClassWhenFlag
  , dsClassWhenEq
  , dsNavGet
  , dsOnClickOutside
  , dsOnKeydownEscape
  , dsSetTheme
  ) where

import Prelude

import App.Alpine (ThemeMode(..), themeModeName)
import App.Html (Attr, attr)
import App.Theme (themeDarkName, themeLightName, themeStorageKey)
import Data.Route (Route, routeUrl)
import Data.I18n (Lang)

-- ============================================================================
-- Constants — shared with App.Alpine's fragment contract (same #content,
-- same data-page-* payload); Datastar's own request-detection header is
-- separate and sent automatically by @get/@post, per its own docs.
-- ============================================================================

-- | Sent automatically by every Datastar @get/@post call. Server-side
-- | detection of "is this a Datastar action" must key off this, entirely
-- | separate from App.Alpine's alpineRequestHeader/?_frag=1 — the two must
-- | never be conflated (see spec.md's Implementation Decisions).
datastarRequestHeader :: String
datastarRequestHeader = "datastar-request"

dataPageTitleAttr :: String
dataPageTitleAttr = "data-page-title"

dataPageLangAttr :: String
dataPageLangAttr = "data-page-lang"

-- ============================================================================
-- DsFlag — the closed set of boolean signal names this spike needs
-- ============================================================================

data DsFlag
  = DsThemeMenuOpen
  | DsLangMenuOpen
  | DsDrawerOpen

derive instance eqDsFlag :: Eq DsFlag

flagName :: DsFlag -> String
flagName = case _ of
  DsThemeMenuOpen -> "themeOpen"
  DsLangMenuOpen -> "langOpen"
  DsDrawerOpen -> "drawerOpen"

-- ============================================================================
-- Signals — data-signals:name="value" (Datastar's data-signals syntax,
-- verified against data-star.dev/docs.md)
-- ============================================================================

-- | Initializes every flag this page's chrome needs, all false, plus the
-- | `theme` signal read from the *same* localStorage key App.Alpine's
-- | xDataTheme uses (App.Theme.themeStorageKey) -- so switching theme on
-- | either transport's version of a page is reflected consistently for a
-- | real side-by-side comparison, not two independent theme stores.
dsSignalsInit :: Attr
dsSignalsInit =
  attr "data-signals"
    ( "{theme: (localStorage.getItem('" <> themeStorageKey <> "') || 'system'), "
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

-- | Active-item highlight for a boolean flag's signal (e.g. current theme
-- | menu item) — data-class:CLASS="expr", per docs.md's data-class syntax.
dsClassWhenFlag :: String -> DsFlag -> Attr
dsClassWhenFlag className f = attr ("data-class:" <> className) ("$" <> flagName f)

-- | Active-item highlight for an equality check against a string signal
-- | (e.g. `$theme === 'dark'`, current language selection).
dsClassWhenEq :: String -> String -> String -> Attr
dsClassWhenEq className signal value =
  attr ("data-class:" <> className) ("$" <> signal <> " === '" <> value <> "'")

-- ============================================================================
-- Shell nav — hand-rolled on top of @get, since Datastar has no built-in
-- pushState/history (its own docs point to plain <a>; see spec.md). The
-- pushState/popstate wrapper itself lives in App.Layout.Scripts'
-- dsShellRouterScript, listening for the real "datastar-fetch"
-- {type:"finished"} event Datastar dispatches after every @get/@post.
-- ============================================================================

-- | evt.preventDefault() keeps the real href as a working no-JS fallback
-- | (same reasoning as App.Alpine.spaLink); @get(url) is Datastar's real,
-- | verified action syntax (data-star.dev/docs.md).
dsNavGet :: Lang -> Route -> Attr
dsNavGet lang route =
  attr "data-on:click" ("evt.preventDefault(); @get('" <> routeUrl lang route <> "')")

dsOnClickOutside :: DsFlag -> Attr
dsOnClickOutside f = attr "data-on:click__outside" ("$" <> flagName f <> " = false")

dsOnKeydownEscape :: DsFlag -> Attr
dsOnKeydownEscape f = attr "data-on:keydown__window__escape" ("$" <> flagName f <> " = false")

-- | Sets the theme signal + localStorage (App.Theme.themeStorageKey) +
-- | document.documentElement's data-theme, then closes the theme menu --
-- | same three effects as App.Alpine's xSetThemeAndClose, same closed
-- | ThemeMode ADT (App.Alpine.ThemeMode) rather than an unstructured String, so an
-- | invalid mode is a compile error here just as it is on the Alpine side.
dsSetTheme :: ThemeMode -> Attr
dsSetTheme mode =
  attr "data-on:click"
    ( "$theme = '" <> themeModeName mode <> "'; localStorage.setItem('" <> themeStorageKey <> "', '"
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
