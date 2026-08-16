-- | Toast / Notification Flash component (ADR-000, ADR-008)
-- |
-- | Auto-dismissing flash notifications driven by typed Alpine constructors.
module App.Ui.Toast
  ( ToastProps
  , renderToast
  ) where

import Prelude

import App.Alpine (Flag(..), onClick, setFlag, xCloak, xDataFlag, xShowFlag)
import App.Html (Html, ariaLabel, attr, class_, el, text, type_)

type ToastProps =
  { id :: String
  , message :: String
  , isSuccess :: Boolean
  }

-- | Render a self-dismissing toast notification.
renderToast :: ToastProps -> Html
renderToast props =
  let
    colorClasses =
      if props.isSuccess then
        "bg-emerald-50 text-emerald-900 border-emerald-200 dark:bg-emerald-950/80 dark:text-emerald-200 dark:border-emerald-800/50"
      else
        "bg-red-50 text-red-900 border-red-200 dark:bg-red-950/80 dark:text-red-200 dark:border-red-800/50"
  in
    el "div"
      [ xDataFlag ToastVisible true
      , xShowFlag ToastVisible
      , xCloak
      , class_ ("flex items-center justify-between gap-3 rounded-xl border p-4 shadow-lg text-sm " <> colorClasses)
      , attr "role" "status"
      ]
      [ el "span" [ class_ "font-medium" ] [ text props.message ]
      , el "button"
          [ type_ "button"
          , class_ "rounded-lg p-1 text-current opacity-60 hover:opacity-100 hover:bg-black/5 dark:hover:bg-white/10 transition-opacity cursor-pointer"
          , onClick (setFlag ToastVisible false)
          , ariaLabel "Dismiss notification"
          ]
          [ text "✕" ]
      ]
