-- | Badge primitive — Monospace status indicators conforming to DESIGN.md
module App.Ui.Badge where

import Prelude

import App.Html (Html, class_, el, text)

data BadgeVariant = BadgePrimary | BadgeSecondary | BadgeTertiary | BadgeSuccess | BadgeWarning | BadgeError | BadgeNeutral
type Variant = BadgeVariant

renderVariant :: BadgeVariant -> String
renderVariant = case _ of
  BadgePrimary -> "bg-emerald-50 text-emerald-800 border-emerald-300 dark:bg-emerald-950/60 dark:text-emerald-300 dark:border-emerald-800"
  BadgeSecondary -> "bg-zinc-100 text-zinc-800 border-zinc-300 dark:bg-zinc-800 dark:text-zinc-200 dark:border-zinc-700"
  BadgeTertiary -> "bg-teal-50 text-teal-800 border-teal-300 dark:bg-teal-950/60 dark:text-teal-300 dark:border-teal-800"
  BadgeSuccess -> "bg-emerald-50 text-emerald-800 border-emerald-300 dark:bg-emerald-950/60 dark:text-emerald-300 dark:border-emerald-800"
  BadgeWarning -> "bg-amber-50 text-amber-800 border-amber-300 dark:bg-amber-950/60 dark:text-amber-300 dark:border-amber-800"
  BadgeError -> "bg-red-50 text-red-800 border-red-300 dark:bg-red-950/60 dark:text-red-300 dark:border-red-800"
  BadgeNeutral -> "bg-zinc-100 text-zinc-700 border-zinc-200 dark:bg-zinc-800 dark:text-zinc-300 dark:border-zinc-700"

-- | Render a semantic monospace tag / badge
badge :: BadgeVariant -> String -> Html
badge variant label =
  el "span"
    [ class_ ("inline-flex items-center px-2 py-0.5 rounded-sm text-xs font-mono font-medium border " <> renderVariant variant) ]
    [ text label ]
