-- | Legal page — terms of service sections
module App.Features.Legal.View where

import Prelude

import App.Alpine (xAutofocus)
import App.Html (Html, attr, class_, el, text)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict)

renderLegal :: Lang -> Html
renderLegal lang =
  let
    d = (dict lang).legal
  in
    el "div" [ class_ "mx-auto max-w-3xl px-4 py-16 sm:px-6 lg:px-8" ]
      [ el "h1" [ class_ "font-display text-4xl font-bold text-slate-900 dark:text-white", xAutofocus, attr "tabindex" "-1" ]
          [ text d.title ]
      , el "p" [ class_ "mt-2 text-sm text-slate-500 dark:text-slate-400" ]
          [ text d.subtitle ]
      , el "p" [ class_ "mt-1 text-sm text-slate-500 dark:text-slate-400" ]
          [ text d.lastUpdated ]
      , el "div" [ class_ "mt-8 space-y-8" ]
          [ foldMap renderSection d.sections ]
      ]

renderSection :: { number :: String, heading :: String, paragraphs :: Array String } -> Html
renderSection section =
  el "section" [ class_ "space-y-3" ]
    [ el "h2" [ class_ "text-xl font-semibold text-slate-900 dark:text-white" ]
        [ text (section.number <> ". " <> section.heading) ]
    , foldMap (\p -> el "p" [ class_ "text-slate-600 dark:text-slate-300 leading-7" ] [ text p ]) section.paragraphs
    ]
