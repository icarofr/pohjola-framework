-- | Alert primitive — Structured feedback notices conforming to DESIGN.md and ARIA
module App.Ui.Alert where

import Prelude

import App.Html (Html, attr, class_, el, text)

data Variant = Info | Success | Warning | Error

derive instance Eq Variant

renderVariant :: Variant -> String
renderVariant = case _ of
  Info -> "alert-info"
  Success -> "alert-success"
  Warning -> "alert-warning"
  Error -> "alert-error"

-- | Render an accessible alert box
alert :: Variant -> String -> Html
alert variant message =
  el "div"
    [ attr "role" (if variant == Error then "alert" else "status")
    , attr "aria-live" "polite"
    , class_ ("alert " <> renderVariant variant <> " shadow-xs")
    ]
    [ text message ]

