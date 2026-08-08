-- | About page sections
module App.Features.About.View where

import App.Alpine (xAutofocus)
import App.Html (Html, attr, class_, el, text)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict)

renderAbout :: Lang -> Html
renderAbout lang =
  let
    d = (dict lang).about
  in
    el "div" [ class_ "mx-auto max-w-3xl px-4 py-16 sm:px-6 lg:px-8" ]
      [ el "h1" [ class_ "font-display text-4xl font-bold text-slate-900 dark:text-white", xAutofocus, attr "tabindex" "-1" ]
          [ text d.heading ]
      , el "div" [ class_ "mt-8 space-y-6" ]
          [ foldMap (\p -> el "p" [ class_ "text-lg leading-8 text-slate-600 dark:text-slate-300" ] [ text p ]) d.paragraphs ]
      ]
