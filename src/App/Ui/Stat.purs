-- | DaisyUI Stats primitive
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
    [ el "div" [ class_ "stat-title text-base-content/70 font-mono text-xs" ] [ text props.label ]
    , el "div" [ class_ "stat-value text-primary text-3xl font-black" ] [ text props.value ]
    , case props.description of
        Just desc -> el "div" [ class_ "stat-desc text-base-content/60 text-xs" ] [ text desc ]
        Nothing -> text ""
    ]

statGrid :: Array StatItem -> Html
statGrid items =
  el "div" [ class_ "stats stats-vertical lg:stats-horizontal shadow-md bg-base-100 border border-base-200 w-full" ]
    (map statCard items)
