-- | Community & Contributing — fills Hub template slots only.
module App.Features.Contact.View where

import App.Form (FormStatus)
import App.Html (Html)
import App.Ui.Templates.PageHeader as PageHeader
import App.Ui.Templates.Render (renderPage)
import App.Ui.Templates.Types
  ( ActionTarget(..)
  , HubSlots
  , PageTemplate(..)
  , hubCardTriple
  , hubSlots
  )
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe)
import Data.Route (Route(..))

renderContact :: Lang -> Maybe FormStatus -> Html
renderContact lang status =
  renderPage lang Contact status (Hub (contactSlots lang))

contactSlots :: Lang -> HubSlots
contactSlots lang =
  let
    d = (dict lang).contact
    nav = (dict lang).nav
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
      [ PageHeader.breadcrumbHome lang nav.home
      , PageHeader.breadcrumbHere nav.contact
      ]
