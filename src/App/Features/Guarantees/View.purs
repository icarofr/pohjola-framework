-- | Guarantees page view — fills Editorial template slots only.
module App.Features.Guarantees.View where

import App.Form (FormStatus)
import App.Html (Html)
import App.Ui.Templates.PageHeader as PageHeader
import App.Ui.Templates.Render (renderPage)
import App.Ui.Templates.Types
  ( EditorialSlots
  , PageTemplate(..)
  , editorialSlots
  , valueSextuple
  , valuesSlots
  )
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe(..))
import Data.Route (Route(..))

renderGuarantees :: Lang -> Maybe FormStatus -> Html
renderGuarantees lang status =
  renderPage lang Guarantees status (Editorial (pageSlots lang))

pageSlots :: Lang -> EditorialSlots
pageSlots lang =
  let
    d = (dict lang).guarantees
    nav = (dict lang).nav
    items = d.values.items
  in
    editorialSlots
      d.heading
      (Just d.subtitle)
      { heading: d.mission.heading
      , lead: d.mission.lead
      , body: d.mission.body
      }
      ( valuesSlots d.values.heading d.values.intro
          (valueSextuple items.one items.two items.three items.four items.five items.six)
      )
      [ PageHeader.breadcrumbHome lang nav.home
      , PageHeader.breadcrumbHere d.heading
      ]
