-- | CTA section — call to action
module App.Features.Home.Components.CTA where

import App.Html (Html, class_, el, text)
import App.Ui.Button (buttonLink, Variant(..), Size(..))
import App.Ui.Container (container)
import Data.I18n (Lang, dict)
import Data.Route (Route(..))

renderCTA :: Lang -> Html
renderCTA lang =
  let
    d = (dict lang).cta
  in
    el "section" [ class_ "py-12 sm:py-16 lg:py-20" ]
      [ container "max-w-7xl" ""
          [ el "div" [ class_ "bg-gray-900 px-6 py-12 text-center rounded-2xl sm:px-16 sm:py-16 dark:bg-gray-900 ring-1 ring-white/10 shadow-xs" ]
              [ el "h2" [ class_ "font-display text-3xl font-extrabold tracking-tight text-white sm:text-4xl leading-tight" ]
                  [ text d.heading ]
              , el "p" [ class_ "mx-auto mt-4 max-w-xl text-base sm:text-lg text-gray-300 font-normal leading-relaxed" ]
                  [ text d.body ]
              , el "div" [ class_ "mt-8 flex justify-center" ]
                  [ buttonLink { variant: Inverted, size: Lg, lang, route: About, extraClass: "" } d.ctaLabel ]
              ]
          ]
      ]

