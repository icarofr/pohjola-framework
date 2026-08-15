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
    container "max-w-7xl" "py-12 sm:py-16 lg:py-20"
      [ el "div" [ class_ "max-w-3xl mx-auto space-y-12" ]
          [ el "div" [ class_ "text-center max-w-2xl mx-auto" ]
              [ el "p" [ class_ "text-xs font-mono font-semibold uppercase tracking-widest text-emerald-700 dark:text-emerald-400" ]
                  [ text navDict.about ]
              , el "h1" [ class_ "mt-2 font-display text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl dark:text-white", xAutofocus, attr "tabindex" "-1" ]
                  [ text d.heading ]
              ]
          , el "div" [ class_ "rounded-2xl bg-white p-8 sm:p-10 shadow-xs ring-1 ring-gray-200 dark:bg-gray-900/60 dark:ring-white/10 space-y-6" ]
              [ foldMap (\p -> el "p" [ class_ "text-base/8 text-gray-700 dark:text-gray-300 font-normal" ] [ text p ]) d.paragraphs ]
          ]
      ]
