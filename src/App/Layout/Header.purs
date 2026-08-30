-- | Site header — DaisyUI navbar + popover dropdown + drawer-button
-- | (research/daisyui-llms.txt Navbar, Dropdown popover, Drawer).
module App.Layout.Header where

import App.Alpine (ThemeMode(..), navLink, xDataTheme, xSetTheme, xSync)
import App.Html (Html, attr, class_, el, flag, href, id_, style_, text, type_)
import App.Layout.Icons (globeIcon, pohjolaLogo)
import Data.Content (siteInfo)
import Data.I18n (Lang(..), dict)
import Data.Route (Route(..), routeUrl)

render :: Lang -> Route -> Html
render lang currentRoute =
  let
    d = dict lang
    langLabel = case lang of
      En -> "EN"
      Fr -> "FR"
  in
    el "header"
      [ id_ "header"
      , class_ "navbar bg-base-100"
      , xSync
      ]
      [ el "div" [ class_ "navbar-start" ]
          [ el "label"
              [ attr "for" "nav-drawer"
              , class_ "btn btn-ghost lg:hidden"
              , attr "aria-label" d.common.menuLabel
              ]
              [ text "☰" ]
          , navLink { lang, current: currentRoute, target: Home }
              [ class_ "btn btn-ghost" ]
              [ pohjolaLogo
              , text siteInfo.title
              ]
          ]
      , el "div" [ class_ "navbar-center hidden lg:flex" ]
          [ el "ul" [ class_ "menu menu-horizontal" ]
              [ el "li" [] [ navLink { lang, current: currentRoute, target: About } [] [ text d.nav.about ] ]
              , el "li" [] [ navLink { lang, current: currentRoute, target: Contact } [] [ text d.nav.contact ] ]
              , el "li" [] [ navLink { lang, current: currentRoute, target: PostList } [] [ text d.nav.posts ] ]
              ]
          ]
      , el "div" [ class_ "navbar-end" ]
          [ langMenu lang currentRoute d.common.langToggleLabel langLabel
          , themeMenu lang
          ]
      ]

langMenu :: Lang -> Route -> String -> String -> Html
langMenu _lang currentRoute aria currentLangLabel =
  el "div" []
    [ el "button"
        [ type_ "button"
        , attr "popovertarget" "header-lang-menu"
        , style_ "anchor-name:--header-lang"
        , class_ "btn btn-ghost"
        , attr "aria-label" aria
        ]
        [ globeIcon, text currentLangLabel ]
    , el "ul"
        [ class_ "dropdown menu"
        , flag "popover"
        , id_ "header-lang-menu"
        , style_ "position-anchor:--header-lang"
        ]
        [ el "li" [] [ el "a" [ href (routeUrl En currentRoute) ] [ text "English" ] ]
        , el "li" [] [ el "a" [ href (routeUrl Fr currentRoute) ] [ text "Français" ] ]
        ]
    ]

themeMenu :: Lang -> Html
themeMenu lang =
  let
    c = (dict lang).common
  in
    el "div" [ xDataTheme ]
      [ el "button"
          [ type_ "button"
          , attr "popovertarget" "header-theme-menu"
          , style_ "anchor-name:--header-theme"
          , class_ "btn btn-ghost"
          , attr "aria-label" c.themeLabel
          ]
          [ text c.themeLabel ]
      , el "ul"
          [ class_ "dropdown menu"
          , flag "popover"
          , id_ "header-theme-menu"
          , style_ "position-anchor:--header-theme"
          ]
          [ el "li" [] [ el "button" [ type_ "button", xSetTheme ThemeLight ] [ text c.themeLight ] ]
          , el "li" [] [ el "button" [ type_ "button", xSetTheme ThemeDark ] [ text c.themeDark ] ]
          , el "li" [] [ el "button" [ type_ "button", xSetTheme ThemeSystem ] [ text c.themeSystem ] ]
          ]
      ]
