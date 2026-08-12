-- | Hero section — headline + body + CTA
module App.Features.Home.Components.Hero where

import App.Alpine (xAutofocus)
import App.Html (Html, attr, class_, el, text)
import App.Ui.Button (buttonLink, Variant(..), Size(..))
import App.Ui.Container (container)
import Data.I18n (Lang, dict)
import Data.Route (Route(..))

renderHero :: Lang -> Html
renderHero lang =
  let
    d = (dict lang).hero
  in
    el "section" [ class_ "relative overflow-hidden bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-slate-900 dark:to-slate-800" ]
      [ container "max-w-7xl" "py-20 lg:py-28"
          [ container "max-w-3xl" "text-center"
              [ el "h1" [ class_ "font-display text-4xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-5xl lg:text-6xl", xAutofocus, attr "tabindex" "-1" ]
                  [ text d.headline ]
              , el "p" [ class_ "mt-6 text-lg leading-8 text-slate-600 dark:text-slate-300" ]
                  [ text d.body ]
              , el "div" [ class_ "mt-10 flex items-center justify-center gap-x-6" ]
                  [ buttonLink { variant: Primary, size: Lg, lang, route: About, extraClass: "" } d.ctaLabel ]
              ]
          ]
      ]
