-- | DaisyUI Stats primitive (research/daisyui stat docs)
module App.Ui.Stat where

import Prelude

import App.Html (Html, class_, el, text)
import Data.Maybe (Maybe(..))

type StatItem =
  { label :: String
  , value :: String
  , description :: Maybe String
  }

statCard :: StatItem -> Html
statCard props =
  el "div" [ class_ "stat" ]
    [ el "div" [ class_ "stat-title" ] [ text props.label ]
    , el "div" [ class_ "stat-value text-primary" ] [ text props.value ]
    , case props.description of
        Just desc -> el "div" [ class_ "stat-desc" ] [ text desc ]
        Nothing -> text ""
    ]

statGrid :: Array StatItem -> Html
statGrid items =
  el "div" [ class_ "stats stats-vertical bg-base-100 lg:stats-horizontal w-full" ]
    (map statCard items)
