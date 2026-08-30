-- | Site header — frozen navbar shell (DESIGN.md + Daisy navbar).
module App.Ui.Shell.SiteHeader
  ( SiteHeaderProps
  , siteHeader
  , siteHeaderClass
  ) where

import Prelude

import App.Alpine (navLink, xSync)
import App.Html (Html, attr, class_, el, id_, text)
import App.Layout.Icons (pohjolaLogo)
import App.Ui.Shell.LangMenu as LangMenu
import App.Ui.Shell.ThemeControl as ThemeControl
import Data.I18n (Lang(..))
import Data.Route (Route(..))

type SiteHeaderProps =
  { lang :: Lang
  , currentRoute :: Route
  , menuLabel :: String
  , siteTitle :: String
  , aboutLabel :: String
  , contactLabel :: String
  , postsLabel :: String
  , langToggleLabel :: String
  , themeToggleLabel :: String
  }

siteHeaderClass :: String
siteHeaderClass = "navbar sticky top-0 z-10 bg-base-100/80 backdrop-blur border-b border-base-300 min-h-0"

siteHeader :: SiteHeaderProps -> Html
siteHeader props =
  let
    langLabel = case props.lang of
      En -> "EN"
      Fr -> "FR"
  in
    el "header"
      [ id_ "header"
      , class_ siteHeaderClass
      , xSync
      ]
      [ el "div" [ class_ "navbar-start" ]
          [ el "label"
              [ attr "for" "nav-drawer"
              , class_ "btn btn-ghost lg:hidden"
              , attr "aria-label" props.menuLabel
              ]
              [ text "☰" ]
          , navLink { lang: props.lang, current: props.currentRoute, target: Home }
              [ class_ "btn btn-ghost gap-2" ]
              [ pohjolaLogo, text props.siteTitle ]
          ]
      , el "div" [ class_ "navbar-center hidden lg:flex" ]
          [ el "ul" [ class_ "menu menu-horizontal px-1" ]
              [ el "li" [] [ navLink { lang: props.lang, current: props.currentRoute, target: About } [] [ text props.aboutLabel ] ]
              , el "li" [] [ navLink { lang: props.lang, current: props.currentRoute, target: Contact } [] [ text props.contactLabel ] ]
              , el "li" [] [ navLink { lang: props.lang, current: props.currentRoute, target: PostList } [] [ text props.postsLabel ] ]
              ]
          ]
      , el "div" [ class_ "navbar-end gap-1" ]
          [ LangMenu.langMenu
              { currentLang: props.lang
              , currentRoute: props.currentRoute
              , ariaLabel: props.langToggleLabel
              , currentLangLabel: langLabel
              }
          , ThemeControl.themeControl { ariaLabel: props.themeToggleLabel }
          ]
      ]
