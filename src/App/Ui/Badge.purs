-- | Badge primitive — DaisyUI semantic component classes
module App.Ui.Badge where

import Prelude

import App.Html (Html, class_, el, text)

data BadgeVariant = BadgePrimary | BadgeSecondary | BadgeTertiary | BadgeSuccess | BadgeWarning | BadgeError | BadgeNeutral
type Variant = BadgeVariant

renderVariant :: BadgeVariant -> String
renderVariant = case _ of
  BadgePrimary -> "badge-primary"
  BadgeSecondary -> "badge-secondary"
  BadgeTertiary -> "badge-accent"
  BadgeSuccess -> "badge-success"
  BadgeWarning -> "badge-warning"
  BadgeError -> "badge-error"
  BadgeNeutral -> "badge-neutral"

-- | Render a semantic monospace tag / badge
badge :: BadgeVariant -> String -> Html
badge variant label =
  el "span"
    [ class_ ("badge badge-sm font-mono " <> renderVariant variant) ]
    [ text label ]
