-- | DaisyUI alert — vendor/daisyui/skills/daisyui/components/alert.md
module App.Ui.Alert
  ( AlertVariant(..)
  , alert
  ) where

import Prelude

import App.Html (Html, attr, class_, el, text)

data AlertVariant = AlertInfo | AlertSuccess | AlertWarning | AlertError

alert :: AlertVariant -> String -> Html
alert variant msg =
  el "div"
    [ attr "role" "alert"
    , class_ ("alert " <> color)
    ]
    [ text msg ]
  where
  color = case variant of
    AlertInfo -> "alert-info"
    AlertSuccess -> "alert-success"
    AlertWarning -> "alert-warning"
    AlertError -> "alert-error"
