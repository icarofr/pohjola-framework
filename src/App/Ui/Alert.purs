-- | Alert primitive — DaisyUI semantic component classes
module App.Ui.Alert where

import Prelude

import App.Html (Html, attr, class_, el, text)

data AlertVariant = AlertInfo | AlertSuccess | AlertWarning | AlertError
type Variant = AlertVariant

renderVariant :: AlertVariant -> String
renderVariant = case _ of
  AlertInfo -> "alert-info"
  AlertSuccess -> "alert-success"
  AlertWarning -> "alert-warning"
  AlertError -> "alert-error"

-- | Render an accessible alert banner
alert :: AlertVariant -> String -> Html
alert variant message =
  el "div"
    [ attr "role" (if isError variant then "alert" else "status")
    , class_ ("alert " <> renderVariant variant)
    ]
    [ text message ]
  where
  isError = case _ of
    AlertError -> true
    _ -> false
