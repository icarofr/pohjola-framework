-- | DaisyUI container + width constraint (Daisy has no max-w primitive).
module App.Ui.Container where

import Prelude

import App.Html (Html, class_, el)

container :: String -> String -> Array Html -> Html
container maxW extra children =
  el "div" [ class_ ("container mx-auto px-4 " <> maxW <> " " <> extra) ] children
