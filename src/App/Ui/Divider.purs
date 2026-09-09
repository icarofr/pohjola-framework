-- | DaisyUI divider — vendor/daisyui/skills/daisyui/components/divider.md
module App.Ui.Divider (divider) where

import App.Html (Html, class_, el)

divider :: Html
divider = el "div" [ class_ "divider" ] []
