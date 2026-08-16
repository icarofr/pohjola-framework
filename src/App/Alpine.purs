-- | Alpine.js integration — the single seam between server-rendered HTML and
-- | browser interactivity.
-- |
-- | Owns the swap target ID, the AJAX detection header, the `spaLink` helper,
-- | and every Alpine attribute the app is allowed to emit.
-- |
-- | ## Closing ADR-000's Vector B
-- |
-- | Alpine attribute values are JavaScript. ADR-000's threat model names
-- | Vector B — "user data flowing into an Alpine constructor argument
-- | (currently doesn't happen, but `xData :: String -> Attr` accepts
-- | anything)" — and its acceptance of `unsafe-eval` partly rested on that
-- | vector staying closed *by convention*.
-- |
-- | It is now closed by construction, at both levels:
-- |
-- |   * `Expr` is abstract — the type is exported, its constructor is not — so
-- |     an expression can only be produced by a builder in this module. A
-- |     string literal where an `Expr` is expected is a type error.
-- |   * `Flag` is a closed sum type, so the *identifier* inside a generated
-- |     expression cannot carry expression syntax either. Leaving the flag name
-- |     an open `String` would have let JavaScript in through the one slot the
-- |     `Expr` wrapper did not cover.
-- |
-- | Both halves are required. Neither alone closes the vector.
-- |
-- | This does **not** change the `unsafe-eval` decision. Alpine's standard
-- | build evaluates every attribute expression through `new Function()`
-- | regardless of how the expression was constructed, and the CSP build cannot
-- | call `fetch`, which `prefetchHover` needs. See ADR-000.
-- |
-- | There is deliberately no escape hatch, mirroring the `Html` ADT's refusal
-- | of an unescaped-HTML constructor (ADR-001). A new interaction shape is
-- | added as a named builder here — reviewed once, asserted by ContractSpec —
-- | rather than improvised at a call site.
module App.Alpine
  ( contentTarget
  , alpineRequestHeader
  , spaLink
  , navLink
  , Flag(..)
  , flagName
  , ThemeMode(..)
  , themeModeName
  , setTheme
  , cycleTheme
  , Expr
  , renderExpr
  , xDataFlag
  , xDataTheme
  , xShowFlag
  , xShowNotFlag
  , xShowTheme
  , setFlag
  , toggleFlag
  , ariaExpandedFlag
  , themeToggle
  , onClick
  , onClickOutside
  , onKeydownEscapeWindow
  , onMouseenter
  , prefetchHover
  , xTargetPush
  , xCloak
  , xSync
  , xAutofocus
  ) where

import Prelude

import App.Html (Attr, Html, attr, el, flag, href)
import Data.I18n (Lang)
import Data.Route (Route, routeUrl)

-- ============================================================================
-- Constants — the contract between server fragments and Alpine AJAX
-- ============================================================================

-- | The DOM element ID that Alpine AJAX swaps on navigation.
-- | Used by: Page.purs (defines the target), spaLink (targets it),
-- | Main.purs (fragment response must contain it).
contentTarget :: String
contentTarget = "content"

-- | The request header Alpine AJAX sends on click navigation.
-- |
-- | The server treats a request as a fragment request when this header is
-- | present **or** `?_frag=1` is in the query string — either signal is
-- | sufficient (`App.Main.isFragmentRequest` is a boolean OR). Both are
-- | supported deliberately per ADR-007: Alpine sends the header, while
-- | `?_frag=1` gives a header-free way to request a fragment (curl,
-- | integration tests, non-header clients) and a cache key independent of
-- | `Vary`.
alpineRequestHeader :: String
alpineRequestHeader = "x-alpine-request"

-- ============================================================================
-- Flag — the closed set of boolean UI state names
-- ============================================================================

-- | A boolean flag in an Alpine component's `x-data` scope.
-- |
-- | Closed on purpose. An open `String` here would reopen ADR-000's Vector B
-- | through the identifier slot: `setFlag "x; evil()" true` would render
-- | `x; evil() = true`. Adding a flag means adding a constructor, which is the
-- | same friction `Route` imposes and for the same reason.
data Flag
  = MenuOpen
  | LangMenuOpen
  | ModalOpen
  | ToastVisible
  | AccordionOpen
  | TabActive

derive instance eqFlag :: Eq Flag

instance showFlag :: Show Flag where
  show = case _ of
    MenuOpen -> "MenuOpen"
    LangMenuOpen -> "LangMenuOpen"
    ModalOpen -> "ModalOpen"
    ToastVisible -> "ToastVisible"
    AccordionOpen -> "AccordionOpen"
    TabActive -> "TabActive"

