-- | Rigid, responsive grid templates with full-height child matching
module App.Ui.Layout.Grid where

import Prelude

import App.Html (Html, class_, el)

-- | 3-Column responsive grid with standardized 24px/32px gap and stretch alignment
grid3 :: Array Html -> Html
grid3 items =
  el "div" [ class_ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 sm:gap-8 items-stretch" ] items

-- | 2-Column responsive grid
grid2 :: Array Html -> Html
grid2 items =
  el "div" [ class_ "grid grid-cols-1 md:grid-cols-2 gap-6 sm:gap-8 items-stretch" ] items

-- | 4-Column responsive grid for metrics/telemetry
grid4 :: Array Html -> Html
grid4 items =
  el "div" [ class_ "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 items-stretch" ] items
