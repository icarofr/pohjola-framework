-- | CTA section — call to action
module App.Features.Home.Components.CTA where

import App.Html (Html, attr, class_, el, text)
import App.Ui.Button (buttonLink, Variant(..), Size(..))
import App.Ui.Container (container)
import Data.I18n (Lang, dict)
import Data.Route (Route(..))

renderCTA :: Lang -> Html
renderCTA lang =
  let
    d = (dict lang).cta
  in
    el "section" [ class_ "py-8 sm:py-12 lg:py-14" ]
      [ container "max-w-7xl" ""
          [ el "div" [ class_ "relative isolate overflow-hidden bg-gray-900 px-6 py-10 text-center shadow-xl rounded-3xl sm:px-16 sm:py-12 dark:bg-gray-900 dark:ring-1 dark:ring-white/10" ]
              [ -- Ambient decorative glow
                el "div"
                  [ class_ "absolute -top-24 left-1/2 -z-10 -translate-x-1/2 transform-gpu blur-3xl pointer-events-none"
                  , attr "aria-hidden" "true"
                  ]
                  [ el "div" [ class_ "aspect-577/310 w-[36.0625rem] bg-gradient-to-r from-emerald-500 to-teal-700 opacity-30" ] [] ]
              , el "h2" [ class_ "font-display text-3xl font-bold tracking-tight text-white sm:text-4xl" ]
                  [ text d.heading ]
              , el "p" [ class_ "mx-auto mt-4 max-w-xl text-lg/8 text-gray-300 font-normal" ]
                  [ text d.body ]
              , el "div" [ class_ "mt-8 flex justify-center" ]
                  [ buttonLink { variant: Inverted, size: Lg, lang, route: About, extraClass: "" } d.ctaLabel ]
              ]
          ]
      ]
