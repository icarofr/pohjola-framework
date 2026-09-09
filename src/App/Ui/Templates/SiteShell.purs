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
  , NavChrome(..)
  , ThemeMode(..)
  , ariaExpandedFlag
  , classWhenFlag
  , classWhenTheme
  , closeSiteDrawer
  , contentTarget
  , dataPageLangAttr
  , dataPageTitleAttr
  , dropdownItemClass
  , dropdownItemClasses
  , dropdownPanelClass
  , dropdownTriggerClass
  , langLink
  , navLink
  , navLinkClasses
  , onClick
  , onClickOutside
  , onKeydownEscapeWindow
  , setFlag
  , siteDrawerId
  , toggleFlag
  , xDataSiteChrome
  , xSetTheme
  , xSetThemeAndClose
  , xShowFlag
  , xShowTheme
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
  , href
  , id_
  , rel_
  , target_
  , text
  , type_
  )
import App.Ui.Alert (AlertVariant(..), alert)
import App.Ui.Container as Container
import App.Ui.Templates.Contract as Contract
import Data.Content (bookingUrl)
import Data.I18n (Lang(..), dict, langTag)
import Data.Maybe (Maybe(..), maybe)
import Data.Route (Route(..), routeTitle)
import Data.String.Common (toUpper)

type ShellLabels =
  { siteTitle :: String
  , menuLabel :: String
  , homeLabel :: String
  , langEn :: String
  , langFr :: String
  , langPt :: String
  , langToggleLabel :: String
  , themeLight :: String
  , themeDark :: String
  , themeSystem :: String
  , themeLabel :: String
  , copyright :: String
  , closeSidebarLabel :: String
  , closeMenuLabel :: String
  , closeLabel :: String
  , aboutLabel :: String
  , guaranteesLabel :: String
  , docsLabel :: String
  , githubLabel :: String
  }

