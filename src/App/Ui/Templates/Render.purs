-- | Deterministic page renderer — the only way to produce routed page content.
module App.Ui.Templates.Render
  ( renderPage
  ) where

import App.Form (FormStatus)
import App.Html (Html)
import App.Ui.Templates.Article as Article
import App.Ui.Templates.Editorial as Editorial
import App.Ui.Templates.Feed as Feed
import App.Ui.Templates.Hub as Hub
import App.Ui.Templates.Landing as Landing
import App.Ui.Templates.Schedule as Schedule
import App.Ui.Templates.SiteShell as Shell
import App.Ui.Templates.Types (PageTemplate(..))
import Data.I18n (Lang)
import Data.Maybe (Maybe)
import Data.Route (Route)

renderPage :: Lang -> Route -> Maybe FormStatus -> PageTemplate -> Html
renderPage lang route status template =
  let
    labels = Shell.shellLabels lang
    body = case template of
      Landing slots ->
        Landing.renderLanding slots
      Editorial slots ->
        Editorial.renderEditorial lang route slots
      Hub slots ->
        Hub.renderHub lang route slots
      Feed slots ->
        Feed.renderFeed lang route slots
      Schedule slots ->
        Schedule.renderSchedule lang route slots
      Article slots ->
        Article.renderArticle lang route slots
  in
    Shell.sitePage lang route labels status body
