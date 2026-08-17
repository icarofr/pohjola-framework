-- | Stat primitive — Metric card conforming to DESIGN.md and Layr dashboard guidelines
module App.Ui.Stat where

import Prelude

import App.Html (Html, class_, el, text)
import Data.Maybe (Maybe(..))

type StatItem =
  { label :: String
  , value :: String
  , description :: Maybe String
  }

-- | Render a single metric card
statCard :: StatItem -> Html
statCard item =
  el "div" [ class_ "stat bg-base-100 rounded-lg ring-1 ring-base-content/10 p-5 shadow-xs" ]
    [ el "div" [ class_ "stat-title text-xs font-semibold uppercase tracking-wider text-base-content/60" ] [ text item.label ]
    , el "div" [ class_ "stat-value text-2xl font-bold tracking-tight text-base-content" ] [ text item.value ]
    , case item.description of
        Just desc -> el "div" [ class_ "stat-desc text-xs text-base-content/70 mt-1" ] [ text desc ]
        Nothing -> text ""
    ]

-- | Render a responsive grid of stats
statGrid :: Array StatItem -> Html
statGrid items =
  el "div" [ class_ "grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4" ]
    (map statCard items)
