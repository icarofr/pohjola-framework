-- | About page sections
module App.Features.About.View where

import App.Alpine (xAutofocus)
import App.Html (Html, attr, class_, el, text)
import App.Ui.Container (container)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict)

renderAbout :: Lang -> Html
renderAbout lang =
  let
    d = (dict lang).about
    navDict = (dict lang).nav
  in
    container "max-w-4xl" "py-16 sm:py-24"
      [ container "max-w-2xl" "text-center"
          [ el "p" [ class_ "text-xs font-semibold uppercase tracking-wider text-indigo-600 dark:text-indigo-400" ]
              [ text navDict.about ]
          , el "h1" [ class_ "mt-2 font-display text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl dark:text-white", xAutofocus, attr "tabindex" "-1" ]
              [ text d.heading ]
          ]
      , el "div" [ class_ "mt-12 rounded-2xl bg-white p-8 sm:p-10 shadow-xs ring-1 ring-gray-200 dark:bg-gray-900/60 dark:ring-white/10 space-y-6" ]
          [ foldMap (\p -> el "p" [ class_ "text-base/8 text-gray-700 dark:text-gray-300 font-normal" ] [ text p ]) d.paragraphs ]
      ]
