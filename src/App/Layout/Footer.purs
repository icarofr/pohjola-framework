-- | Site footer — delegates to frozen shell blueprint.
module App.Layout.Footer where

import App.Html (Html)
import App.Ui.Shell.SiteFooter as Shell
import Data.Content (siteInfo)
import Data.I18n (Lang, dict)
import Data.Route (Route)

render :: Lang -> Route -> Html
render lang currentRoute =
  let
    d = dict lang
  in
    Shell.siteFooter
      { siteTitle: siteInfo.title
      , siteDescription: siteInfo.description
      , exploreLabel: d.footer.explore
      , resourcesLabel: d.footer.resources
      , aboutLabel: d.nav.about
      , contactLabel: d.nav.contact
      , postsLabel: d.nav.posts
      , githubLabel: d.footer.github
      , issuesLabel: d.footer.issues
      , lang
      , currentRoute
      }
