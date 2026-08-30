-- | DaisyUI typography — `prose` utility.
module App.Ui.Prose (prose, proseLg) where

import App.Html (Html, class_, el)

prose :: Array Html -> Html
prose = el "div" [ class_ "prose" ]

proseLg :: Array Html -> Html
proseLg = el "div" [ class_ "prose prose-lg" ]
