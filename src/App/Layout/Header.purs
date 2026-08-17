-- | Site header navigation — DaisyUI navbar component
module App.Layout.Header where

import Prelude

import App.Alpine (Flag(..), ariaExpandedFlag, navLink, onClick, spaLink, toggleFlag, xCloak, xDataFlag, xShowFlag)
import App.Html (Html, attr, class_, el, href, text)
import App.Layout.Icons (pohjolaLogo)
import App.Ui.Badge as Badge
import Data.Content (siteInfo)
import Data.I18n (Dictionary, Lang(..), dict)
import Data.Route (Route(..), routeUrl)

render :: Lang -> Route -> Html
render lang currentRoute =
  let
    d = dict lang
    otherLang = case lang of
      En -> Fr
      Fr -> En
    langToggleUrl = routeUrl otherLang currentRoute
    langToggleLabel = case lang of
      En -> "FR"
      Fr -> "EN"
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
              , Badge.badge Badge.BadgeSuccess "v0.1"
              ]

          -- Navbar Center: Desktop Nav
          , el "div" [ class_ "navbar-center hidden md:flex items-center space-x-1" ]
              [ renderNavItem lang currentRoute About d.nav.about
              , renderNavItem lang currentRoute Contact d.nav.contact
              , renderNavItem lang currentRoute PostList d.nav.posts
              ]

          -- Navbar End: Language switcher + Mobile menu button
          , el "div" [ class_ "navbar-end w-auto flex items-center gap-2" ]
              [ el "a"
                  [ href langToggleUrl
                  , class_ "btn btn-ghost btn-sm font-mono text-xs"
                  , attr "aria-label" ("Switch language to " <> langToggleLabel)
                  ]
                  [ text langToggleLabel ]
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
