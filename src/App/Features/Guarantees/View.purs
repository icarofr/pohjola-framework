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
  , emptyValue
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
  in
    editorialSlots
      d.heading
      (Just d.body)
      { heading: d.heading
      , lead: d.body
      , body: d.body
      }
      (valuesSlots d.heading d.body (valueSextuple emptyValue emptyValue emptyValue emptyValue emptyValue emptyValue))
      [ PageHeader.breadcrumbHome lang nav.home
      , PageHeader.breadcrumbHere d.heading
      ]
