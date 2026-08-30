-- | Site header — delegates to frozen shell blueprint.
module App.Layout.Header where

import App.Html (Html)
import App.Ui.Shell.SiteHeader as Shell
import Data.Content (siteInfo)
import Data.I18n (Lang, dict)
import Data.Route (Route)

render :: Lang -> Route -> Html
render lang currentRoute =
  let
    d = dict lang
  in
    Shell.siteHeader
      { lang
      , currentRoute
      , menuLabel: d.common.menuLabel
      , siteTitle: siteInfo.title
      , aboutLabel: d.nav.about
      , contactLabel: d.nav.contact
      , postsLabel: d.nav.posts
      , langToggleLabel: d.common.langToggleLabel
      , themeToggleLabel: d.common.themeLabel
      }
