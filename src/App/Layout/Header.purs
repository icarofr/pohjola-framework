-- | Site header navigation — DaisyUI navbar with Theme Toggle and Language Dropdown
module App.Layout.Header where

import Prelude

import App.Alpine (Flag(..), ThemeMode(..), ariaExpandedFlag, cycleTheme, navLink, onClick, toggleFlag, xCloak, xDataFlag, xDataTheme, xShowFlag, xShowTheme)
import App.Html (Html, attr, class_, el, href, text)
import App.Layout.Icons (pohjolaLogo)
import Data.Content (siteInfo)
import Data.I18n (Dictionary, Lang(..), dict)
import Data.Route (Route(..), routeUrl)

render :: Lang -> Route -> Html
render lang currentRoute =
  let
    d = dict lang
    currentLangLabel = case lang of
      En -> "EN"
      Fr -> "FR"
  in
    el "header"
      [ class_ "sticky top-0 z-50 bg-base-100/90 backdrop-blur-md border-b border-base-300"
      , xDataFlag MenuOpen false
      ]
      [ el "div" [ class_ "navbar max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 justify-between" ]
          [ -- Navbar Start: Logo + Title
            el "div" [ class_ "navbar-start w-auto flex items-center gap-3" ]
              [ navLink { lang, current: currentRoute, target: Home }
                  [ class_ "flex items-center gap-2.5 font-bold text-base tracking-tight text-base-content hover:opacity-80 transition-opacity" ]
                  [ el "div" [ class_ "size-7 rounded-md bg-primary flex items-center justify-center text-primary-content font-mono font-bold text-xs" ]
                      [ pohjolaLogo ]
                  , el "span" [ class_ "font-mono font-bold uppercase tracking-wider text-sm" ]
                      [ text siteInfo.title ]
                  ]
              ]

          -- Navbar Center: Desktop Nav
          , el "div" [ class_ "navbar-center hidden md:flex items-center space-x-1" ]
              [ renderNavItem lang currentRoute About d.nav.about
              , renderNavItem lang currentRoute Contact d.nav.contact
              , renderNavItem lang currentRoute PostList d.nav.posts
              ]

          -- Navbar End: Theme toggle + Language Dropdown + Mobile menu button
          , el "div" [ class_ "navbar-end w-auto flex items-center gap-2" ]
              [ -- Theme toggle button
                el "button"
                  [ class_ "btn btn-ghost btn-sm btn-square text-base-content"
                  , onClick cycleTheme
                  , xDataTheme
                  , attr "aria-label" "Toggle color theme (Light / Dark / System)"
                  ]
                  [ -- Sun icon for Light
                    el "svg" [ class_ "size-4", xShowTheme ThemeLight, attr "fill" "none", attr "viewBox" "0 0 24 24", attr "stroke-width" "2", attr "stroke" "currentColor" ]
                      [ el "path" [ attr "stroke-linecap" "round", attr "stroke-linejoin" "round", attr "d" "M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" ] [] ]
                  -- Moon icon for Dark
                  , el "svg" [ class_ "size-4", xShowTheme ThemeDark, attr "fill" "none", attr "viewBox" "0 0 24 24", attr "stroke-width" "2", attr "stroke" "currentColor" ]
                      [ el "path" [ attr "stroke-linecap" "round", attr "stroke-linejoin" "round", attr "d" "M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" ] [] ]
                  -- Monitor icon for System
                  , el "svg" [ class_ "size-4", xShowTheme ThemeSystem, attr "fill" "none", attr "viewBox" "0 0 24 24", attr "stroke-width" "2", attr "stroke" "currentColor" ]
                      [ el "path" [ attr "stroke-linecap" "round", attr "stroke-linejoin" "round", attr "d" "M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" ] [] ]
                  ]

              -- Language dropdown (DaisyUI dropdown)
              , el "div" [ class_ "dropdown dropdown-end" ]
                  [ el "div"
                      [ attr "tabindex" "0"
                      , attr "role" "button"
                      , class_ "btn btn-ghost btn-sm text-xs font-mono flex items-center gap-1 text-base-content"
                      , attr "aria-label" "Select language"
                      ]
                      [ el "span" [] [ text currentLangLabel ]
                      , el "svg" [ class_ "size-3 opacity-60", attr "fill" "none", attr "viewBox" "0 0 24 24", attr "stroke-width" "2.5", attr "stroke" "currentColor" ]
                          [ el "path" [ attr "stroke-linecap" "round", attr "stroke-linejoin" "round", attr "d" "M19.5 8.25l-7.5 7.5-7.5-7.5" ] [] ]
                      ]
                  , el "ul"
                      [ attr "tabindex" "0"
                      , class_ "dropdown-content menu bg-base-100 rounded-box z-50 w-32 p-1.5 shadow-lg border border-base-200 text-xs font-mono mt-1"
                      ]
                      [ el "li" []
                          [ el "a"
                              [ href (routeUrl En currentRoute)
                              , class_ (if lang == En then "active font-bold" else "")
                              ]
                              [ text "English (EN)" ]
                          ]
                      , el "li" []
                          [ el "a"
                              [ href (routeUrl Fr currentRoute)
                              , class_ (if lang == Fr then "active font-bold" else "")
                              ]
                              [ text "Français (FR)" ]
                          ]
                      ]
                  ]

              -- Mobile menu trigger
              , el "button"
                  [ class_ "btn btn-ghost btn-sm md:hidden"
                  , onClick (toggleFlag MenuOpen)
                  , ariaExpandedFlag MenuOpen
                  , attr "aria-label" "Toggle navigation menu"
                  ]
                  [ el "svg" [ class_ "size-5", attr "fill" "none", attr "viewBox" "0 0 24 24", attr "stroke-width" "2", attr "stroke" "currentColor" ]
                      [ el "path" [ attr "stroke-linecap" "round", attr "stroke-linejoin" "round", attr "d" "M4 6h16M4 12h16M4 18h16" ] [] ]
                  ]
              ]
          ]

      -- Mobile Dropdown Menu
      , el "div"
          [ class_ "md:hidden border-t border-base-300 bg-base-100 px-4 py-3 space-y-1"
          , xShowFlag MenuOpen
          , xCloak
          ]
          [ renderMobileNavItem lang currentRoute About d.nav.about
          , renderMobileNavItem lang currentRoute Contact d.nav.contact
          , renderMobileNavItem lang currentRoute PostList d.nav.posts
          , el "div" [ class_ "pt-2 mt-2 border-t border-base-200 flex items-center justify-between text-xs font-mono px-3" ]
              [ el "span" [ class_ "text-base-content/60" ] [ text "Language" ]
              , el "div" [ class_ "flex gap-2" ]
                  [ el "a" [ href (routeUrl En currentRoute), class_ (if lang == En then "font-bold text-primary" else "text-base-content/70") ] [ text "EN" ]
                  , el "span" [ class_ "text-base-content/40" ] [ text "|" ]
                  , el "a" [ href (routeUrl Fr currentRoute), class_ (if lang == Fr then "font-bold text-primary" else "text-base-content/70") ] [ text "FR" ]
                  ]
              ]
          ]
      ]

renderNavItem :: Lang -> Route -> Route -> String -> Html
renderNavItem lang current target label =
  let
    isActive = isCurrentRoute current target
    activeClass = if isActive then "btn-active font-bold text-primary" else ""
  in
    navLink { lang, current, target }
      [ class_ ("btn btn-ghost btn-sm text-xs font-semibold " <> activeClass) ]
      [ text label ]

renderMobileNavItem :: Lang -> Route -> Route -> String -> Html
renderMobileNavItem lang current target label =
  let
    isActive = isCurrentRoute current target
    activeClass = if isActive then "bg-base-200 font-bold text-primary" else "text-base-content"
  in
    navLink { lang, current, target }
      [ class_ ("block px-3 py-2 rounded-md text-sm font-medium hover:bg-base-200 transition-colors " <> activeClass) ]
      [ text label ]

isCurrentRoute :: Route -> Route -> Boolean
isCurrentRoute current target =
  case current, target of
    Home, Home -> true
    About, About -> true
    Contact, Contact -> true
    PostList, PostList -> true
    PostDetail _, PostList -> true
    _, _ -> false