-- | The JavaScript identifier for a flag. Total.
flagName :: Flag -> String
flagName = case _ of
  MenuOpen -> "menuOpen"
  LangMenuOpen -> "open"
  ModalOpen -> "modalOpen"
  ToastVisible -> "toastVisible"
  AccordionOpen -> "accordionOpen"
  TabActive -> "tabActive"

-- ============================================================================
-- Theme modes
-- ============================================================================

data ThemeMode
  = ThemeLight
  | ThemeDark
  | ThemeSystem

derive instance eqThemeMode :: Eq ThemeMode

instance showThemeMode :: Show ThemeMode where
  show = case _ of
    ThemeLight -> "ThemeLight"
    ThemeDark -> "ThemeDark"
    ThemeSystem -> "ThemeSystem"

themeModeName :: ThemeMode -> String
themeModeName = case _ of
  ThemeLight -> "light"
  ThemeDark -> "dark"
  ThemeSystem -> "system"

-- ============================================================================
-- Expr — a generated Alpine/JS expression
-- ============================================================================

-- | An Alpine expression. Abstract by design: the constructor is not exported,
-- | so values come only from the builders below.
newtype Expr = Expr String

instance semigroupExpr :: Semigroup Expr where
  append (Expr "") b = b
  append a (Expr "") = a
  append (Expr a) (Expr b) = Expr (a <> "; " <> b)

instance monoidExpr :: Monoid Expr where
  mempty = Expr ""

-- | The rendered expression text. Exported so tests can assert on the
-- | generated JavaScript; not needed in order to build attributes.
renderExpr :: Expr -> String
renderExpr (Expr s) = s

boolLit :: Boolean -> String
boolLit true = "true"
boolLit false = "false"

-- ============================================================================
-- Expression builders — the vocabulary of interactions the app supports
-- ============================================================================

-- | Assign a flag: `setFlag MenuOpen false` → `menuOpen = false`
setFlag :: Flag -> Boolean -> Expr
setFlag f value = Expr (flagName f <> " = " <> boolLit value)

-- | Invert a flag: `toggleFlag MenuOpen` → `menuOpen = !menuOpen`
toggleFlag :: Flag -> Expr
toggleFlag f = Expr (flagName f <> " = !" <> flagName f)

-- | Theme toggle: flip the `dark` class on `<html>` and persist the result.
-- |
-- | The one multi-statement expression in the app. It lives here as a single
-- | named value so it is written once, reviewed once, and asserted by
-- | ContractSpec rather than retyped at a call site. The stored value is read
-- | back from `classList` *after* toggling — deriving it from the pre-toggle
-- | state would invert the theme on reload.
themeToggle :: Expr
themeToggle = Expr
  ( "document.documentElement.classList.toggle('dark'); "
      <> "localStorage.setItem('theme', document.documentElement.classList.contains('dark') ? 'dark' : 'light')"
  )

-- | Set explicit theme mode (Light, Dark, or System).
setTheme :: ThemeMode -> Expr
setTheme = case _ of
  ThemeLight ->
    Expr "localStorage.setItem('theme', 'light'); document.documentElement.classList.remove('dark')"
  ThemeDark ->
    Expr "localStorage.setItem('theme', 'dark'); document.documentElement.classList.add('dark')"
  ThemeSystem ->
    Expr "localStorage.setItem('theme', 'system'); (matchMedia('(prefers-color-scheme: dark)').matches ? document.documentElement.classList.add('dark') : document.documentElement.classList.remove('dark'))"

-- | Cycle theme through system -> light -> dark -> system.
cycleTheme :: Expr
cycleTheme = Expr
  ( "theme = (theme === 'system' ? 'light' : theme === 'light' ? 'dark' : 'system'); "
      <> "localStorage.setItem('theme', theme); "
      <> "if (theme === 'dark') { document.documentElement.classList.add('dark'); } "
      <> "else if (theme === 'light') { document.documentElement.classList.remove('dark'); } "
      <> "else { (window.matchMedia('(prefers-color-scheme: dark)').matches ? document.documentElement.classList.add('dark') : document.documentElement.classList.remove('dark')); }"
  )

