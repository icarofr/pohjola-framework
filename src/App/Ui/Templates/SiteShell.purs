-- | Site chrome — DaisyUI drawer, navbar, theme dropdown, and footer.
module App.Ui.Templates.SiteShell
  ( ShellLabels
  , sitePage
  , siteErrorPage
  , shellLabels
  ) where

import Prelude

import App.Alpine
  ( Flag(..)
  , ThemeMode(..)
  , ariaExpandedFlag
  , closeSiteDrawer
  , classWhenFlag
  , classWhenTheme
  , contentTarget
  , dataPageLangAttr
  , dataPageTitleAttr
  , onClick
  , onClickOutside
  , onKeydownEscapeWindow
  , setFlag
  , siteDrawerId
  , toggleFlag
  , xDataThemeWithFlag
  , xSetTheme
  , xSetThemeAndClose
  , xShowFlag
  )
import App.Form (FormStatus(..), formStatusQuery, statusText)
import App.Html
  ( Attr
  , Html
  , ariaLabel
  , attr
  , class_
  , el
  , for_
  , id_
  , text
  , type_
  )
import App.Ui.Alert (AlertVariant(..), alert)
import App.Ui.Container as Container
import App.Ui.Templates.Contract as Contract
import Data.I18n (Lang, dict, langTag)
import Data.Maybe (Maybe(..), maybe)
import Data.Route (Route, routeTitle)

-- | `aboutLabel`/`contactLabel`/`postsLabel`/`homeLabel`/`langEn`/`langFr`/
-- | `langPt` are gone for now along with the nav links and language switcher
-- | that used them — see the doc comments on `renderHeader`/`renderDrawerSide`
-- | (clean-sheet rebuild, .scratch/clean-sheet-homepage/). Return together.
type ShellLabels =
  { siteTitle :: String
  , menuLabel :: String
  , langToggleLabel :: String
  , themeLight :: String
  , themeDark :: String
  , themeSystem :: String
  , themeLabel :: String
  , copyright :: String
  , closeSidebarLabel :: String
  , closeMenuLabel :: String
  , closeLabel :: String
  }

shellLabels :: Lang -> ShellLabels
shellLabels lang =
  let
    d = dict lang
  in
    { siteTitle: d.common.siteTitle
    , menuLabel: d.common.menuLabel
    , langToggleLabel: d.common.langToggleLabel
    , themeLight: d.common.themeLight
    , themeDark: d.common.themeDark
    , themeSystem: d.common.themeSystem
    , themeLabel: d.common.themeLabel
    , copyright: d.footer.copyright
    , closeSidebarLabel: d.common.closeSidebarLabel
    , closeMenuLabel: d.common.closeMenuLabel
    , closeLabel: d.common.closeLabel
    }

maybeStatusBanner :: Lang -> Maybe FormStatus -> Html
maybeStatusBanner lang = maybe (text "") \status ->
  let
    variant = case status of
      FormSuccess -> AlertSuccess
      FormError -> AlertError
      FormSubscribed -> AlertSuccess
  in
    el "div" [ attr "data-form-status" (formStatusQuery status) ]
      [ alert variant (statusText lang status) ]

-- | `Route` is threaded through only for `routeTitle` here — nothing
-- | downstream of `sitePageTitled` currently needs a route value (see that
-- | function's doc). Kept in this signature for forward API compatibility;
-- | `sitePage` itself has no caller right now (clean-sheet rebuild, see
-- | .scratch/clean-sheet-homepage/ — every feature that called it is
-- | deleted), so this is unreachable, not exercised.
sitePage :: Lang -> Route -> ShellLabels -> Maybe FormStatus -> Html -> Html
sitePage lang route labels status content =
  sitePageTitled lang (routeTitle lang route) labels status content

-- | No `Route` parameter for now: every nav link this shell would highlight
-- | or build (site-title-as-home-link, the main nav, the language
-- | switcher, the footer links) needs a real destination route, and none
-- | exist mid-purge (clean-sheet rebuild, see
-- | .scratch/clean-sheet-homepage/) — unlike "which route is current",
-- | "what route to link to" has no absurd/wildcard escape. The chrome below
-- | renders only what doesn't need a destination (title text, theme
-- | switcher, drawer toggle). Nav links, the language switcher, and this
-- | parameter all return together once real routes exist (ticket 02).
sitePageTitled :: Lang -> String -> ShellLabels -> Maybe FormStatus -> Html -> Html
sitePageTitled lang title labels status content =
  el "div"
    ( [ class_ "drawer drawer-end min-h-full bg-base-100 text-base-content"
      , id_ contentTarget
      , attr dataPageTitleAttr title
      , attr dataPageLangAttr (langTag lang)
      ]
        <>
          [ xDataThemeWithFlag ThemeMenuOpen false
          , onKeydownEscapeWindow closeSiteDrawer
          ]
    )
    [ el "input"
        [ type_ "checkbox"
        , class_ "drawer-toggle"
        , id_ siteDrawerId
        ]
        []
    , el "div" [ class_ "drawer-content flex min-h-full flex-col" ]
        [ renderHeader lang labels
        , maybeStatusBanner lang status
        , el "main" [ class_ "flex-1" ] [ content ]
        , renderFooter lang labels
        ]
    , renderDrawerSide labels
    ]

