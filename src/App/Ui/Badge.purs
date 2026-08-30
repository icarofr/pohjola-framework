-- | Badge primitive — DaisyUI semantic component classes
module App.Ui.Badge where

import Prelude

import App.Html (Html, class_, el, text)

data BadgeVariant = BadgePrimary | BadgeSecondary | BadgeTertiary | BadgeSuccess | BadgeWarning | BadgeError | BadgeNeutral
type Variant = BadgeVariant

data BadgeSize = BadgeXs | BadgeSm | BadgeMd

renderSize :: BadgeSize -> String
renderSize = case _ of
  BadgeXs -> "badge-xs"
  BadgeSm -> "badge-sm"
  BadgeMd -> ""

renderVariant :: BadgeVariant -> String
renderVariant = case _ of
  BadgePrimary -> "badge-primary"
  BadgeSecondary -> "badge-secondary"
  BadgeTertiary -> "badge-accent"
  BadgeSuccess -> "badge-success"
  BadgeWarning -> "badge-warning"
  BadgeError -> "badge-error"
  BadgeNeutral -> "badge-neutral"

-- | Render a DaisyUI badge (default size: sm)
badge :: BadgeVariant -> String -> Html
badge variant label =
  badgeSized BadgeSm variant label

badgeSized :: BadgeSize -> BadgeVariant -> String -> Html
badgeSized size variant label =
  el "span"
    [ class_ ("badge font-mono " <> renderSize size <> " " <> renderVariant variant) ]
    [ text label ]
