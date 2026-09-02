-- | About page view — fills Editorial template slots only.
module App.Features.About.View where

import App.Form (FormStatus)
import App.Html (Html)
import App.Ui.Templates.PageHeader as PageHeader
import App.Ui.Templates.Render (renderPage)
import App.Ui.Templates.Types
  ( EditorialSlots
  , PageTemplate(..)
  , editorialSlots
  , valuesSlotsFromArray
  )
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe(..))
import Data.Route (Route(..))

renderAbout :: Lang -> Maybe FormStatus -> Html
renderAbout lang status =
  renderPage lang About status (Editorial (aboutSlots lang))

aboutSlots :: Lang -> EditorialSlots
aboutSlots lang =
  let
    d = (dict lang).about
    nav = (dict lang).nav
  in
    editorialSlots
      d.heading
      (Just d.subtitle)
      d.mission
      (valuesSlotsFromArray d.values.heading d.values.intro d.values.items)
      [ PageHeader.breadcrumbHome lang nav.home
      , PageHeader.breadcrumbHere nav.about
      ]
