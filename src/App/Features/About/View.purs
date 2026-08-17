-- | About page sections
module App.Features.About.View where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.Badge as Badge
import App.Ui.Card (card, cardBody)
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
      [ el "div" [ class_ "max-w-3xl mx-auto space-y-10" ]
          [ el "div" [ class_ "text-center max-w-2xl mx-auto" ]
              [ el "div" [ class_ "mb-4 flex justify-center" ]
                  [ Badge.badge Badge.Neutral navDict.about ]
              , el "h1" [ class_ "font-display text-4xl font-extrabold tracking-tight text-gray-900 sm:text-5xl dark:text-white leading-tight" ]
                  [ text d.heading ]
              ]
          , card $ cardBody
              ( el "div" [ class_ "space-y-6 text-base sm:text-lg leading-relaxed text-gray-700 dark:text-gray-300 font-normal" ]
                  (foldMap (\p -> [ el "p" [] [ text p ] ]) d.paragraphs)
              )
          ]
      ]

