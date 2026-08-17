-- | Alpine.js integration — the single seam between server-rendered HTML and
-- | browser interactivity.
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

contentTarget :: String
contentTarget = "content"

alpineRequestHeader :: String
alpineRequestHeader = "x-alpine-request"

-- ============================================================================
-- Flag — the closed set of boolean UI state names
-- ============================================================================

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

newtype Expr = Expr String

instance semigroupExpr :: Semigroup Expr where
  append (Expr "") b = b
  append a (Expr "") = a
  append (Expr a) (Expr b) = Expr (a <> "; " <> b)

instance monoidExpr :: Monoid Expr where
  mempty = Expr ""

renderExpr :: Expr -> String
renderExpr (Expr s) = s

boolLit :: Boolean -> String
boolLit true = "true"
boolLit false = "false"

-- ============================================================================
-- Expression builders
-- ============================================================================

setFlag :: Flag -> Boolean -> Expr
setFlag f value = Expr (flagName f <> " = " <> boolLit value)

toggleFlag :: Flag -> Expr
toggleFlag f = Expr (flagName f <> " = !" <> flagName f)

-- | Theme toggle: flip the `dark` class and `data-theme` on `<html>` and persist.
themeToggle :: Expr
themeToggle = Expr
  ( "document.documentElement.classList.toggle('dark'); "
      <> "document.documentElement.setAttribute('data-theme', document.documentElement.classList.contains('dark') ? 'dim' : 'nord'); "
      <> "localStorage.setItem('theme', document.documentElement.classList.contains('dark') ? 'dark' : 'light')"
  )

-- | Set explicit theme mode (Light, Dark, or System) for DaisyUI + Tailwind.
setTheme :: ThemeMode -> Expr
setTheme = case _ of
  ThemeLight ->
    Expr "localStorage.setItem('theme', 'light'); document.documentElement.setAttribute('data-theme', 'nord'); document.documentElement.classList.remove('dark')"
  ThemeDark ->
    Expr "localStorage.setItem('theme', 'dark'); document.documentElement.setAttribute('data-theme', 'dim'); document.documentElement.classList.add('dark')"
  ThemeSystem ->
    Expr "localStorage.setItem('theme', 'system'); document.documentElement.removeAttribute('data-theme'); (matchMedia('(prefers-color-scheme: dark)').matches ? document.documentElement.classList.add('dark') : document.documentElement.classList.remove('dark'))"

-- | Cycle theme through system -> light -> dark -> system for DaisyUI + Tailwind.
cycleTheme :: Expr
cycleTheme = Expr
  ( "theme = (theme === 'system' ? 'light' : theme === 'light' ? 'dark' : 'system'); "
      <> "localStorage.setItem('theme', theme); "
      <> "if (theme === 'dark') { document.documentElement.setAttribute('data-theme', 'dim'); document.documentElement.classList.add('dark'); } "
      <> "else if (theme === 'light') { document.documentElement.setAttribute('data-theme', 'nord'); document.documentElement.classList.remove('dark'); } "
      <> "else { document.documentElement.removeAttribute('data-theme'); (window.matchMedia('(prefers-color-scheme: dark)').matches ? document.documentElement.classList.add('dark') : document.documentElement.classList.remove('dark')); }"
  )

prefetchExpr :: Expr
prefetchExpr = Expr
  ("fetch($el.href, {headers: {'" <> alpineRequestHeader <> "': 'true'}})")

-- ============================================================================
-- Attribute constructors
-- ============================================================================

xDataFlag :: Flag -> Boolean -> Attr
xDataFlag f value =
  attr "x-data" ("{ " <> flagName f <> ": " <> boolLit value <> " }")

xDataTheme :: Attr
xDataTheme =
  attr "x-data" "{ theme: (localStorage.getItem('theme') || 'system') }"

xShowFlag :: Flag -> Attr
xShowFlag f = attr "x-show" (flagName f)

xShowNotFlag :: Flag -> Attr
xShowNotFlag f = attr "x-show" ("!" <> flagName f)

xShowTheme :: ThemeMode -> Attr
xShowTheme mode = attr "x-show" ("theme === '" <> themeModeName mode <> "'")

ariaExpandedFlag :: Flag -> Attr
ariaExpandedFlag f = attr ":aria-expanded" (flagName f <> ".toString()")

xCloak :: Attr
xCloak = flag "x-cloak"

xSync :: Attr
xSync = flag "x-sync"

xTargetPush :: String -> Attr
xTargetPush = attr "x-target.push"

xAutofocus :: Attr
xAutofocus = flag "x-autofocus"

-- ============================================================================
-- Event handlers
-- ============================================================================

onClick :: Expr -> Attr
onClick e = attr "@click" (renderExpr e)

onClickOutside :: Expr -> Attr
onClickOutside e = attr "@click.outside" (renderExpr e)

onKeydownEscapeWindow :: Expr -> Attr
onKeydownEscapeWindow e = attr "@keydown.escape.window" (renderExpr e)

onMouseenter :: Expr -> Attr
onMouseenter e = attr "@mouseenter" (renderExpr e)

prefetchHover :: Attr
prefetchHover = onMouseenter prefetchExpr

spaLink :: Lang -> Route -> Array Attr -> Array Html -> Html
spaLink lang route extraAttrs children =
  el "a"
    ( [ href (routeUrl lang route)
      , xTargetPush contentTarget
      , prefetchHover
      ] <> extraAttrs
    )
    children

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
