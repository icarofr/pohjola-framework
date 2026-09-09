-- | Docs page view — fills Notice template slots only.
-- |
-- | Notice, not Editorial: one lead paragraph and an ordered roadmap list,
-- | not a mission statement with a six-item grid — a "not built yet" page
-- | shouldn't look as fully loaded as a features page.
module App.Features.Docs.View where

import App.Form (FormStatus)
import App.Html (Html)
import App.Ui.Templates.PageHeader as PageHeader
import App.Ui.Templates.Render (renderPage)
import App.Ui.Templates.Types (NoticeSlots, PageTemplate(..), noticeSlots)
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe)
import Data.Route (Route(..))

renderDocs :: Lang -> Maybe FormStatus -> Html
renderDocs lang status =
  renderPage lang Docs status (Notice (docsSlots lang))

docsSlots :: Lang -> NoticeSlots
docsSlots lang =
  let
    d = (dict lang).docs
    nav = (dict lang).nav
  in
    noticeSlots d.heading d.subtitle d.lead d.itemsHeading d.itemsIntro d.items
      [ PageHeader.breadcrumbHome lang nav.home
      , PageHeader.breadcrumbHere d.heading
      ]
