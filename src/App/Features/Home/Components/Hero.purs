-- | Hero section — headline + body + CTA
module App.Features.Home.Components.Hero where

import App.Html (Html, attr, class_, el, text)
import App.Ui.Badge as Badge
import App.Ui.Button (buttonLink, buttonLinkExternal, Variant(..), Size(..))
import App.Ui.Container (container)
import Data.Content (bookingUrl)
import Data.I18n (Lang, dict)
import Data.Route (Route(..))

renderHero :: Lang -> Html
renderHero lang =
  let
    d = dict lang
  in
    el "section" [ class_ "relative isolate pt-12 pb-16 sm:pt-16 sm:pb-20 lg:pt-20 lg:pb-24 border-b border-gray-200/80 dark:border-white/5" ]
      [ container "max-w-4xl" "text-center"
          [ -- Architecture Badge
            el "div" [ class_ "mb-6 flex justify-center" ]
              [ Badge.badge Badge.Tertiary "PureScript 0.15.16 • Bun • Alpine.js" ]
          , el "h1" [ class_ "font-display text-4xl font-extrabold tracking-tight text-gray-900 sm:text-6xl dark:text-white leading-[1.1]" ]
              [ text d.hero.headline ]
          , el "p" [ class_ "mt-6 text-lg sm:text-xl leading-relaxed text-gray-600 dark:text-gray-300 max-w-2xl mx-auto font-normal" ]
              [ text d.hero.body ]
          , el "div" [ class_ "mt-10 flex flex-wrap items-center justify-center gap-4" ]
              [ buttonLink { variant: Primary, size: Lg, lang, route: About, extraClass: "" } d.hero.ctaLabel
              , buttonLinkExternal { variant: Secondary, size: Lg, href: bookingUrl, extraClass: "" } "GitHub Repository →"
              ]
          , el "div" [ class_ "mt-10 flex justify-center" ]
              [ el "div" [ class_ "inline-flex items-center gap-x-3 rounded-lg bg-gray-900 px-4 py-2.5 text-xs sm:text-sm font-mono text-gray-200 ring-1 ring-white/10 dark:bg-gray-900 shadow-xs" ]
                  [ el "span" [ class_ "text-emerald-400 select-none font-bold" ] [ text "$" ]
                  , el "span" [] [ text "git clone https://github.com/icarofr/pohjola-framework.git" ]
                  ]
              ]
          ]
      ]
