-- | DaisyUI divider — see node_modules/daisyui/components/divider.css
module App.Ui.Divider (divider) where

import App.Html (Html, class_, el)

divider :: Html
divider = el "div" [ class_ "divider" ] []
