-- | Stat primitive — Telemetry metric card conforming to DESIGN.md
module App.Ui.Stat where

import Prelude

import App.Html (Html, class_, el, text)
import Data.Maybe (Maybe(..))

type StatItem =
  { label :: String
  , value :: String
  , description :: Maybe String
  }

-- | Render a single telemetry metric block
statCard :: StatItem -> Html
statCard item =
  el "div" [ class_ "stat p-6 bg-white dark:bg-zinc-900 border border-zinc-200/90 dark:border-zinc-800 rounded-lg shadow-2xs" ]
    [ el "div" [ class_ "stat-title text-xs font-mono font-medium uppercase tracking-widest text-zinc-500 dark:text-zinc-400" ] [ text item.label ]
    , el "div" [ class_ "stat-value mt-2 text-3xl font-extrabold tracking-tight font-display text-zinc-900 dark:text-white" ] [ text item.value ]
    , case item.description of
        Just desc -> el "div" [ class_ "stat-desc mt-2 text-xs text-zinc-500 dark:text-zinc-400 font-mono" ] [ text desc ]
        Nothing -> text ""
    ]

-- | Render a responsive grid of stats with hairline separators
statGrid :: Array StatItem -> Html
statGrid items =
  el "div" [ class_ "grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4" ]
    (map statCard items)
