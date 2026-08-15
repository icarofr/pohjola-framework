-- | Header / Top Navigation component
-- |
-- | Uses `navLink` for internal routes — swaps #content on click, prefetches
-- | on hover, unless pointing to current route.
-- | Language switch links intentionally do NOT use `navLink` — switching language
-- | changes the HTML `lang` attribute on <html>, which is outside #content, so it
-- | requires a full document load.
module App.Layout.Header where

import Prelude

import App.Alpine (Flag(..), ariaExpandedFlag, onClick, onClickOutside, onKeydownEscapeWindow, setFlag, themeToggle, toggleFlag, xCloak, xDataFlag, xShowFlag, xShowNotFlag, xSync, navLink)
import App.Html (Attr, Html, ariaLabel, attr, class_, el, href, id_, text)
import Data.Foldable (foldMap)
import Data.I18n (Lang(..), dict, langTag)
import Data.Route (Route(..), navItems, routeUrl)
import Data.String (toUpper)

render :: Lang -> Route -> Html
render lang currentRoute =
  let
    d = dict lang
  in
    el "header" [ class_ "sticky top-0 z-40 w-full backdrop-blur-md bg-white/80 dark:bg-gray-950/80 border-b border-gray-200/80 dark:border-white/10 transition-colors" ]
      [ el "nav"
          [ id_ "nav"
          , xDataFlag MenuOpen false
          , xSync
          , class_ "mx-auto max-w-7xl px-4 sm:px-6 lg:px-8"
          , ariaLabel d.common.navAriaLabel
          ]
          [ el "div" [ class_ "flex items-center justify-between h-16" ]
              [ -- Logo
                navLink { lang, current: currentRoute, target: Home }
                  [ class_ "flex items-center gap-x-2.5 font-display text-lg font-bold text-gray-900 dark:text-white tracking-tight group" ]
                  [ brandIcon
                  , el "span" [ class_ "transition-colors group-hover:text-emerald-600 dark:group-hover:text-emerald-400" ] [ text d.common.siteTitle ]
                  ]
              -- Desktop nav
              , el "div" [ class_ "hidden md:flex items-center space-x-8" ]
                  [ el "div" [ class_ "flex items-center space-x-6" ]
                      [ foldMap (renderNavItem lang currentRoute) (navItems lang) ]
                  , el "div" [ class_ "flex items-center space-x-3 border-l border-gray-200 dark:border-white/10 pl-6" ]
                      [ renderDarkToggle lang
                      , renderLangToggle lang currentRoute
                      ]
                  ]
              -- Mobile menu button
              , el "button"
                  [ onClick (toggleFlag MenuOpen)
                  , attr "aria-controls" "mobile-menu"
                  , ariaExpandedFlag MenuOpen
                  , class_ "md:hidden inline-flex items-center justify-center p-2 rounded-lg text-gray-500 hover:text-gray-900 hover:bg-gray-100 dark:text-gray-400 dark:hover:text-white dark:hover:bg-white/10 transition-colors focus-visible:outline-2 focus-visible:outline-emerald-600"
                  , ariaLabel d.common.menuLabel
                  ]
                  [ hamburgerIcon
                  , closeIcon
                  ]
              ]
          -- Mobile nav
          , el "div"
              [ xShowFlag MenuOpen
              , xCloak
              , onClickOutside (setFlag MenuOpen false)
              , onClick (setFlag MenuOpen false)
              , onKeydownEscapeWindow (setFlag MenuOpen false)
              , class_ "md:hidden px-2 pb-4 pt-2 space-y-1 border-t border-gray-200 dark:border-white/10"
              , id_ "mobile-menu"
              ]
              [ foldMap (renderMobileNavItem lang currentRoute) (navItems lang)
              , el "div" [ class_ "flex items-center justify-between px-3 pt-3 mt-2 border-t border-gray-100 dark:border-white/5" ]
                  [ el "div" [ class_ "flex items-center space-x-2" ]
                      [ langLink En currentRoute
                          [ class_ (langLinkClass lang En) ]
                          [ text (toUpper (langTag En)) ]
                      , el "span" [ class_ "text-gray-300 dark:text-gray-600" ] [ text "/" ]
                      , langLink Fr currentRoute
                          [ class_ (langLinkClass lang Fr) ]
                          [ text (toUpper (langTag Fr)) ]
                      ]
                  , renderDarkToggle lang
                  ]
              ]
          ]
      ]

brandIcon :: Html
brandIcon =
  el "div"
    [ class_ "size-8 rounded-lg bg-emerald-600 flex items-center justify-center text-white shadow-xs font-bold text-sm tracking-wider" ]
    [ el "svg"
        [ class_ "size-5"
        , attr "viewBox" "0 0 24 24"
        , attr "fill" "none"
        , attr "stroke" "currentColor"
        , attr "stroke-width" "2"
        ]
        [ el "path"
            [ attr "stroke-linecap" "round"
            , attr "stroke-linejoin" "round"
            , attr "d" "M13 10V3L4 14h7v7l9-11h-7z"
            ]
            []
        ]
    ]

hamburgerIcon :: Html
hamburgerIcon =
  el "svg"
    [ xShowNotFlag MenuOpen
    , class_ "size-6"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke-width" "1.5"
    , attr "stroke" "currentColor"
    ]
    [ el "path"
        [ attr "stroke-linecap" "round"
        , attr "stroke-linejoin" "round"
        , attr "d" "M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
        ]
        []
    ]

