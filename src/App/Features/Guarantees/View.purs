-- | Guarantees page view — fills Hub template slots only.
-- |
-- | Hub, not Editorial: three condensed claims as cards, not a mission
-- | statement with a six-item grid — visually distinct from About, which
-- | genuinely is a mission-and-principles page.
module App.Features.Guarantees.View where

import App.Form (FormStatus)
import App.Html (Html)
import App.Ui.Templates.PageHeader as PageHeader
import App.Ui.Templates.Render (renderPage)
import App.Ui.Templates.Types (ActionTarget(..), HubSlots, PageTemplate(..), hubCardTriple, hubSlots)
import Data.Content (ciConfigUrl, htmlSourceUrl, policyGateUrl)
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe)
import Data.Route (Route(..))

renderGuarantees :: Lang -> Maybe FormStatus -> Html
renderGuarantees lang status =
  renderPage lang Guarantees status (Hub (guaranteesSlots lang))

-- | Each card names a different file backing its claim (policy gate, Html
-- | ADT, CI config) — never the same link three times. See Data.Content's
-- | doc comments for which docs/GUARANTEES.md row each one matches.
guaranteesSlots :: Lang -> HubSlots
guaranteesSlots lang =
  let
    d = (dict lang).guarantees
    nav = (dict lang).nav
    toCard href c =
      { title: c.title
      , description: c.description
      , buttonLabel: c.buttonLabel
      , target: External { href }
      }
  in
    hubSlots d.heading d.subtitle d.lead
      ( hubCardTriple
          (toCard policyGateUrl d.cards.one)
          (toCard htmlSourceUrl d.cards.two)
          (toCard ciConfigUrl d.cards.three)
      )
      [ PageHeader.breadcrumbHome lang nav.home
      , PageHeader.breadcrumbHere d.heading
      ]
