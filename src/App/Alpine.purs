-- | Alpine.js integration — the single seam between server-rendered HTML and
-- | browser interactivity.
module App.Alpine
  ( contentTarget
  , alpineRequestHeader
  , spaLink
  , navLink
  , NavChrome(..)
  , navLinkClasses
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
  , xDataThemeWithFlag
  , xShowFlag
  , xShowNotFlag
  , xShowTheme
  , xSetTheme
  , xSetThemeAndClose
  , setFlag
  , toggleFlag
  , ariaExpandedFlag
  , ariaSelectedFlag
  , ariaSelectedNotFlag
  , classWhenFlag
  , themeToggle
  , siteDrawerId
  , closeSiteDrawer
  , classWhenTheme
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
import App.Theme as Theme
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
  | ThemeMenuOpen
  | ModalOpen
  | ToastVisible
  | AccordionOpen
  | TabActive

derive instance eqFlag :: Eq Flag

instance showFlag :: Show Flag where
  show = case _ of
    MenuOpen -> "MenuOpen"
    LangMenuOpen -> "LangMenuOpen"
    ThemeMenuOpen -> "ThemeMenuOpen"
    ModalOpen -> "ModalOpen"
    ToastVisible -> "ToastVisible"
    AccordionOpen -> "AccordionOpen"
    TabActive -> "TabActive"

flagName :: Flag -> String
flagName = case _ of
  MenuOpen -> "menuOpen"
  LangMenuOpen -> "open"
  ThemeMenuOpen -> "themeOpen"
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

siteDrawerId :: String
siteDrawerId = "site-drawer"

closeSiteDrawer :: Expr
closeSiteDrawer =
  Expr ("document.getElementById('" <> siteDrawerId <> "').checked = false")

applyThemeJs :: String
applyThemeJs =
  "var r=document.documentElement;"
    <> "if(theme==='light')r.setAttribute('data-theme','"
    <> Theme.themeLightName
    <> "');"
    <> "else if(theme==='dark')r.setAttribute('data-theme','"
    <> Theme.themeDarkName
    <> "');"
    <> "else r.removeAttribute('data-theme')"

-- | Binary light/dark toggle via DaisyUI data-theme.
themeToggle :: Expr
themeToggle = Expr
  ( "var r=document.documentElement,d=r.getAttribute('data-theme')==='"
      <> Theme.themeDarkName
      <> "';"
      <> "theme=d?'light':'dark';"
      <> "localStorage.setItem('"
      <> Theme.themeStorageKey
      <> "',theme);"
      <> applyThemeJs
  )

-- | Set explicit theme preference (light, dark, or system) via data-theme.
setTheme :: ThemeMode -> Expr
setTheme = case _ of
  ThemeLight ->
    Expr
      ( "theme='light';localStorage.setItem('"
          <> Theme.themeStorageKey
          <> "','light');document.documentElement.setAttribute('data-theme','"
          <> Theme.themeLightName
          <> "')"
      )
  ThemeDark ->
    Expr
      ( "theme='dark';localStorage.setItem('"
          <> Theme.themeStorageKey
          <> "','dark');document.documentElement.setAttribute('data-theme','"
          <> Theme.themeDarkName
          <> "')"
      )
  ThemeSystem ->
    Expr
      ( "theme='system';localStorage.setItem('"
          <> Theme.themeStorageKey
          <> "','system');document.documentElement.removeAttribute('data-theme')"
      )

-- | Cycle theme through system -> light -> dark -> system.
cycleTheme :: Expr
cycleTheme = Expr
  ( "theme=(theme==='system'?'light':theme==='light'?'dark':'system');"
      <> "localStorage.setItem('"
      <> Theme.themeStorageKey
      <> "',theme);"
      <> applyThemeJs
  )

-- ============================================================================
-- Attribute constructors
-- ============================================================================

xDataFlag :: Flag -> Boolean -> Attr
xDataFlag f value =
  attr "x-data" ("{ " <> flagName f <> ": " <> boolLit value <> " }")

xDataTheme :: Attr
xDataTheme =
  attr "x-data"
    ( "{ theme: (localStorage.getItem('"
        <> Theme.themeStorageKey
        <> "') || 'system') }"
    )

xDataThemeWithFlag :: Flag -> Boolean -> Attr
xDataThemeWithFlag f b =
  attr "x-data"
    ( "{ theme: (localStorage.getItem('"
        <> Theme.themeStorageKey
        <> "') || 'system'), "
        <> flagName f
        <> ": "
        <> boolLit b
        <> " }"
    )

xShowFlag :: Flag -> Attr
xShowFlag f = attr "x-show" (flagName f)

xShowNotFlag :: Flag -> Attr
xShowNotFlag f = attr "x-show" ("!" <> flagName f)

xShowTheme :: ThemeMode -> Attr
xShowTheme mode = attr "x-show" ("theme === '" <> themeModeName mode <> "'")

xSetTheme :: ThemeMode -> Attr
xSetTheme mode = onClick (setTheme mode)

xSetThemeAndClose :: ThemeMode -> Flag -> Attr
xSetThemeAndClose mode f = onClick (setTheme mode <> setFlag f false)

ariaExpandedFlag :: Flag -> Attr
ariaExpandedFlag f = attr ":aria-expanded" (flagName f <> ".toString()")

ariaSelectedFlag :: Flag -> Attr
ariaSelectedFlag f = attr ":aria-selected" (flagName f <> ".toString()")

ariaSelectedNotFlag :: Flag -> Attr
ariaSelectedNotFlag f = attr ":aria-selected" ("(!" <> flagName f <> ").toString()")

classWhenFlag :: String -> Flag -> Attr
classWhenFlag className f =
  attr ":class" ("{ '" <> className <> "': " <> flagName f <> " }")

classWhenTheme :: String -> ThemeMode -> Attr
classWhenTheme className mode =
  attr ":class" ("{ '" <> className <> "': theme === '" <> themeModeName mode <> "' }")

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

prefetchExpr :: Expr
prefetchExpr = Expr
  ("fetch($el.href, {headers: {'" <> alpineRequestHeader <> "': 'true'}})")

spaLink :: Lang -> Route -> Array Attr -> Array Html -> Html
spaLink lang route extraAttrs children =
  el "a"
    ( [ href (routeUrl lang route)
      , xTargetPush contentTarget
      , prefetchHover
      ] <> extraAttrs
    )
    children

-- | Where a route-aware nav link is rendered in site chrome.
-- | Active DaisyUI modifiers are centralized here so shell edits cannot forget them.
data NavChrome = NavDesktop | NavMobile | NavFooter

navLinkClasses :: NavChrome -> Boolean -> String
navLinkClasses NavDesktop isActive =
  "btn btn-ghost btn-sm"
    <>
      if isActive then
        " btn-active"

      else
        ""

navLinkClasses NavMobile isActive =
  "btn btn-ghost justify-start"
    <>
      if isActive then
        " menu-active"

      else
        ""

navLinkClasses NavFooter _ = "link link-hover"

navLink :: { lang :: Lang, current :: Route, target :: Route } -> Array Attr -> Array Html -> Html
navLink { lang, current, target } extraAttrs children =
  el "a"
    ( [ href (routeUrl lang target)
      , xTargetPush contentTarget
      ]
        <> (if target == current then [ attr "aria-current" "page" ] else [])
        <> (if target == current then [] else [ prefetchHover ])
        <> extraAttrs
    )
    children