siteErrorPage :: Lang -> Int -> Html
siteErrorPage lang statusCode =
  let
    labels = shellLabels lang
    title = show statusCode <> " — " <> labels.siteTitle
    body =
      el "div" [ class_ "mx-auto max-w-3xl px-6 py-24 text-center" ]
        [ el "h1" [ class_ "text-5xl font-semibold tracking-tight" ] [ text (show statusCode) ]
        , el "p" [ class_ "mt-6 text-lg opacity-70" ] [ text (errorMessage lang statusCode) ]
        ]
  in
    -- Reuse the drawer wrapper so Alpine replaceWith and TitleSync keep working.
    sitePageTitled lang title labels Nothing body

errorMessage :: Lang -> Int -> String
errorMessage lang status =
  let
    d = dict lang
  in
    if status == 404 then d.common.error404 else d.common.error500

-- | Nav links, the language switcher, and the site-title home link are all
-- | gone for now — every one of them needs a real destination route, and
-- | none exist (clean-sheet rebuild, see .scratch/clean-sheet-homepage/).
-- | What remains renders without a destination: plain title text, the theme
-- | switcher, and the mobile drawer toggle. Return together in ticket 02.
renderHeader :: Lang -> ShellLabels -> Html
renderHeader _ labels =
  el "header"
    [ class_ "sticky top-0 z-50 border-b border-base-200 bg-base-100"
    , attr Contract.marker Contract.siteHeader
    ]
    [ Container.container Container.ContainerW6xl "px-4 sm:px-6"
        [ el "div" [ class_ "navbar min-h-16 px-0" ]
            [ el "div" [ class_ "navbar-start" ]
                [ el "span" [ class_ "btn btn-ghost text-lg font-semibold no-animation" ]
                    [ text labels.siteTitle ]
                ]
            , el "div" [ class_ "navbar-end gap-2" ]
                [ renderThemeDropdown labels
                , el "div" [ class_ "md:hidden" ]
                    [ el "label"
                        [ for_ siteDrawerId
                        , class_ "btn btn-square btn-ghost drawer-button"
                        , ariaLabel labels.menuLabel
                        ]
                        [ hamburgerIcon ]
                    ]
                ]
            ]
        ]
    ]

renderDrawerSide :: ShellLabels -> Html
renderDrawerSide labels =
  el "div" [ class_ "drawer-side z-50 md:hidden" ]
    [ el "label"
        [ for_ siteDrawerId
        , class_ "drawer-overlay"
        , ariaLabel labels.closeSidebarLabel
        ]
        []
    , el "div"
        [ class_ "flex min-h-full w-80 flex-col bg-base-200 p-4 text-base-content" ]
        [ el "div" [ class_ "flex items-center justify-between" ]
            [ el "span" [ class_ "text-lg font-semibold" ] [ text labels.siteTitle ]
            , el "label"
                [ for_ siteDrawerId
                , class_ "btn btn-ghost btn-sm"
                , ariaLabel labels.closeMenuLabel
                ]
                [ text labels.closeLabel ]
            ]
        , el "nav" [ class_ "menu mt-6 w-full rounded-box bg-base-100 p-2" ]
            [ el "li" [ class_ "menu-title" ] [ text labels.themeLabel ]
            , themeMenuItem DrawerMenu ThemeLight labels.themeLight
            , themeMenuItem DrawerMenu ThemeDark labels.themeDark
            , themeMenuItem DrawerMenu ThemeSystem labels.themeSystem
            ]
        ]
    ]

