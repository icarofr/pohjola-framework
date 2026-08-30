-- | Marketing/hub card — DaisyUI card + figure recipe (research/daisyui card docs)
module App.Ui.Layout.ActionCard
  ( ActionCardProps
  , actionCard
  , actionCardCtaVariant
  ) where

import Prelude

import App.Html (Html)
import App.Ui.Badge (BadgeVariant, badge)
import App.Ui.Button (ButtonVariant(..), Size(..), buttonLink, buttonLinkExternal)
import App.Ui.Card as Card
import App.Ui.Layout.Types (ActionTarget(..))
import Data.Array (catMaybes)
import Data.Maybe (Maybe(..))

-- | Frozen CTA intent — do not vary per feature (eval 07 / UiSpec).
actionCardCtaVariant :: ButtonVariant
actionCardCtaVariant = ButtonOutline

type ActionCardProps =
  { tag :: Maybe { text :: String, variant :: BadgeVariant }
  , imageUrl :: Maybe { url :: String, alt :: String, width :: Int, height :: Int }
  , title :: String
  , description :: String
  , action ::
      { label :: String
      , target :: ActionTarget
      }
  }

actionCard :: ActionCardProps -> Html
actionCard props =
  Card.card Card.defaultCardOptions
    ( catMaybes
        [ map
            ( \img ->
                Card.cardFigure
                  ( Card.cardImage
                      { src: img.url
                      , alt: img.alt
                      , width: img.width
                      , height: img.height
                      }
                  )
            )
            props.imageUrl
        , Just
            ( Card.cardBody
                ( catMaybes
                    [ map (\t -> badge t.variant t.text) props.tag
                    , Just (Card.cardTitle props.title)
                    , Just (Card.cardText props.description)
                    , Just
                        ( Card.cardActions true
                            [ case props.action.target of
                                Internal t ->
                                  buttonLink
                                    { variant: actionCardCtaVariant
                                    , size: Sm
                                    , lang: t.lang
                                    , route: t.route
                                    }
                                    props.action.label
                                External t ->
                                  buttonLinkExternal
                                    { variant: actionCardCtaVariant
                                    , size: Sm
                                    , href: t.href
                                    }
                                    props.action.label
                            ]
                        )
                    ]
                )
            )
        ]
    )