closeIcon :: Html
closeIcon =
  el "svg"
    [ xShowFlag MenuOpen
    , xCloak
    , class_ "size-6"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke-width" "1.5"
    , attr "stroke" "currentColor"
    ]
    [ el "path"
        [ attr "stroke-linecap" "round"
        , attr "stroke-linejoin" "round"
        , attr "d" "M6 18L18 6M6 6l12 12"
        ]
        []
    ]

chevronDownIcon :: Html
chevronDownIcon =
  el "svg"
    [ class_ "size-4 text-gray-400 dark:text-gray-500"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke-width" "1.5"
    , attr "stroke" "currentColor"
    ]
    [ el "path"
        [ attr "stroke-linecap" "round"
        , attr "stroke-linejoin" "round"
        , attr "d" "M19.5 8.25l-7.5 7.5-7.5-7.5"
        ]
        []
    ]

sunIcon :: Html
sunIcon =
  el "svg"
    [ class_ "size-5 dark:hidden"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke-width" "1.5"
    , attr "stroke" "currentColor"
    ]
    [ el "path"
        [ attr "stroke-linecap" "round"
        , attr "stroke-linejoin" "round"
        , attr "d" "M21.752 15.002A9.718 9.718 0 0118 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 003 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 009.002-5.998z"
        ]
        []
    ]

moonIcon :: Html
moonIcon =
  el "svg"
    [ class_ "size-5 hidden dark:block"
    , attr "fill" "none"
    , attr "viewBox" "0 0 24 24"
    , attr "stroke-width" "1.5"
    , attr "stroke" "currentColor"
    ]
    [ el "path"
        [ attr "stroke-linecap" "round"
        , attr "stroke-linejoin" "round"
        , attr "d" "M12 3v2.25m6.364.386l-1.591 1.591M21 12h-2.25m-.386 6.364l-1.591-1.591M12 18.75V21m-4.773-4.227l-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0z"
        ]
        []
    ]

renderNavItem :: Lang -> Route -> { label :: String, route :: Route } -> Html
renderNavItem lang currentRoute item =
  let
    activeClass =
      if item.route == currentRoute then "text-emerald-600 dark:text-emerald-400 font-semibold"
      else "text-gray-600 dark:text-gray-300 hover:text-emerald-600 dark:hover:text-emerald-400 font-medium"
  in
    navLink { lang, current: currentRoute, target: item.route }
      [ class_ ("text-sm transition-colors " <> activeClass) ]
      [ text item.label ]

renderMobileNavItem :: Lang -> Route -> { label :: String, route :: Route } -> Html
renderMobileNavItem lang currentRoute item =
  let
    activeClass =
      if item.route == currentRoute then "bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-400"
      else "text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-800/50"
  in
    navLink { lang, current: currentRoute, target: item.route }
      [ class_ ("block px-3 py-2 text-base font-medium rounded-lg transition-colors " <> activeClass) ]
      [ text item.label ]

renderLangToggle :: Lang -> Route -> Html
renderLangToggle lang currentRoute =
  let
    d = dict lang
  in
    el "div" [ xDataFlag LangMenuOpen false, class_ "relative", onKeydownEscapeWindow (setFlag LangMenuOpen false) ]
      [ el "button"
          [ onClick (toggleFlag LangMenuOpen)
          , ariaExpandedFlag LangMenuOpen
          , attr "aria-haspopup" "true"
          , attr "aria-controls" "lang-menu"
          , class_ "flex items-center gap-1.5 rounded-lg px-2.5 py-1.5 text-sm font-semibold text-gray-700 dark:text-gray-300 hover:text-emerald-600 dark:hover:text-emerald-400 hover:bg-gray-100 dark:hover:bg-white/10 transition-colors focus-visible:outline-2 focus-visible:outline-emerald-600 cursor-pointer"
          , ariaLabel d.common.langToggleLabel
          ]
          [ el "span" [] [ text (toUpper (langTag lang)) ]
          , chevronDownIcon
          ]
      , el "div"
          [ xShowFlag LangMenuOpen
          , xCloak
          , onClickOutside (setFlag LangMenuOpen false)
          , id_ "lang-menu"
          , class_ "absolute right-0 mt-2 w-36 origin-top-right rounded-lg bg-white dark:bg-gray-800 p-1 shadow-lg ring-1 ring-black/5 dark:ring-white/10 focus:outline-hidden"
          ]
          [ langLink En currentRoute
              [ class_ "block rounded-md px-3 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors" ]
              [ text "English" ]
          , langLink Fr currentRoute
              [ class_ "block rounded-md px-3 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors" ]
              [ text "Français" ]
          ]
      ]

renderDarkToggle :: Lang -> Html
renderDarkToggle lang =
  el "button"
    [ onClick themeToggle
    , class_ "rounded-lg p-2 text-gray-500 hover:text-gray-900 hover:bg-gray-100 dark:text-gray-400 dark:hover:text-white dark:hover:bg-white/10 transition-colors focus-visible:outline-2 focus-visible:outline-emerald-600 cursor-pointer"
    , ariaLabel (dict lang).common.darkModeToggle
    ]
    [ sunIcon
    , moonIcon
    ]

-- | Language switch link — a PLAIN anchor (real href, full reload), NOT
-- | navLink. See module header for why AJAX must not swap across languages.
langLink :: Lang -> Route -> Array Attr -> Array Html -> Html
langLink target currentRoute extraAttrs children =
  el "a"
    ([ href (routeUrl target currentRoute) ] <> extraAttrs)
    children

langLinkClass :: Lang -> Lang -> String
langLinkClass current target
  | current == target = "text-emerald-600 dark:text-emerald-400 font-semibold"
  | otherwise = "text-gray-400 hover:text-emerald-600 dark:hover:text-emerald-400 font-medium transition-colors"
