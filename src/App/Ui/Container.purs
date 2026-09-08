-- | DaisyUI container + width constraint (Daisy has no max-w primitive).
module App.Ui.Container
  ( ContainerWidth(..)
  , container
  ) where

import Prelude

import App.Html (Html, class_, el)

-- | The closed set of max-widths actually used across the template layer.
-- | A bare String here let a typo compile clean and render unstyled.
data ContainerWidth = ContainerW2xl | ContainerW3xl | ContainerW4xl | ContainerW6xl

widthClass :: ContainerWidth -> String
widthClass = case _ of
  ContainerW2xl -> "max-w-2xl"
  ContainerW3xl -> "max-w-3xl"
  ContainerW4xl -> "max-w-4xl"
  ContainerW6xl -> "max-w-6xl"

container :: ContainerWidth -> String -> Array Html -> Html
container maxW extra children =
  el "div" [ class_ ("container mx-auto px-4 " <> widthClass maxW <> " " <> extra) ] children
