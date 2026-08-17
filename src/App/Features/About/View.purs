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
    container "max-w-4xl" "py-16 sm:py-24 space-y-12"
      [ -- Page Header
        el "div" [ class_ "space-y-4" ]
          [ el "div" [ class_ "flex items-center gap-2" ]
              [ Badge.badge Badge.Primary navDict.about
              , Badge.badge Badge.Neutral "MANIFESTO"
              ]
          , el "h1" [ class_ "font-display text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight text-zinc-950 dark:text-white leading-[1.1]" ]
              [ text d.heading ]
          ]
      -- Main Content Container
      , card $ cardBody
          ( el "div" [ class_ "space-y-6 text-base sm:text-lg leading-relaxed text-zinc-700 dark:text-zinc-300 font-normal" ]
              (foldMap (\p -> [ el "p" [] [ text p ] ]) d.paragraphs)
          )
      ]
