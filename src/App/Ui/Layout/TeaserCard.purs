-- | Content-feed teaser — DaisyUI linked card-body recipe
module App.Ui.Layout.TeaserCard
  ( TeaserCardProps
  , teaserCard
  , teaserCardBodyClass
  , teaserCardReadMoreClass
  ) where

import Prelude

import App.Alpine (spaLink)
import App.Html (Html, class_, el, href, rel_, target_, text)
import App.Ui.Badge as Badge
import App.Ui.Card (CardOptions, defaultCardOptions)
import App.Ui.Card as Card
import App.Ui.Layout.Types (ActionTarget(..))
import Data.Array (catMaybes)
import Data.Maybe (Maybe(..))

type TeaserCardProps =
  { meta :: Maybe String
  , title :: String
  , excerpt :: String
  , action ::
      { label :: String
      , target :: ActionTarget
      }
  }

teaserCardBodyClass :: String
teaserCardBodyClass = "card-body gap-3 transition-colors hover:bg-base-200/50"

teaserCardReadMoreClass :: String
teaserCardReadMoreClass = "text-sm font-medium text-primary"

teaserCardOptions :: CardOptions
teaserCardOptions =
  defaultCardOptions { fullHeight = true }

teaserCardBody :: TeaserCardProps -> Array Html -> Html
teaserCardBody props children =
  case props.action.target of
    Internal t ->
      spaLink t.lang t.route [ class_ teaserCardBodyClass ] children
    External t ->
      el "a"
        [ href t.href
        , target_ "_blank"
        , rel_ "noopener noreferrer"
        , class_ teaserCardBodyClass
        ]
        children

teaserCard :: TeaserCardProps -> Html
teaserCard props =
  Card.card teaserCardOptions
    [ teaserCardBody props
        ( catMaybes
            [ map (Badge.badgeSized Badge.BadgeXs Badge.BadgeNeutral) props.meta
            , Just (Card.cardTitle props.title)
            , Just (Card.cardText props.excerpt)
            , Just (el "span" [ class_ teaserCardReadMoreClass ] [ text props.action.label ])
            ]
        )
    ]
