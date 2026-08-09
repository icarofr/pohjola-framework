-- | CTA section — call to action
module App.Features.Home.Components.CTA where

import App.Html (Html, class_, el, text)
import App.Ui.Button (buttonLink, Variant(..), Size(..))
import App.Ui.Container (container)
import Data.I18n (Lang, dict)
import Data.Route (Route(..), routeUrl)

renderCTA :: Lang -> Html
renderCTA lang =
  let
    d = (dict lang).cta
  in
    el "section" [ class_ "py-20 bg-slate-50 dark:bg-slate-900" ]
      [ container "max-w-3xl" "text-center"
          [ el "h2" [ class_ "font-display text-3xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-4xl" ]
              [ text d.heading ]
          , el "p" [ class_ "mt-4 text-lg leading-8 text-slate-600 dark:text-slate-300" ]
              [ text d.body ]
          , el "div" [ class_ "mt-6" ]
              [ buttonLink { variant: Primary, size: Lg, href: routeUrl lang Contact, extraClass: "shadow-lg" } d.ctaLabel ]
          ]
      ]
