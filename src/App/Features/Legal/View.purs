-- | Legal page — page-level rendering, orchestrates Components/
module App.Features.Legal.View where

import App.Alpine (xAutofocus)
import App.Features.Legal.Components.LegalSection (renderLegalSection)
import App.Html (Html, attr, class_, el, text)
import App.Ui.Container (container)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict)

renderLegal :: Lang -> Html
renderLegal lang =
  let
    d = (dict lang).legal
  in
    container "max-w-3xl" "py-16"
      [ el "h1" [ class_ "font-display text-4xl font-bold text-slate-900 dark:text-white", xAutofocus, attr "tabindex" "-1" ]
          [ text d.title ]
      , el "p" [ class_ "mt-2 text-sm text-slate-500 dark:text-slate-400" ]
          [ text d.subtitle ]
      , el "p" [ class_ "mt-1 text-sm text-slate-500 dark:text-slate-400" ]
          [ text d.lastUpdated ]
      , el "div" [ class_ "mt-8 space-y-8" ]
          [ foldMap renderLegalSection d.sections ]
      ]
