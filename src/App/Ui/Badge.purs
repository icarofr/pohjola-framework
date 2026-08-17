-- | Badge primitive — Semantic status indicators conforming to DESIGN.md
module App.Ui.Badge where

import Prelude

import App.Html (Html, class_, el, text)

data Variant = Primary | Secondary | Tertiary | Success | Warning | Error | Neutral

renderVariant :: Variant -> String
renderVariant = case _ of
  Primary -> "badge-primary"
  Secondary -> "badge-secondary"
  Tertiary -> "badge-accent"
  Success -> "badge-success"
  Warning -> "badge-warning"
  Error -> "badge-error"
  Neutral -> "badge-neutral"

-- | Render a semantic badge / pill
badge :: Variant -> String -> Html
badge variant label =
  el "span"
    [ class_ ("badge badge-sm font-medium " <> renderVariant variant) ]
    [ text label ]
