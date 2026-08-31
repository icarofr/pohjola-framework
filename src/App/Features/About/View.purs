-- | About page view — fills Editorial template slots only.
module App.Features.About.View where

import App.Html (Html)
import App.Ui.Templates.Render (renderPage)
import App.Ui.Templates.Types
  ( ActionTarget(..)
  , BreadcrumbItem
  , EditorialSlots
  , PageTemplate(..)
  , editorialSlots
  , valuesSlotsFromArray
  )
import Data.I18n (Lang(..), dict)
import Data.Maybe (Maybe(..))
import Data.Route (Route(..))

renderAbout :: Lang -> Html
renderAbout lang =
  renderPage lang About (Editorial (aboutSlots lang))

aboutSlots :: Lang -> EditorialSlots
aboutSlots lang =
  let
    d = (dict lang).about
  in
    editorialSlots
      d.heading
      d.mission
      (valuesSlotsFromArray d.values.heading d.values.intro d.values.items)
      (aboutBreadcrumbs lang)

aboutBreadcrumbs :: Lang -> Array BreadcrumbItem
aboutBreadcrumbs lang =
  let
    d = (dict lang).about
  in
    [ { label: homeCrumbLabel lang
      , target: Just (Internal { lang, route: Home })
      }
    , { label: d.heading, target: Nothing }
    ]

homeCrumbLabel :: Lang -> String
homeCrumbLabel En = "Home"
homeCrumbLabel Fr = "Accueil"
