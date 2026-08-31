-- | Hub page — DaisyUI card grid with primary actions.
module App.Ui.Templates.Hub
  ( renderHub
  ) where

import Prelude

import App.Html (Html, attr, class_, el, text)
import App.Ui.Breadcrumbs as Breadcrumbs
import App.Ui.Button as Button
import App.Ui.Button (Size(..))
import App.Ui.Card as Card
import App.Ui.Container as Container
import App.Ui.Templates.ActionLink as ActionLink
import App.Ui.Templates.Contract as Contract
import App.Ui.Templates.Types (HubCard, HubSlots, BreadcrumbItem, hubCards)
import Data.Array (length)
import Data.I18n (Lang)
import Data.Route (Route)

renderHub :: Lang -> Route -> HubSlots -> Html
renderHub lang route slots =
  el "section"
    [ class_ "py-16 sm:py-20"
    , attr Contract.marker Contract.hubPage
    ]
    [ Container.container "max-w-6xl" "px-4 sm:px-6"
        [ maybeBreadcrumbs lang route slots.breadcrumbs
        , el "div"
            [ class_ "mx-auto max-w-2xl text-center"
            , attr Contract.marker Contract.hubHeader
            ]
            [ el "h1" [ class_ "text-4xl font-bold sm:text-5xl" ] [ text slots.title ]
            , el "p" [ class_ "mt-4 text-lg opacity-70" ] [ text slots.subtitle ]
            ]
        , el "div"
            [ class_ "mt-12 grid gap-6 md:grid-cols-3"
            , attr Contract.marker Contract.hubCards
            ]
            (map renderCard (hubCards slots.cards))
        ]
    ]

maybeBreadcrumbs :: Lang -> Route -> Array BreadcrumbItem -> Html
maybeBreadcrumbs lang route items =
  if length items == 0 then
    el "span" [] []
  else
    el "div"
      [ class_ "my-4"
      , attr Contract.marker Contract.hubBreadcrumbs
      ]
      [ Breadcrumbs.breadcrumbs lang route items ]

renderCard :: HubCard -> Html
renderCard card =
  el "div" [ attr Contract.marker Contract.hubCard ]
    [ Card.card Card.defaultCardOptions
        [ Card.cardBody
            [ Card.cardTitle card.title
            , el "p" [ class_ "flex-auto opacity-70" ] [ text card.description ]
            , Card.cardActions true
                [ ActionLink.actionTarget Button.ButtonPrimary Md card.target card.buttonLabel ]
            ]
        ]
    ]