renderThemeDropdown :: ShellLabels -> Html
renderThemeDropdown labels =
  el "div"
    [ class_ "dropdown dropdown-end"
    , classWhenFlag "dropdown-open" ThemeMenuOpen
    , onClickOutside (setFlag ThemeMenuOpen false)
    , onKeydownEscapeWindow (setFlag ThemeMenuOpen false)
    ]
    [ el "button"
        [ attrTypeButton
        , class_ "btn btn-ghost btn-sm"
        , ariaLabel labels.themeLabel
        , attr "aria-haspopup" "menu"
        , ariaExpandedFlag ThemeMenuOpen
        , onClick (toggleFlag ThemeMenuOpen)
        ]
        [ themeIcon ]
    , el "ul"
        [ xShowFlag ThemeMenuOpen
        , class_
            "menu menu-sm dropdown-content rounded-box z-50 mt-3 w-52 bg-base-100 p-2 shadow"
        ]
        [ themeMenuItem DropdownMenu ThemeLight labels.themeLight
        , themeMenuItem DropdownMenu ThemeDark labels.themeDark
        , themeMenuItem DropdownMenu ThemeSystem labels.themeSystem
        ]
    ]

-- | Which surface a theme menu item renders in — the desktop dropdown is a
-- | popover that needs to close itself (ThemeMenuOpen) on selection; the
-- | mobile drawer's theme buttons are flat list items with no popover flag
-- | of their own to close.
data MenuContext = DropdownMenu | DrawerMenu

themeMenuItem :: MenuContext -> ThemeMode -> String -> Html
themeMenuItem context mode label =
  el "li" []
    [ el "button"
        ( [ class_ "btn btn-ghost btn-sm w-full justify-start"
          , classWhenTheme "btn-active" mode
          , attrTypeButton
          ]
            <> case context of
              DrawerMenu -> [ xSetTheme mode ]
              DropdownMenu -> [ xSetThemeAndClose mode ThemeMenuOpen ]
        )
        [ text label ]
    ]

-- | Footer nav links need real destination routes, and none exist yet —
-- | same reasoning as `renderHeader`'s doc comment. Just the identity/
-- | copyright aside remains; the link row returns in ticket 02.
renderFooter :: Lang -> ShellLabels -> Html
renderFooter _ labels =
  el "footer"
    [ class_ "footer footer-center border-t border-base-200 bg-base-100 p-10 text-base-content sm:footer-horizontal"
    , attr Contract.marker Contract.siteFooter
    ]
    [ el "aside" []
        [ el "p" [ class_ "font-semibold" ] [ text labels.siteTitle ]
        , el "p" [ class_ "text-sm opacity-70" ] [ text labels.copyright ]
        ]
    ]

hamburgerIcon :: Html
hamburgerIcon =
  el "svg"
    [ attr "xmlns" "http://www.w3.org/2000/svg"
    , class_ "h-5 w-5"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke" "currentColor"
    ]
    [ el "path"
        [ attr "stroke-linecap" "round"
        , attr "stroke-linejoin" "round"
        , attr "stroke-width" "2"
        , attr "d" "M4 6h16M4 12h16M4 18h16"
        ]
        []
    ]

themeIcon :: Html
themeIcon =
  el "svg"
    [ attr "xmlns" "http://www.w3.org/2000/svg"
    , class_ "h-5 w-5"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke" "currentColor"
    , attr "stroke-width" "2"
    , attr "stroke-linecap" "round"
    , attr "stroke-linejoin" "round"
    ]
    [ el "circle" [ attr "cx" "12", attr "cy" "12", attr "r" "5" ] []
    , el "path"
        [ attr "d"
            "M12 1v2M12 21v2M4.2 4.2l1.4 1.4M18.4 18.4l1.4 1.4M1 12h2M21 12h2M4.2 19.8l1.4-1.4M18.4 5.6l1.4-1.4"
        ]
        []
    ]

attrTypeButton :: Attr
attrTypeButton = attr "type" "button"