shellLabels :: Lang -> ShellLabels
shellLabels lang =
  let
    d = dict lang
  in
    { siteTitle: d.common.siteTitle
    , menuLabel: d.common.menuLabel
    , homeLabel: d.nav.home
    , langEn: "English"
    , langFr: "Français"
    , langPt: "Português"
    , langToggleLabel: d.common.langToggleLabel
    , themeLight: d.common.themeLight
    , themeDark: d.common.themeDark
    , themeSystem: d.common.themeSystem
    , themeLabel: d.common.themeLabel
    , copyright: d.footer.copyright
    , closeSidebarLabel: d.common.closeSidebarLabel
    , closeMenuLabel: d.common.closeMenuLabel
    , closeLabel: d.common.closeLabel
    , aboutLabel: d.nav.about
    , guaranteesLabel: d.nav.guarantees
    , docsLabel: d.nav.docs
    , githubLabel: d.footer.github
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

sitePage :: Lang -> Route -> ShellLabels -> Maybe FormStatus -> Html -> Html
sitePage lang route labels status content =
  sitePageTitled lang route (routeTitle lang route) labels status content

sitePageTitled :: Lang -> Route -> String -> ShellLabels -> Maybe FormStatus -> Html -> Html
sitePageTitled lang route title labels status content =
  el "div"
    ( [ class_ "drawer drawer-end min-h-dvh bg-base-100 text-base-content"
      , id_ contentTarget
      , attr dataPageTitleAttr title
      , attr dataPageLangAttr (langTag lang)
      ]
        <>
          [ xDataSiteChrome false
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
        [ renderHeader lang route labels
        , maybeStatusBanner lang status
        , el "main" [ class_ "flex-1" ] [ content ]
        , renderFooter lang route labels
        ]
    , renderDrawerSide lang route labels
    ]

siteErrorPage :: Lang -> Int -> Html
siteErrorPage lang statusCode =
  let
    labels = shellLabels lang
    title = show statusCode <> " - " <> labels.siteTitle
    body =
      el "div" [ class_ "mx-auto max-w-3xl px-6 py-24 text-center" ]
        [ el "h1" [ class_ "text-5xl font-semibold tracking-tight" ] [ text (show statusCode) ]
        , el "p" [ class_ "mt-6 text-lg opacity-70" ] [ text (errorMessage lang statusCode) ]
        ]
  in
    -- Reuse the drawer wrapper so Alpine replaceWith and TitleSync keep working.
    -- Home stands in for the current route: an error page has none of its
    -- own, and Home is guaranteed to exist (it's the one route every build
    -- of this framework always has).
    sitePageTitled lang Home title labels Nothing body

errorMessage :: Lang -> Int -> String
errorMessage lang status =
  let
    d = dict lang
  in
    if status == 404 then d.common.error404 else d.common.error500

renderHeader :: Lang -> Route -> ShellLabels -> Html
renderHeader lang route labels =
  el "header"
    [ class_ "sticky top-0 z-50 border-b border-base-200 bg-base-100"
    , attr Contract.marker Contract.siteHeader
    ]
    [ Container.container Container.ContainerW6xl "px-4 sm:px-6"
        [ el "div" [ class_ "navbar min-h-16 px-0" ]
            [ el "div" [ class_ "navbar-start" ]
                [ navLink { lang, current: route, target: Home }
                    [ class_ "btn btn-ghost text-lg font-semibold" ]
                    [ text labels.siteTitle ]
                ]
            , el "nav"
                [ class_ "navbar-center hidden gap-1 md:flex"
                , ariaLabel (dict lang).common.navAriaLabel
                ]
                [ desktopNavLink lang route Home labels.homeLabel
                , desktopNavLink lang route About labels.aboutLabel
                , desktopNavLink lang route Guarantees labels.guaranteesLabel
                , desktopNavLink lang route Docs labels.docsLabel
                ]
            , el "div" [ class_ "navbar-end hidden gap-1 md:flex" ]
                [ githubLink labels
                , renderThemeDropdown labels
                , renderLangDropdown lang route labels
                ]
            , el "div" [ class_ "navbar-end md:hidden" ]
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

renderDrawerSide :: Lang -> Route -> ShellLabels -> Html
renderDrawerSide lang route labels =
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
            [ mobileNavLink lang route Home labels.homeLabel
            , mobileNavLink lang route About labels.aboutLabel
            , mobileNavLink lang route Guarantees labels.guaranteesLabel
            , mobileNavLink lang route Docs labels.docsLabel
            , el "li" [] [ githubLink labels ]
            , el "li" [ class_ "menu-title mt-4" ] [ text labels.themeLabel ]
            , themeMenuItem DrawerMenu ThemeLight labels.themeLight
            , themeMenuItem DrawerMenu ThemeDark labels.themeDark
            , themeMenuItem DrawerMenu ThemeSystem labels.themeSystem
            , el "li" [ class_ "menu-title mt-4" ] [ text labels.langToggleLabel ]
            , langMenuItem DrawerMenu En lang route labels.langEn
            , langMenuItem DrawerMenu Fr lang route labels.langFr
            , langMenuItem DrawerMenu Pt lang route labels.langPt
            ]
        ]
    ]

desktopNavLink :: Lang -> Route -> Route -> String -> Html
desktopNavLink lang current target label =
  navLink { lang, current, target }
    [ class_ (navLinkClasses NavDesktop (target == current)) ]
    [ text label ]

-- | Same URL as Home's hero CTA (`Data.Content.bookingUrl`) — the one
-- | GitHub link every page shares, not a per-page decision. Icon-only, same
-- | as the theme toggle beside it — a visible "Source Code" button was
-- | most of why the desktop navbar felt crowded.
githubLink :: ShellLabels -> Html
githubLink labels =
  el "a"
    [ href bookingUrl
    , target_ "_blank"
    , rel_ "noopener noreferrer"
    , class_ "btn btn-ghost btn-sm"
    , ariaLabel labels.githubLabel
    ]
    [ githubIcon ]

renderLangDropdown :: Lang -> Route -> ShellLabels -> Html
renderLangDropdown currentLang route labels =
  el "div"
    [ class_ "dropdown dropdown-end"
    , classWhenFlag "dropdown-open" LangMenuOpen
    , onClickOutside (setFlag LangMenuOpen false)
    , onKeydownEscapeWindow (setFlag LangMenuOpen false)
    ]
    [ el "button"
        [ attrTypeButton
        , class_ (dropdownTriggerClass <> " gap-1")
        , ariaLabel labels.langToggleLabel
        , attr "aria-haspopup" "menu"
        , ariaExpandedFlag LangMenuOpen
        , onClick (toggleFlag LangMenuOpen)
        ]
        [ globeIcon, text (toUpper (langTag currentLang)) ]
    , el "ul"
        [ xShowFlag LangMenuOpen
        , class_ dropdownPanelClass
        ]
        [ langMenuItem DropdownMenu En currentLang route labels.langEn
        , langMenuItem DropdownMenu Fr currentLang route labels.langFr
        , langMenuItem DropdownMenu Pt currentLang route labels.langPt
        ]
    ]

-- | Which surface a language menu item renders in — same DropdownMenu vs.
-- | DrawerMenu split as `themeMenuItem`: the desktop popover closes itself
-- | (LangMenuOpen) on selection, the drawer closes the whole drawer instead.
langMenuItem :: MenuContext -> Lang -> Lang -> Route -> String -> Html
langMenuItem context targetLang currentLang route label =
  el "li" []
    [ langLink { targetLang, currentLang, route }
        ( [ class_ (dropdownItemClasses (targetLang == currentLang)) ]
            <> case context of
              DrawerMenu -> [ onClick closeSiteDrawer ]
              DropdownMenu -> [ onClick (setFlag LangMenuOpen false) ]
        )
        [ text label ]
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
        , class_ dropdownTriggerClass
        , ariaLabel labels.themeLabel
        , attr "aria-haspopup" "menu"
        , ariaExpandedFlag ThemeMenuOpen
        , onClick (toggleFlag ThemeMenuOpen)
        ]
        [ sunIcon, moonIcon, systemIcon ]
    , el "ul"
        [ xShowFlag ThemeMenuOpen
        , class_ dropdownPanelClass
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
        ( [ class_ dropdownItemClass
          , classWhenTheme "btn-active" mode
          , attrTypeButton
          ]
            <> case context of
              DrawerMenu -> [ xSetTheme mode ]
              DropdownMenu -> [ xSetThemeAndClose mode ThemeMenuOpen ]
        )
        [ text label ]
    ]

mobileNavLink :: Lang -> Route -> Route -> String -> Html
mobileNavLink lang current target label =
  el "li" []
    [ navLink { lang, current, target }
        ( [ class_ (navLinkClasses NavMobile (target == current))
          , onClick closeSiteDrawer
          ]
        )
        [ text label ]
    ]

renderFooter :: Lang -> Route -> ShellLabels -> Html
renderFooter lang route labels =
  el "footer"
    [ class_ "footer footer-center border-t border-base-300 bg-base-200 p-10 text-base-content sm:footer-horizontal"
    , attr Contract.marker Contract.siteFooter
    ]
    [ el "aside" []
        [ el "p" [ class_ "font-semibold" ] [ text labels.siteTitle ]
        , el "p" [ class_ "text-sm opacity-70" ] [ text labels.copyright ]
        ]
    , el "nav" [ class_ "grid grid-flow-col gap-4 text-sm opacity-70" ]
        [ footerLink lang route Home labels.homeLabel
        , footerLink lang route About labels.aboutLabel
        , footerLink lang route Guarantees labels.guaranteesLabel
        , footerLink lang route Docs labels.docsLabel
        ]
    ]

footerLink :: Lang -> Route -> Route -> String -> Html
footerLink lang current target label =
  navLink { lang, current, target }
    [ class_ (navLinkClasses NavFooter (target == current)) ]
    [ text label ]

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

-- | Trigger icon reflects the *selected* preference, not the resolved
-- | color scheme — all three sit in the DOM and toggle via `xShowTheme`
-- | against the same `theme` x-data value `classWhenTheme` reads for the
-- | active menu item, so the icon and the checked entry always agree.
sunIcon :: Html
sunIcon =
  el "svg"
    [ attr "xmlns" "http://www.w3.org/2000/svg"
    , class_ "h-5 w-5"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke" "currentColor"
    , attr "stroke-width" "2"
    , attr "stroke-linecap" "round"
    , attr "stroke-linejoin" "round"
    , xShowTheme ThemeLight
    ]
    [ el "circle" [ attr "cx" "12", attr "cy" "12", attr "r" "5" ] []
    , el "path"
        [ attr "d"
            "M12 1v2M12 21v2M4.2 4.2l1.4 1.4M18.4 18.4l1.4 1.4M1 12h2M21 12h2M4.2 19.8l1.4-1.4M18.4 5.6l1.4-1.4"
        ]
        []
    ]

moonIcon :: Html
moonIcon =
  el "svg"
    [ attr "xmlns" "http://www.w3.org/2000/svg"
    , class_ "h-5 w-5"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke" "currentColor"
    , attr "stroke-width" "2"
    , attr "stroke-linecap" "round"
    , attr "stroke-linejoin" "round"
    , xShowTheme ThemeDark
    ]
    [ el "path"
        [ attr "d" "M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" ]
        []
    ]

systemIcon :: Html
systemIcon =
  el "svg"
    [ attr "xmlns" "http://www.w3.org/2000/svg"
    , class_ "h-5 w-5"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke" "currentColor"
    , attr "stroke-width" "2"
    , attr "stroke-linecap" "round"
    , attr "stroke-linejoin" "round"
    , xShowTheme ThemeSystem
    ]
    [ el "rect" [ attr "x" "3", attr "y" "4", attr "width" "18", attr "height" "13", attr "rx" "2" ] []
    , el "path" [ attr "d" "M8 21h8M12 17v4" ] []
    ]

globeIcon :: Html
globeIcon =
  el "svg"
    [ attr "xmlns" "http://www.w3.org/2000/svg"
    , class_ "h-4 w-4"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke" "currentColor"
    , attr "stroke-width" "2"
    , attr "stroke-linecap" "round"
    , attr "stroke-linejoin" "round"
    ]
    [ el "circle" [ attr "cx" "12", attr "cy" "12", attr "r" "9" ] []
    , el "path" [ attr "d" "M3 12h18M12 3c2.5 2.7 3.8 6 3.8 9s-1.3 6.3-3.8 9c-2.5-2.7-3.8-6-3.8-9s1.3-6.3 3.8-9z" ] []
    ]

githubIcon :: Html
githubIcon =
  el "svg"
    [ attr "xmlns" "http://www.w3.org/2000/svg"
    , class_ "h-5 w-5"
    , attr "viewBox" "0 0 24 24"
    , attr "fill" "currentColor"
    ]
    [ el "path"
        [ attr "d"
            "M12 .5C5.65.5.5 5.65.5 12c0 5.08 3.29 9.39 7.86 10.91.57.1.78-.25.78-.55 0-.27-.01-1.16-.02-2.11-3.2.7-3.87-1.36-3.87-1.36-.53-1.33-1.29-1.69-1.29-1.69-1.05-.72.08-.7.08-.7 1.17.08 1.78 1.2 1.78 1.2 1.03 1.77 2.71 1.26 3.37.96.1-.75.4-1.26.73-1.55-2.55-.29-5.24-1.28-5.24-5.69 0-1.26.45-2.29 1.19-3.09-.12-.29-.52-1.46.11-3.05 0 0 .97-.31 3.18 1.18a11 11 0 0 1 2.9-.39c.98 0 1.97.13 2.9.39 2.2-1.49 3.17-1.18 3.17-1.18.63 1.59.23 2.76.11 3.05.74.8 1.19 1.83 1.19 3.09 0 4.42-2.69 5.39-5.25 5.68.41.36.78 1.06.78 2.14 0 1.55-.01 2.79-.01 3.17 0 .3.2.66.79.55A10.52 10.52 0 0 0 23.5 12c0-6.35-5.15-11.5-11.5-11.5Z"
        ]
        []
    ]

attrTypeButton :: Attr
attrTypeButton = attr "type" "button"
