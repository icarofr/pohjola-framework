-- | Notice page — one centered announcement and an ordered roadmap list.
-- |
-- | Deliberately not a card grid: a "this doesn't exist yet" page shouldn't
-- | look as fully built as a features or values page. Distinct in shape
-- | from both Editorial (two-column mission + values grid) and Hub (bordered
-- | card grid) — see App.Ui.Templates.Types.NoticeSlots.
module App.Ui.Templates.Notice
  ( renderNotice
  ) where

import Prelude

import App.Html (Html, attr, class_, el, text)
import App.Ui.Container as Container
import App.Ui.Templates.Contract as Contract
import App.Ui.Templates.PageHeader as PageHeader
import App.Ui.Templates.Types (NoticeItem, NoticeSlots)
import Data.Array (mapWithIndex)
import Data.I18n (Lang)
import Data.Maybe (Maybe(..))
import Data.Route (Route)

renderNotice :: Lang -> Route -> NoticeSlots -> Html
renderNotice lang route slots =
  el "section"
    [ class_ "py-16 sm:py-20"
    , attr Contract.marker Contract.noticePage
    ]
    [ Container.container Container.ContainerW3xl "px-4 sm:px-6"
        [ PageHeader.render lang route
            ( PageHeader.pageHeaderSlots slots.heading (Just slots.subtitle) slots.breadcrumbs
            )
        , el "p"
            [ class_ "mt-6 text-xl opacity-80"
            , attr Contract.marker Contract.noticeLead
            ]
            [ text slots.lead ]
        , el "div" [ class_ "mt-16" ]
            [ el "h2" [ class_ "text-2xl font-bold" ] [ text slots.itemsHeading ]
            , el "p" [ class_ "mt-3 opacity-70" ] [ text slots.itemsIntro ]
            , el "ol"
                [ class_ "mt-10 space-y-8"
                , attr Contract.marker Contract.noticeItems
                ]
                (mapWithIndex renderItem slots.items)
            ]
        ]
    ]

renderItem :: Int -> NoticeItem -> Html
renderItem index item =
  el "li"
    [ class_ "flex gap-4"
    , attr Contract.marker Contract.noticeItem
    ]
    [ el "span"
        [ class_ "badge badge-outline badge-lg shrink-0 font-mono" ]
        [ text (show (index + 1)) ]
    , el "div" []
        [ el "p" [ class_ "font-semibold" ] [ text item.title ]
        , el "p" [ class_ "mt-1 text-sm opacity-70" ] [ text item.description ]
        ]
    ]
