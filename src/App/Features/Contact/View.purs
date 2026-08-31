-- | Community & Contributing — fills Hub template slots only.
module App.Features.Contact.View where

import App.Html (Html)
import App.Ui.Templates.Render (renderPage)
import App.Ui.Templates.Types
  ( ActionTarget(..)
  , BreadcrumbItem
  , HubSlots
  , PageTemplate(..)
  , hubCardTriple
  , hubSlots
  )
import Data.I18n (Lang(..), dict)
import Data.Maybe (Maybe(..))
import Data.Route (Route(..))

renderContact :: Lang -> Html
renderContact lang =
  renderPage lang Contact (Hub (contactSlots lang))

contactSlots :: Lang -> HubSlots
contactSlots lang =
  let
    d = (dict lang).contact
  in
    hubSlots
      d.title
      d.subtitle
      ( hubCardTriple
          { title: d.issuesTitle
          , description: d.issuesText
          , buttonLabel: d.issuesButton
          , target: External { href: "https://github.com/icarofr/pohjola-framework/issues" }
          }
          { title: d.discussionsTitle
          , description: d.discussionsText
          , buttonLabel: d.discussionsButton
          , target: External { href: "https://github.com/icarofr/pohjola-framework/discussions" }
          }
          { title: d.sourceTitle
          , description: d.sourceText
          , buttonLabel: d.sourceButton
          , target: External { href: "https://github.com/icarofr/pohjola-framework" }
          }
      )
      (contactBreadcrumbs lang)

contactBreadcrumbs :: Lang -> Array BreadcrumbItem
contactBreadcrumbs lang =
  let
    d = (dict lang).contact
  in
    [ { label: homeCrumbLabel lang
      , target: Just (Internal { lang, route: Home })
      }
    , { label: d.title, target: Nothing }
    ]

homeCrumbLabel :: Lang -> String
homeCrumbLabel En = "Home"
homeCrumbLabel Fr = "Accueil"
homeCrumbLabel Pt = "Início"
