-- | Site header navigation — responsive DaisyUI navbar with desktop dropdowns & native mobile drawer
module App.Layout.Header where

import Prelude

import App.Alpine (Flag(..), ThemeMode(..), ariaExpandedFlag, navLink, onClick, onClickOutside, onKeydownEscapeWindow, setFlag, toggleFlag, xCloak, xDataFlag, xDataTheme, xDataThemeWithFlag, xSetTheme, xSetThemeAndClose, xShowFlag, xShowTheme, xSync)
import App.Html (Html, attr, class_, el, href, id_, text, type_)
import App.Layout.Icons (globeIcon, pohjolaLogo)
import Data.Content (siteInfo)
import Data.I18n (Lang(..), dict)
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
      [ id_ "header"
      , xSync
      , class_ "sticky top-0 z-50 bg-base-100/90 backdrop-blur-md border-b border-base-300"
      , xDataFlag MenuOpen false
      , onClickOutside (setFlag MenuOpen false)
      , onKeydownEscapeWindow (setFlag MenuOpen false)
      ]
      [ el "div" [ class_ "navbar max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 justify-between" ]
          [ -- Navbar Start: Brand Logo + Title
            el "div" [ class_ "navbar-start w-auto flex items-center gap-3" ]
              [ navLink { lang, current: currentRoute, target: Home }
                  [ class_ "flex items-center gap-2.5 font-bold text-base tracking-tight text-base-content hover:opacity-80 transition-opacity" ]
                  [ el "div" [ class_ "size-7 rounded-md bg-primary flex items-center justify-center text-primary-content font-mono font-bold text-xs" ]
                      [ pohjolaLogo ]
                  , el "span" [ class_ "font-mono font-bold uppercase tracking-wider text-sm" ]
                      [ text siteInfo.title ]
                  ]
              ]

          -- Navbar Center: Desktop Navigation Links (hidden on mobile)
          , el "div" [ class_ "navbar-center hidden md:flex items-center space-x-1" ]
              [ renderNavItem lang currentRoute About d.nav.about
              , renderNavItem lang currentRoute Contact d.nav.contact
              , renderNavItem lang currentRoute PostList d.nav.posts
              ]

          -- Navbar End: Desktop Dropdowns + Mobile Hamburger Trigger
          , el "div" [ class_ "navbar-end w-auto flex items-center gap-1.5" ]
              [ -- Desktop Language Dropdown (hidden on mobile)
                el "div"
                  [ class_ "dropdown dropdown-end hidden md:block"
                  , xDataFlag LangMenuOpen false
                  , onClickOutside (setFlag LangMenuOpen false)
                  , onKeydownEscapeWindow (setFlag LangMenuOpen false)
                  ]
                  [ el "button"
                      [ type_ "button"
                      , onClick (toggleFlag LangMenuOpen)
                      , class_ "btn btn-ghost btn-sm gap-1 px-2 text-xs font-mono font-medium text-base-content/80 hover:text-base-content"
                      , attr "aria-label" "Select language"
                      , ariaExpandedFlag LangMenuOpen
                      ]
                      [ globeIcon
                      , el "span" [ class_ "font-semibold" ] [ text currentLangLabel ]
                      , el "svg" [ class_ "size-2.5 opacity-50", attr "fill" "none", attr "viewBox" "0 0 24 24", attr "stroke-width" "2.5", attr "stroke" "currentColor" ]
                          [ el "path" [ attr "stroke-linecap" "round", attr "stroke-linejoin" "round", attr "d" "M19.5 8.25l-7.5 7.5-7.5-7.5" ] [] ]
                      ]
                  , el "ul"
                      [ xShowFlag LangMenuOpen
                      , xCloak
                      , class_ "dropdown-content menu menu-sm bg-base-100 rounded-box z-50 w-36 p-1 shadow-lg border border-base-200 text-xs mt-1 block"
                      ]
                      [ el "li" []
                          [ el "a"
                              [ href (routeUrl En currentRoute)
                              , onClick (setFlag LangMenuOpen false)
                              , class_ (if lang == En then "active font-bold" else "")
                              ]
                              [ text "English" ]
                          ]
                      , el "li" []
                          [ el "a"
                              [ href (routeUrl Fr currentRoute)
                              , onClick (setFlag LangMenuOpen false)
                              , class_ (if lang == Fr then "active font-bold" else "")
                              ]
                              [ text "Français" ]
                          ]
                      ]
                  ]

              -- Desktop Theme Controller Dropdown (hidden on mobile)
              , el "div"
                  [ class_ "dropdown dropdown-end hidden md:block"
                  , xDataThemeWithFlag ThemeMenuOpen false
                  , onClickOutside (setFlag ThemeMenuOpen false)
                  , onKeydownEscapeWindow (setFlag ThemeMenuOpen false)
                  ]
                  [ el "button"
                      [ type_ "button"
                      , onClick (toggleFlag ThemeMenuOpen)
                      , class_ "btn btn-ghost btn-sm btn-circle text-base-content/80 hover:text-base-content"
                      , attr "aria-label" (d.common.themeLabel <> " (Light / Dark / System)")
                      , ariaExpandedFlag ThemeMenuOpen
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
                  , el "ul"
                      [ xShowFlag ThemeMenuOpen
                      , xCloak
                      , class_ "dropdown-content menu menu-sm bg-base-100 rounded-box z-50 w-32 p-1 shadow-lg border border-base-200 text-xs font-mono mt-1 whitespace-nowrap block"
                      ]
                      [ el "li" []
                          [ el "button"
                              [ type_ "button"
                              , class_ "flex items-center gap-2"
                              , xSetThemeAndClose ThemeLight ThemeMenuOpen
                              ]
                              [ el "svg" [ class_ "size-3.5", attr "fill" "none", attr "viewBox" "0 0 24 24", attr "stroke-width" "2", attr "stroke" "currentColor" ]
                                  [ el "path" [ attr "stroke-linecap" "round", attr "stroke-linejoin" "round", attr "d" "M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" ] [] ]
                              , el "span" [] [ text d.common.themeLight ]
                              ]
                          ]
                      , el "li" []
                          [ el "button"
                              [ type_ "button"
                              , class_ "flex items-center gap-2"
                              , xSetThemeAndClose ThemeDark ThemeMenuOpen
                              ]
                              [ el "svg" [ class_ "size-3.5", attr "fill" "none", attr "viewBox" "0 0 24 24", attr "stroke-width" "2", attr "stroke" "currentColor" ]
                                  [ el "path" [ attr "stroke-linecap" "round", attr "stroke-linejoin" "round", attr "d" "M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" ] [] ]
                              , el "span" [] [ text d.common.themeDark ]
                              ]
                          ]
                      , el "li" []
                          [ el "button"
                              [ type_ "button"
                              , class_ "flex items-center gap-2"
                              , xSetThemeAndClose ThemeSystem ThemeMenuOpen
                              ]
                              [ el "svg" [ class_ "size-3.5", attr "fill" "none", attr "viewBox" "0 0 24 24", attr "stroke-width" "2", attr "stroke" "currentColor" ]
                                  [ el "path" [ attr "stroke-linecap" "round", attr "stroke-linejoin" "round", attr "d" "M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" ] [] ]
                              , el "span" [] [ text d.common.themeSystem ]
                              ]
                          ]
                      ]
                  ]

              -- Mobile Menu Hamburger Trigger (clean, isolated on mobile top bar)
              , el "button"
                  [ class_ "btn btn-ghost btn-sm btn-square md:hidden text-base-content/80 hover:text-base-content"
                  , onClick (toggleFlag MenuOpen)
                  , ariaExpandedFlag MenuOpen
                  , attr "aria-label" "Toggle navigation menu"
                  ]
                  [ el "svg" [ class_ "size-5", attr "fill" "none", attr "viewBox" "0 0 24 24", attr "stroke-width" "2", attr "stroke" "currentColor" ]
                      [ el "path" [ attr "stroke-linecap" "round", attr "stroke-linejoin" "round", attr "d" "M4 6h16M4 12h16M4 18h16" ] [] ]
                  ]
              ]
          ]

      -- Mobile Drawer (Clean, thumb-friendly navigation & utilities)
      , el "div"
          [ class_ "mobile-drawer md:hidden border-t border-base-300 bg-base-100 px-4 py-4 space-y-4"
          , xShowFlag MenuOpen
          , xCloak
          ]
          [ -- Primary Navigation Links (large touch targets)
            el "div" [ class_ "space-y-1" ]
              [ renderMobileNavItem lang currentRoute About d.nav.about
              , renderMobileNavItem lang currentRoute Contact d.nav.contact
              , renderMobileNavItem lang currentRoute PostList d.nav.posts
              ]

          -- Mobile Utility Footer: Language & Theme Thumb-Friendly Selectors
          , el "div"
              [ class_ "pt-4 border-t border-base-200 space-y-3.5"
              , xDataTheme
              ]
              [ -- Language Segmented Control
                el "div" [ class_ "space-y-1.5" ]
                  [ el "div" [ class_ "text-[11px] font-mono font-semibold uppercase tracking-wider text-base-content/60 px-1" ]
                      [ text "Language" ]
                  , el "div" [ class_ "grid grid-cols-2 gap-2" ]
                      [ el "a"
                          [ href (routeUrl En currentRoute)
                          , onClick (setFlag MenuOpen false)
                          , class_ ("btn btn-sm justify-center text-xs " <> if lang == En then "btn-primary font-bold shadow-sm" else "btn-ghost bg-base-200/70 font-normal text-base-content/80")
                          ]
                          [ text "English (EN)" ]
                      , el "a"
                          [ href (routeUrl Fr currentRoute)
                          , onClick (setFlag MenuOpen false)
                          , class_ ("btn btn-sm justify-center text-xs " <> if lang == Fr then "btn-primary font-bold shadow-sm" else "btn-ghost bg-base-200/70 font-normal text-base-content/80")
                          ]
                          [ text "Français (FR)" ]
                      ]
                  ]

              -- Theme Mode Selector
              , el "div" [ class_ "space-y-1.5" ]
                  [ el "div" [ class_ "text-[11px] font-mono font-semibold uppercase tracking-wider text-base-content/60 px-1" ]
                      [ text d.common.themeLabel ]
                  , el "div" [ class_ "grid grid-cols-3 gap-2" ]
                      [ el "button"
                          [ type_ "button"
                          , xSetTheme ThemeLight
                          , class_ "btn btn-sm btn-ghost bg-base-200/70 text-xs font-normal flex items-center justify-center gap-1"
                          ]
                          [ el "svg" [ class_ "size-3.5", attr "fill" "none", attr "viewBox" "0 0 24 24", attr "stroke-width" "2", attr "stroke" "currentColor" ]
                              [ el "path" [ attr "stroke-linecap" "round", attr "stroke-linejoin" "round", attr "d" "M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" ] [] ]
                          , el "span" [] [ text d.common.themeLight ]
                          ]
                      , el "button"
                          [ type_ "button"
                          , xSetTheme ThemeDark
                          , class_ "btn btn-sm btn-ghost bg-base-200/70 text-xs font-normal flex items-center justify-center gap-1"
                          ]
                          [ el "svg" [ class_ "size-3.5", attr "fill" "none", attr "viewBox" "0 0 24 24", attr "stroke-width" "2", attr "stroke" "currentColor" ]
                              [ el "path" [ attr "stroke-linecap" "round", attr "stroke-linejoin" "round", attr "d" "M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" ] [] ]
                          , el "span" [] [ text d.common.themeDark ]
                          ]
                      , el "button"
                          [ type_ "button"
                          , xSetTheme ThemeSystem
                          , class_ "btn btn-sm btn-ghost bg-base-200/70 text-xs font-normal flex items-center justify-center gap-1"
                          ]
                          [ el "svg" [ class_ "size-3.5", attr "fill" "none", attr "viewBox" "0 0 24 24", attr "stroke-width" "2", attr "stroke" "currentColor" ]
                              [ el "path" [ attr "stroke-linecap" "round", attr "stroke-linejoin" "round", attr "d" "M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" ] [] ]
                          , el "span" [] [ text d.common.themeSystem ]
                          ]
                      ]
                  ]
              ]
          ]
      ]

renderNavItem :: Lang -> Route -> Route -> String -> Html
renderNavItem lang currentRoute targetRoute label =
  let
    isActive = currentRoute == targetRoute
    activeClass = if isActive then "btn btn-sm btn-ghost font-semibold text-primary" else "btn btn-sm btn-ghost font-normal text-base-content/80 hover:text-base-content"
  in
    navLink { lang, current: currentRoute, target: targetRoute }
      [ class_ activeClass ]
      [ text label ]

renderMobileNavItem :: Lang -> Route -> Route -> String -> Html
renderMobileNavItem lang currentRoute targetRoute label =
  let
    isActive = currentRoute == targetRoute
    activeClass = if isActive then "block px-3.5 py-2.5 rounded-lg text-base font-semibold bg-base-200 text-primary" else "block px-3.5 py-2.5 rounded-lg text-base font-normal text-base-content/80 hover:bg-base-200"
  in
    navLink { lang, current: currentRoute, target: targetRoute }
      [ class_ activeClass
      , onClick (setFlag MenuOpen false)
      ]
      [ text label ]
