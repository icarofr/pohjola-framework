-- | Feed page — DaisyUI card grid for post teasers.
module App.Ui.Templates.Feed
  ( renderFeed
  ) where

import Prelude

import App.Html (Html, attr, class_, el, text)
import App.Ui.Avatar as Avatar
import App.Ui.Badge as Badge
import App.Ui.Card as Card
import App.Ui.Container as Container
import App.Ui.Templates.ActionLink as ActionLink
import App.Ui.Templates.Contract as Contract
import App.Ui.Templates.PageHeader as PageHeader
import App.Ui.Templates.Types (FeedCard, FeedSlots)
import Data.I18n (Lang)
import Data.Maybe (Maybe(..))
import Data.Route (Route)
import Data.String as String

renderFeed :: Lang -> Route -> FeedSlots -> Html
renderFeed lang route slots =
  el "section"
    [ class_ "py-16 sm:py-20"
    , attr Contract.marker Contract.feedPage
    ]
    [ Container.container "max-w-6xl" "px-4 sm:px-6"
        [ PageHeader.render lang route
            ( PageHeader.pageHeaderSlots slots.title (Just slots.subtitle) slots.breadcrumbs
            )
        , el "div"
            [ class_ "mt-12 grid gap-6 md:grid-cols-2 lg:grid-cols-3"
            , attr Contract.marker Contract.feedGrid
            ]
            (map renderPostCard slots.posts)
        ]
    ]

renderPostCard :: FeedCard -> Html
renderPostCard card =
  el "article" [ attr Contract.marker Contract.feedCard ]
    [ Card.card Card.defaultCardOptions
        ( cardFigure card
            <>
              [ Card.cardBody
                  [ el "div" [ class_ "flex items-center gap-2 text-xs" ]
                      [ Badge.badge Badge.BadgeSecondary card.category
                      , el "span" [ class_ "opacity-60" ] [ text card.date ]
                      ]
                  , el "h3" [ class_ "card-title line-clamp-2" ]
                      [ ActionLink.titleLink card.target card.title ]
                  , el "p" [ class_ "line-clamp-3 opacity-70" ] [ text card.excerpt ]
                  , el "div" [ class_ "mt-auto flex items-center gap-3 pt-6" ]
                      [ Avatar.avatarPlaceholder Avatar.Avatar8 (String.take 1 card.authorName)
                      , el "div" [ class_ "text-sm" ]
                          [ el "p" [ class_ "font-medium" ] [ text card.authorName ]
                          , el "p" [ class_ "opacity-60" ] [ text card.authorRole ]
                          ]
                      ]
                  ]
              ]
        )
    ]

cardFigure :: FeedCard -> Array Html
cardFigure card =
  if String.trim card.imageUrl == "" then
    []
  else
    [ Card.cardFigure
        ( Card.cardImage
            { src: card.imageUrl
            , alt: card.title
            , width: 400
            , height: 200
            }
        )
    ]
