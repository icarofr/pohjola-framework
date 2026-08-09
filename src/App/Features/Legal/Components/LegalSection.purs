-- | Legal section — presentational component for a numbered legal section.
module App.Features.Legal.Components.LegalSection where

import Prelude

import App.Html (Html, class_, el, text)
import Data.Foldable (foldMap)

renderLegalSection :: { number :: String, heading :: String, paragraphs :: Array String } -> Html
renderLegalSection section =
  el "section" [ class_ "space-y-3" ]
    [ el "h2" [ class_ "text-xl font-semibold text-slate-900 dark:text-white" ]
        [ text (section.number <> ". " <> section.heading) ]
    , foldMap (\p -> el "p" [ class_ "text-slate-600 dark:text-slate-300 leading-7" ] [ text p ]) section.paragraphs
    ]
