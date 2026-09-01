-- | Article page — DaisyUI prose body and meta card.
module App.Ui.Templates.Article
  ( renderArticle
  ) where

import App.Html (Html, attr, class_, el, text)
import App.Ui.Badge as Badge
import App.Ui.Card as Card
import App.Ui.Container as Container
import App.Ui.Prose as Prose
import App.Ui.Templates.Contract as Contract
import App.Ui.Templates.PageHeader as PageHeader
import App.Ui.Templates.Types (ArticleSlots)
import Data.I18n (Lang)
import Data.Maybe (Maybe(..))
import Data.Route (Route)

renderArticle :: Lang -> Route -> ArticleSlots -> Html
renderArticle lang route slots =
  el "article"
    [ class_ "py-12 sm:py-16"
    , attr Contract.marker Contract.articlePage
    ]
    [ Container.container "max-w-6xl" "px-4 sm:px-6"
        [ PageHeader.renderDetail lang route
            [ Badge.badge Badge.BadgeSecondary slots.metaTag ]
            ( PageHeader.pageHeaderSlots slots.title Nothing slots.breadcrumbs
            )
        , el "div" [ class_ "mt-8 grid gap-10 lg:grid-cols-[minmax(0,1fr)_280px]" ]
            [ el "div" []
                [ el "div"
                    [ attr Contract.marker Contract.articleBody
                    , class_ "max-w-3xl"
                    ]
                    [ Prose.proseLg [ el "p" [] [ text slots.body ] ] ]
                ]
            , el "aside" [ attr Contract.marker Contract.articleMeta ]
                [ Card.card Card.defaultCardOptions
                    [ Card.cardBody
                        [ Card.cardTitle "Author"
                        , el "p" [ class_ "font-medium" ] [ text slots.authorName ]
                        , el "p" [ class_ "text-sm opacity-70" ] [ text "Engineering" ]
                        , el "div" [ class_ "divider my-4" ] []
                        , el "p" [ class_ "font-medium" ] [ text "Published" ]
                        , el "p" [ class_ "text-sm opacity-70" ] [ text slots.date ]
                        ]
                    ]
                ]
            ]
        ]
    ]
