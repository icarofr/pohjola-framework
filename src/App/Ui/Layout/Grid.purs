-- | Responsive card grids — Tailwind inside App.Ui.Layout only
module App.Ui.Layout.Grid where

import App.Html (Html, class_, el)

grid3 :: Array Html -> Html
grid3 items =
  el "div" [ class_ "grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3" ] items

grid2 :: Array Html -> Html
grid2 items =
  el "div" [ class_ "grid grid-cols-1 gap-6 md:grid-cols-2" ] items

grid4 :: Array Html -> Html
grid4 items =
  el "div" [ class_ "grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4" ] items
