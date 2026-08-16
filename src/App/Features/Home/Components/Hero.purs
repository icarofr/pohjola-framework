-- | Hero section — headline + body + CTA
module App.Features.Home.Components.Hero where

import App.Alpine (xAutofocus)
import App.Html (Html, attr, class_, el, text)
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
    el "section" [ class_ "relative isolate overflow-hidden pt-8 pb-10 sm:pt-12 sm:pb-14 lg:pt-14 lg:pb-16" ]
      [ -- Subtle top radial glow
        el "div"
          [ class_ "absolute inset-x-0 -top-40 -z-10 transform-gpu overflow-hidden blur-3xl sm:-top-80 pointer-events-none"
          , attr "aria-hidden" "true"
          ]
          [ el "div"
              [ class_ "relative left-[calc(50%-11rem)] aspect-1155/678 w-[36.125rem] -translate-x-1/2 rotate-[30deg] bg-gradient-to-tr from-emerald-500 to-teal-300 opacity-15 sm:left-[calc(50%-30rem)] sm:w-[72.1875rem] dark:opacity-15"
              ]
              []
          ]
      , container "max-w-4xl" "text-center"
          [ -- Eyebrow pill
            el "div" [ class_ "mb-6 flex justify-center" ]
              [ el "div"
                  [ class_ "inline-flex items-center gap-x-2 rounded-full bg-gray-100/90 dark:bg-white/5 px-3.5 py-1 text-xs font-mono font-medium text-gray-800 dark:text-gray-200 ring-1 ring-inset ring-gray-300/60 dark:ring-white/10 shadow-2xs backdrop-blur-xs" ]
                  [ el "span" [ class_ "size-1.5 rounded-full bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.6)]" ] []
                  , text "PureScript • Bun • Alpine.js"
                  ]
              ]
          , el "h1" [ class_ "font-display text-4xl font-bold tracking-tight text-gray-900 sm:text-6xl dark:text-white sm:leading-[1.1] focus:outline-none", xAutofocus, attr "tabindex" "-1" ]
              [ text d.hero.headline ]
          , el "p" [ class_ "mt-6 text-lg/8 text-gray-600 dark:text-gray-300 max-w-2xl mx-auto font-normal" ]
              [ text d.hero.body ]
          , el "div" [ class_ "mt-8 flex flex-wrap items-center justify-center gap-4" ]
              [ buttonLink { variant: Primary, size: Lg, lang, route: About, extraClass: "" } d.hero.ctaLabel
              , buttonLinkExternal { variant: Secondary, size: Lg, href: bookingUrl, extraClass: "" } "GitHub →"
              ]
          , el "div" [ class_ "mt-8 flex justify-center" ]
              [ el "div" [ class_ "inline-flex items-center gap-x-3 rounded-lg bg-gray-900 px-4 py-2 text-xs sm:text-sm font-mono text-gray-200 shadow-md ring-1 ring-gray-900/10 dark:bg-gray-800 dark:ring-white/10" ]
                  [ el "span" [ class_ "text-emerald-400 select-none font-bold" ] [ text "$" ]
                  , el "span" [] [ text "git clone https://github.com/icarofr/pohjola-framework.git" ]
                  ]
              ]
          ]
      ]
