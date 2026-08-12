-- | Header — navigation, language toggle, dark mode toggle, mobile menu
-- |
-- | SPA navigation links use `navLink` from App.Alpine — `x-target.push` plus
-- | hover prefetch, except when the link points at the route already shown
-- | (prefetching the current page is a redundant request; see App.Alpine).
-- | Language toggle links are PLAIN anchors — never a nav link: switching
-- | language changes <html lang> and all head metadata, which the AJAX
-- | fragment swap cannot do. The browser must full-reload.
module App.Layout.Header where

import Prelude

import App.Alpine (Flag(..), ariaExpandedFlag, navLink, onClick, onClickOutside, onKeydownEscapeWindow, setFlag, themeToggle, toggleFlag, xCloak, xDataFlag, xShowFlag, xShowNotFlag, xSync)
import App.Html (Attr, Html, ariaLabel, attr, class_, el, href, id_, text)
import Data.Foldable (foldMap)
import Data.I18n (Lang(..), dict, langTag)
import Data.Route (Route(..), navItems, routeUrl)
import Data.String.Common (toUpper)

render :: Lang -> Route -> Html
render lang currentRoute =
  let
    d = dict lang
  in
    el "header"
      [ class_ "sticky top-0 z-50 bg-white/80 dark:bg-slate-900/80 backdrop-blur-md border-b border-slate-200 dark:border-slate-800" ]
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
                  [ class_ "font-display text-xl font-bold text-slate-900 dark:text-white" ]
                  [ text d.common.siteTitle ]
              -- Desktop nav
              , el "div" [ class_ "hidden md:flex items-center space-x-6" ]
                  [ foldMap (renderNavItem lang currentRoute) (navItems lang)
                  , renderDarkToggle lang
                  , renderLangToggle lang currentRoute
                  ]
              -- Mobile menu button
              , el "button"
                  [ onClick (toggleFlag MenuOpen)
                  , attr "aria-controls" "mobile-menu"
                  , ariaExpandedFlag MenuOpen
                  , class_ "md:hidden inline-flex items-center justify-center p-2 rounded-md text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
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
              , class_ "md:hidden px-2 pb-3 pt-2 space-y-1 border-t border-slate-200 dark:border-slate-800"
              , id_ "mobile-menu"
              ]
              [ foldMap (renderMobileNavItem lang currentRoute) (navItems lang)
              , el "div" [ class_ "flex items-center justify-between px-3 py-2" ]
                  [ el "div" [ class_ "flex items-center space-x-3" ]
                      [ langLink En currentRoute
                          [ class_ (langLinkClass lang En) ]
                          [ text (toUpper (langTag En)) ]
                      , el "span" [ class_ "text-slate-300" ] [ text "/" ]
                      , langLink Fr currentRoute
                          [ class_ (langLinkClass lang Fr) ]
                          [ text (toUpper (langTag Fr)) ]
                      ]
                  , renderDarkToggle lang
                  ]
              ]
          ]
      ]

hamburgerIcon :: Html
hamburgerIcon =
  el "svg"
    [ xShowNotFlag MenuOpen
    , class_ "h-6 w-6"
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
    , class_ "h-6 w-6"
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
    [ class_ "h-4 w-4"
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
    [ class_ "h-5 w-5 dark:hidden"
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
    [ class_ "h-5 w-5 hidden dark:block"
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
      if item.route == currentRoute then "text-blue-600 dark:text-blue-400"
      else "text-slate-700 dark:text-slate-300 hover:text-blue-600 dark:hover:text-blue-400"
  in
    navLink { lang, current: currentRoute, target: item.route }
      [ class_ ("text-sm font-medium transition-colors " <> activeClass) ]
      [ text item.label ]

renderMobileNavItem :: Lang -> Route -> { label :: String, route :: Route } -> Html
renderMobileNavItem lang currentRoute item =
  let
    activeClass =
      if item.route == currentRoute then "bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400"
      else "text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
  in
    navLink { lang, current: currentRoute, target: item.route }
      [ class_ ("block px-3 py-2 text-base font-medium rounded-md " <> activeClass) ]
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
          , class_ "flex items-center gap-1 text-sm font-medium text-slate-700 dark:text-slate-300 hover:text-blue-600 dark:hover:text-blue-400"
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
          , class_ "absolute right-0 mt-2 w-32 rounded-md bg-white dark:bg-slate-800 shadow-lg ring-1 ring-black/5 dark:ring-slate-700 py-1"
          ]
          [ langLink En currentRoute
              [ class_ "block px-4 py-2 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700" ]
              [ text "English" ]
          , langLink Fr currentRoute
              [ class_ "block px-4 py-2 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700" ]
              [ text "Français" ]
          ]
      ]

renderDarkToggle :: Lang -> Html
renderDarkToggle lang =
  el "button"
    [ onClick themeToggle
    , class_ "p-1.5 rounded-md text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
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
  | current == target = "text-blue-600 dark:text-blue-400 font-medium"
  | otherwise = "text-slate-400 hover:text-blue-600 dark:hover:text-blue-400"
