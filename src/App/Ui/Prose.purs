-- | DaisyUI typography utility — see research/daisyui utilities/typography.css
module App.Ui.Prose (prose, proseLg) where

import App.Html (Html, class_, el)

-- | Theme-aware prose container for long-form copy
prose :: Array Html -> Html
prose children =
  el "div" [ class_ "prose max-w-none" ] children

-- | Editorial and article body — DaisyUI prose-lg recipe
proseLg :: Array Html -> Html
proseLg children =
  el "div" [ class_ "prose prose-lg max-w-none" ] children
