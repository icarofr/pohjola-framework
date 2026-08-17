-- | CTA section — call to action
module App.Features.Home.Components.CTA where

import App.Html (Html, class_, el, text)
import App.Ui.Badge as Badge
import App.Ui.Button (buttonLink, Variant(..), Size(..))
import App.Ui.Container (container)
import Data.I18n (Lang, dict)
import Data.Route (Route(..))

renderCTA :: Lang -> Html
renderCTA lang =
  let
    d = (dict lang).cta
  in
    el "section" [ class_ "py-20 sm:py-28 bg-zinc-950 text-white border-b border-zinc-800" ]
      [ container "max-w-5xl" "text-center space-y-8"
          [ el "div" [ class_ "flex justify-center" ]
              [ Badge.badge Badge.Tertiary "START BUILDING TODAY" ]
          , el "h2" [ class_ "font-display text-4xl sm:text-5xl font-extrabold tracking-tight text-white leading-tight" ]
              [ text d.heading ]
          , el "p" [ class_ "mx-auto max-w-2xl text-lg sm:text-xl text-zinc-400 font-normal leading-relaxed" ]
              [ text d.body ]
          , el "div" [ class_ "flex justify-center pt-4" ]
              [ buttonLink { variant: Inverted, size: Lg, lang, route: About, extraClass: "px-8 py-3 text-base font-bold shadow-xl" } d.ctaLabel ]
          ]
      ]
