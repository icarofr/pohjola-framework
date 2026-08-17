-- | Alert primitive — Status banners conforming to DESIGN.md
module App.Ui.Alert where

import Prelude

import App.Html (Html, attr, class_, el, text)

data Variant = Info | Success | Warning | Error

renderVariant :: Variant -> String
renderVariant = case _ of
  Info -> "bg-teal-50 border-teal-300 text-teal-900 dark:bg-teal-950/40 dark:border-teal-800 dark:text-teal-200"
  Success -> "bg-emerald-50 border-emerald-300 text-emerald-900 dark:bg-emerald-950/40 dark:border-emerald-800 dark:text-emerald-200"
  Warning -> "bg-amber-50 border-amber-300 text-amber-900 dark:bg-amber-950/40 dark:border-amber-800 dark:text-amber-200"
  Error -> "bg-red-50 border-red-300 text-red-900 dark:bg-red-950/40 dark:border-red-800 dark:text-red-200"

-- | Render an accessible alert banner
alert :: Variant -> String -> Html
alert variant message =
  el "div"
    [ attr "role" (if isError variant then "alert" else "status")
    , class_ ("p-4 rounded-md border text-sm font-medium shadow-2xs " <> renderVariant variant)
    ]
    [ text message ]
  where
  isError = case _ of
    Error -> true
    _ -> false
