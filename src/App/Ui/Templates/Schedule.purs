-- | Schedule page — DaisyUI match rows with crests (fixtures, calendars).
module App.Ui.Templates.Schedule
  ( renderSchedule
  ) where

import Prelude

import App.Html (Html, attr, class_, el, text)
import App.Ui.Badge as Badge
import App.Ui.Card as Card
import App.Ui.Container as Container
import App.Ui.Templates.ActionLink as ActionLink
import App.Ui.Templates.Contract as Contract
import App.Ui.Templates.PageHeader as PageHeader
import App.Ui.Templates.Types (ScheduleMatch, ScheduleSlots)

renderSchedule :: ScheduleSlots -> Html
renderSchedule slots =
  el "section"
    [ class_ "py-16 sm:py-20"
    , attr Contract.marker Contract.schedulePage
    ]
    [ Container.container "max-w-4xl" "px-4 sm:px-6"
        [ PageHeader.renderCentered { title: slots.title, subtitle: slots.subtitle }
        , el "div"
            [ class_ "mt-12 flex flex-col gap-4"
            , attr Contract.marker Contract.scheduleList
            ]
            (map renderMatchRow slots.matches)
        ]
    ]

renderMatchRow :: ScheduleMatch -> Html
renderMatchRow match =
  el "article" [ attr Contract.marker Contract.scheduleRow ]
    [ Card.card Card.defaultCardOptions
        [ Card.cardBody
            [ el "div" [ class_ "flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between" ]
                [ el "div" [ class_ "flex items-center justify-center gap-4 sm:justify-start" ]
                    [ crest match.home
                    , el "span" [ class_ "text-sm font-semibold uppercase tracking-wide opacity-50" ]
                        [ text match.vsLabel ]
                    , crest match.away
                    ]
                , el "div" [ class_ "flex flex-1 flex-col gap-2 text-center sm:text-left" ]
                    [ el "div" [ class_ "flex flex-wrap items-center justify-center gap-2 sm:justify-start" ]
                        [ Badge.badge Badge.BadgeSecondary match.competition
                        , el "span" [ class_ "text-sm opacity-60" ] [ text match.kickoff ]
                        ]
                    , el "h2" [ class_ "text-lg font-semibold" ]
                        [ ActionLink.titleLink match.target match.title ]
                    , el "p" [ class_ "text-sm opacity-70" ] [ text match.detail ]
                    ]
                ]
            ]
        ]
    ]

crest :: { src :: String, alt :: String } -> Html
crest { src, alt } =
  Card.cardFigure
    ( Card.cardImage
        { src
        , alt
        , width: 48
        , height: 48
        }
    )