-- | Fetch this link's fragment on hover, sending the AJAX header so the server
-- | answers with a fragment.
-- |
-- | Measured behaviour: this hover fetch is typically served from Chromium's
-- | prefetch cache (populated by `renderPrefetch`'s `<link rel="prefetch">`),
-- | so it is nearly free — but the click that follows still hits the network.
-- | The optimisation currently helps the hover rather than the click. See
-- | RECONCILIATION.md and `e2e/prefetch-cache.spec.js`.
prefetchExpr :: Expr
prefetchExpr = Expr
  ("fetch($el.href, {headers: {'" <> alpineRequestHeader <> "': 'true'}})")

-- ============================================================================
-- Attribute constructors
-- ============================================================================

-- | Alpine component scope holding one boolean flag:
-- | `xDataFlag MenuOpen false` → `x-data="{ menuOpen: false }"`
xDataFlag :: Flag -> Boolean -> Attr
xDataFlag f value =
  attr "x-data" ("{ " <> flagName f <> ": " <> boolLit value <> " }")

-- | Alpine component scope holding theme state (system, dark, light):
-- | `xDataTheme` → `x-data="{ theme: (localStorage.getItem('theme') || 'system') }"`
xDataTheme :: Attr
xDataTheme =
  attr "x-data" "{ theme: (localStorage.getItem('theme') || 'system') }"

-- | Visible while the flag is true.
xShowFlag :: Flag -> Attr
xShowFlag f = attr "x-show" (flagName f)

-- | Visible while the flag is false.
xShowNotFlag :: Flag -> Attr
xShowNotFlag f = attr "x-show" ("!" <> flagName f)

-- | Visible when theme matches the given mode.
xShowTheme :: ThemeMode -> Attr
xShowTheme mode = attr "x-show" ("theme === '" <> themeModeName mode <> "'")

-- | `aria-expanded` bound to a flag. Ties the accessible state to the same
-- | flag that drives visibility, so the two cannot drift apart.
ariaExpandedFlag :: Flag -> Attr
ariaExpandedFlag f = attr ":aria-expanded" (flagName f <> ".toString()")

-- | Hide element until Alpine initializes (boolean attribute, no value).
xCloak :: Attr
xCloak = flag "x-cloak"

-- | Sync state across Alpine components (boolean attribute).
xSync :: Attr
xSync = flag "x-sync"

-- | Alpine AJAX navigation target. Takes the DOM element ID to swap.
xTargetPush :: String -> Attr
xTargetPush = attr "x-target.push"

-- | Focus management (boolean attribute).
xAutofocus :: Attr
xAutofocus = flag "x-autofocus"

-- ============================================================================
-- Event handlers — every one takes a generated Expr
-- ============================================================================

onClick :: Expr -> Attr
onClick e = attr "@click" (renderExpr e)

onClickOutside :: Expr -> Attr
onClickOutside e = attr "@click.outside" (renderExpr e)

onKeydownEscapeWindow :: Expr -> Attr
onKeydownEscapeWindow e = attr "@keydown.escape.window" (renderExpr e)

onMouseenter :: Expr -> Attr
onMouseenter e = attr "@mouseenter" (renderExpr e)

-- | Hover prefetch attribute — see `prefetchExpr`.
prefetchHover :: Attr
prefetchHover = onMouseenter prefetchExpr

-- ============================================================================
-- SPA link helper
-- ============================================================================

-- | Navigation link with Alpine AJAX enhancement.
-- |
-- | Bakes in `x-target.push` (swap the content target) and hover prefetch.
-- | The prefetch sends the `x-alpine-request` header so the server returns
-- | a fragment rather than a full page.
-- |
-- | If JS is disabled this degrades to a normal `<a>` — the href is real.
-- | Additional attributes (class, aria-label, …) pass through.
-- |
-- | `App.Ui.Button.buttonLink` delegates here rather than emitting these
-- | attributes itself, so internal navigation is decided in one place.
spaLink :: Lang -> Route -> Array Attr -> Array Html -> Html
spaLink lang route extraAttrs children =
  el "a"
    ( [ href (routeUrl lang route)
      , xTargetPush contentTarget
      , prefetchHover
      ] <> extraAttrs
    )
    children

-- | Navigation link that knows whether it points at the page already shown.
-- |
-- | Identical to `spaLink` except that hover prefetch is omitted when
-- | `target == current`. That case is not hypothetical: after an AJAX swap the
-- | header re-renders, the new link for the *current* route lands under the
-- | user's stationary cursor, `mouseenter` fires again, and `prefetchHover`
-- | fetches the page already on screen. Measured at one wholly redundant
-- | request per navigation (see `e2e/prefetch-cache.spec.js`).
-- |
-- | Use this for any link rendered from a list of routes — header and footer
-- | nav — since those are the only places a link can target the current page.
-- | `spaLink` remains correct for links that structurally cannot self-target
-- | (a post card, a back-link, a CTA).
-- |
-- | The record argument is deliberate: two adjacent `Route` positionals would
-- | silently invert this behaviour if swapped, and the compiler could not tell.
navLink :: { lang :: Lang, current :: Route, target :: Route } -> Array Attr -> Array Html -> Html
navLink { lang, current, target } extraAttrs children =
  el "a"
    ( [ href (routeUrl lang target)
      , xTargetPush contentTarget
      ]
        <> (if target == current then [] else [ prefetchHover ])
        <> extraAttrs
    )
    children
