-- | Standard DaisyUI container wrapper
module App.Ui.Container where

import Prelude

import App.Html (Html, class_, el)

container :: String -> String -> Array Html -> Html
container maxW extraClass children =
  el "div" [ class_ ("container mx-auto px-4 sm:px-6 lg:px-8 " <> maxW <> " " <> extraClass) ] children
