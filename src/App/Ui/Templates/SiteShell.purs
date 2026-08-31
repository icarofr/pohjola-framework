-- | Site chrome — DaisyUI drawer, navbar, theme dropdown, and footer.
module App.Ui.Templates.SiteShell
  ( ShellLabels
  , sitePage
  , shellLabels
  ) where

import Prelude

import App.Alpine
  ( Flag(..)
  , NavChrome(..)
  , ThemeMode(..)
  , ariaExpandedFlag
  , closeSiteDrawer
  , classWhenFlag
  , classWhenTheme
  , contentTarget
  , navLink
  , navLinkClasses
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
  , text
  , type_
  )
import App.Ui.Container as Container
import App.Ui.Templates.Contract as Contract
import Data.I18n (Lang(..), dict)
import Data.Route (Route(..), routeTitle, routeUrl)

type ShellLabels =
  { siteTitle :: String
  , menuLabel :: String
  , aboutLabel :: String
  , contactLabel :: String
  , postsLabel :: String
  , homeLabel :: String
  , langEn :: String
  , langFr :: String
  , langToggleLabel :: String
  , themeLight :: String
  , themeDark :: String
  , themeSystem :: String
  , themeLabel :: String
  , copyright :: String
  }

shellLabels :: Lang -> ShellLabels
shellLabels lang =
  let
    d = dict lang
  in
    { siteTitle: d.common.siteTitle
    , menuLabel: d.common.menuLabel
    , aboutLabel: d.nav.about
    , contactLabel: d.nav.contact
    , postsLabel: d.nav.posts
    , homeLabel: homeLabelText lang
    , langEn: "English"
    , langFr: "Français"
    , langToggleLabel: d.common.langToggleLabel
    , themeLight: d.common.themeLight
    , themeDark: d.common.themeDark
    , themeSystem: d.common.themeSystem
    , themeLabel: d.common.themeLabel
    , copyright: d.footer.copyright
    }

homeLabelText :: Lang -> String
homeLabelText En = "Home"
homeLabelText Fr = "Accueil"

sitePage :: Lang -> Route -> ShellLabels -> Html -> Html
sitePage lang route labels content =
  el "div"
    [ class_ "drawer drawer-end min-h-full bg-base-100 text-base-content"
    , id_ contentTarget
    , attr "data-page-title" (routeTitle lang route)
    , xDataThemeWithFlag ThemeMenuOpen false
    , onKeydownEscapeWindow closeSiteDrawer
    ]
    [ el "input"
        [ type_ "checkbox"
        , class_ "drawer-toggle"
        , id_ siteDrawerId
        ]
        []
    , el "div" [ class_ "drawer-content flex min-h-full flex-col" ]
        [ renderHeader lang route labels
        , el "main" [ class_ "flex-1" ] [ content ]
        , renderFooter lang route labels
        ]
    , renderDrawerSide lang route labels
    ]

renderHeader :: Lang -> Route -> ShellLabels -> Html
renderHeader lang route labels =
  el "header"
    [ class_ "sticky top-0 z-50 border-b border-base-200 bg-base-100"
    , attr Contract.marker Contract.siteHeader
    ]
    [ Container.container "max-w-6xl" "px-4 sm:px-6"
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
                , desktopNavLink lang route PostList labels.postsLabel
                , desktopNavLink lang route Contact labels.contactLabel
                ]
            , el "div" [ class_ "navbar-end hidden gap-2 md:flex" ]
                [ renderThemeDropdown labels
                , el "div" [ class_ "join join-horizontal" ]
                    [ renderLangJoin En lang route labels.langEn
                    , renderLangJoin Fr lang route labels.langFr
                    ]
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
        , ariaLabel "Close sidebar"
        ]
        []
    , el "div"
        [ class_ "flex min-h-full w-80 flex-col bg-base-200 p-4 text-base-content" ]
        [ el "div" [ class_ "flex items-center justify-between" ]
            [ el "span" [ class_ "text-lg font-semibold" ] [ text labels.siteTitle ]
            , el "label"
                [ for_ siteDrawerId
                , class_ "btn btn-ghost btn-sm"
                , ariaLabel "Close menu"
                ]
                [ text "Close" ]
            ]
        , el "nav" [ class_ "menu mt-6 w-full rounded-box bg-base-100 p-2" ]
            [ mobileNavLink lang route Home labels.homeLabel
            , mobileNavLink lang route About labels.aboutLabel
            , mobileNavLink lang route PostList labels.postsLabel
            , mobileNavLink lang route Contact labels.contactLabel
            , el "li" [ class_ "menu-title mt-4" ] [ text labels.themeLabel ]
            , themeMenuItem false ThemeLight labels.themeLight
            , themeMenuItem false ThemeDark labels.themeDark
            , themeMenuItem false ThemeSystem labels.themeSystem
            , el "li" [ class_ "menu-title mt-4" ] [ text labels.langToggleLabel ]
            , el "li" []
                [ el "div" [ class_ "join join-vertical w-full" ]
                    [ renderLangJoin En lang route labels.langEn
                    , renderLangJoin Fr lang route labels.langFr
                    ]
                ]
            ]
        ]
    ]

desktopNavLink :: Lang -> Route -> Route -> String -> Html
desktopNavLink lang current target label =
  navLink { lang, current, target }
    [ class_ (navLinkClasses NavDesktop (target == current)) ]
    [ text label ]

renderLangJoin :: Lang -> Lang -> Route -> String -> Html
renderLangJoin targetLang currentLang route label =
  el "a"
    [ href (routeUrl targetLang route)
    , class_
        ( "join-item btn btn-sm"
            <>
              if targetLang == currentLang then
                " btn-active"

              else
                ""
        )
    ]
    [ text label ]

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
        [ themeMenuItem true ThemeLight labels.themeLight
        , themeMenuItem true ThemeDark labels.themeDark
        , themeMenuItem true ThemeSystem labels.themeSystem
        ]
    ]

themeMenuItem :: Boolean -> ThemeMode -> String -> Html
themeMenuItem closeMenu mode label =
  el "li" []
    [ el "button"
        ( [ class_ "btn btn-ghost btn-sm w-full justify-start"
          , classWhenTheme "btn-active" mode
          , attrTypeButton
          ]
            <>
              if closeMenu then
                [ xSetThemeAndClose mode ThemeMenuOpen ]

              else
                [ xSetTheme mode ]
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
    [ class_ "footer footer-center border-t border-base-200 bg-base-100 p-10 text-base-content sm:footer-horizontal"
    , attr Contract.marker Contract.siteFooter
    ]
    [ el "aside" []
        [ el "p" [ class_ "font-semibold" ] [ text labels.siteTitle ]
        , el "p" [ class_ "text-sm opacity-70" ] [ text labels.copyright ]
        ]
    , el "nav" [ class_ "grid grid-flow-col gap-4 text-sm opacity-70" ]
        [ footerLink lang route Home labels.homeLabel
        , footerLink lang route About labels.aboutLabel
        , footerLink lang route PostList labels.postsLabel
        , footerLink lang route Contact labels.contactLabel
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
