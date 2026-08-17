-- | Home page view — completely rebuilt from scratch
module App.Features.Home.View where

import Prelude

import App.Html (Html, alt, class_, decoding_, el, height_, href, loading_, rel_, src, target_, text, width_)
import App.Ui.Button (buttonLink, buttonLinkExternal, Variant(..), Size(..))
import App.Ui.Container (container)
import Data.Content (Service, bookingUrl, formatPrice, services)
import Data.Foldable (foldMap)
import Data.I18n (Lang, dict, langTag)
import Data.Route (Route(..))

renderHome :: Lang -> Html
renderHome lang =
  let
    d = dict lang
  in
    el "div" [ class_ "flex flex-col w-full" ]
      [ -- Hero Section
        el "section" [ class_ "py-20 sm:py-28 lg:py-36 border-b border-zinc-200 dark:border-zinc-800" ]
          [ container "max-w-5xl" "space-y-8"
              [ el "div" [ class_ "inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-emerald-50 text-emerald-800 border border-emerald-200 dark:bg-emerald-950/60 dark:text-emerald-300 dark:border-emerald-800" ]
                  [ el "span" [ class_ "size-2 rounded-full bg-emerald-500 inline-block animate-pulse" ] []
                  , text "POHJOLA FRAMEWORK 2026"
                  ]
              , el "h1" [ class_ "font-display text-5xl sm:text-7xl lg:text-8xl font-black tracking-tight text-zinc-950 dark:text-white leading-[1.05]" ]
                  [ text d.hero.headline ]
              , el "p" [ class_ "text-xl sm:text-2xl text-zinc-600 dark:text-zinc-300 max-w-3xl font-normal leading-relaxed" ]
                  [ text d.hero.body ]
              , el "div" [ class_ "flex flex-wrap items-center gap-4 pt-4" ]
                  [ buttonLink { variant: Primary, size: Lg, lang, route: About, extraClass: "px-6 py-3 text-base" } d.hero.ctaLabel
                  , buttonLinkExternal { variant: Outline, size: Lg, href: bookingUrl, extraClass: "px-6 py-3 text-base" } "GitHub Repository →"
                  ]
              ]
          ]

      -- Invariant Guarantees Strip
      , el "section" [ class_ "py-16 sm:py-20 border-b border-zinc-200 dark:border-zinc-800 bg-zinc-50 dark:bg-zinc-900/30" ]
          [ container "max-w-5xl" ""
              [ el "div" [ class_ "grid grid-cols-1 md:grid-cols-3 gap-8" ]
                  [ el "div" [ class_ "space-y-2" ]
                      [ el "span" [ class_ "text-xs font-mono font-bold text-emerald-700 dark:text-emerald-400" ] [ text "01 // TOTALITY" ]
                      , el "h3" [ class_ "font-display text-lg font-bold text-zinc-950 dark:text-white" ] [ text "Zero Runtime Errors" ]
                      , el "p" [ class_ "text-sm text-zinc-600 dark:text-zinc-400 leading-relaxed" ] [ text "Exhaustive type-level guarantees with PureScript ADTs. Every failure path is explicitly handled in the compiler." ]
                      ]
                  , el "div" [ class_ "space-y-2" ]
                      [ el "span" [ class_ "text-xs font-mono font-bold text-teal-700 dark:text-teal-400" ] [ text "02 // NATIVE BUN" ]
                      , el "h3" [ class_ "font-display text-lg font-bold text-zinc-950 dark:text-white" ] [ text "Sub-millisecond SSR" ]
                      , el "p" [ class_ "text-sm text-zinc-600 dark:text-zinc-400 leading-relaxed" ] [ text "High-speed server rendering executed directly on Bun.serve with zero Node.js overhead and instant restarts." ]
                      ]
                  , el "div" [ class_ "space-y-2" ]
                      [ el "span" [ class_ "text-xs font-mono font-bold text-zinc-700 dark:text-zinc-400" ] [ text "03 // ISOMORPHIC" ]
                      , el "h3" [ class_ "font-display text-lg font-bold text-zinc-950 dark:text-white" ] [ text "Alpine Interactivity" ]
                      , el "p" [ class_ "text-sm text-zinc-600 dark:text-zinc-400 leading-relaxed" ] [ text "Zero custom JavaScript build steps. Interactivity is delivered through verified, typed Alpine.js seams." ]
                      ]
                  ]
              ]
          ]

      -- Features / Capabilities Section
      , el "section" [ class_ "py-20 sm:py-28 border-b border-zinc-200 dark:border-zinc-800" ]
          [ container "max-w-5xl" "space-y-12"
              [ el "div" [ class_ "space-y-3" ]
                  [ el "span" [ class_ "text-xs font-mono font-bold uppercase tracking-widest text-zinc-500 dark:text-zinc-400" ] [ text "CORE MODULES" ]
                  , el "h2" [ class_ "font-display text-3xl sm:text-4xl font-extrabold tracking-tight text-zinc-950 dark:text-white" ]
                      [ text d.services.sectionTitle ]
                  ]
              , el "div" [ class_ "grid grid-cols-1 md:grid-cols-3 gap-8" ]
                  (map (renderHomeServiceCard lang) services)
              ]
          ]

      -- Quickstart Code Strip
      , el "section" [ class_ "py-16 border-b border-zinc-200 dark:border-zinc-800 bg-zinc-950 text-white" ]
          [ container "max-w-5xl" "flex flex-col sm:flex-row items-center justify-between gap-6"
              [ el "div" [ class_ "space-y-1 text-center sm:text-left" ]
                  [ el "p" [ class_ "text-sm font-bold text-zinc-100 font-mono" ] [ text "QUICKSTART TEMPLATE" ]
                  , el "p" [ class_ "text-xs text-zinc-400 font-mono" ] [ text "Scaffold a new production-ready Pohjola application in seconds." ]
                  ]
              , el "div" [ class_ "inline-flex items-center gap-3 bg-zinc-900 border border-zinc-800 px-4 py-2.5 rounded-md font-mono text-xs text-zinc-200" ]
                  [ el "span" [ class_ "text-emerald-400 font-bold select-none" ] [ text "$" ]
                  , el "span" [ class_ "select-all" ] [ text "git clone https://github.com/icarofr/pohjola-framework.git my-app" ]
                  ]
              ]
          ]

      -- CTA Conversion Section
      , el "section" [ class_ "py-24 sm:py-32 bg-zinc-900 text-white" ]
          [ container "max-w-4xl" "text-center space-y-6"
              [ el "h2" [ class_ "font-display text-3xl sm:text-5xl font-extrabold tracking-tight text-white" ]
                  [ text d.cta.heading ]
              , el "p" [ class_ "text-lg text-zinc-400 max-w-xl mx-auto font-normal leading-relaxed" ]
                  [ text d.cta.body ]
              , el "div" [ class_ "pt-4 flex justify-center" ]
                  [ buttonLink { variant: Inverted, size: Lg, lang, route: About, extraClass: "px-8 py-3.5 text-base font-bold shadow-lg" } d.cta.ctaLabel ]
              ]
          ]
      ]

-- | Render a single service module card on the Home page
renderHomeServiceCard :: Lang -> Service -> Html
renderHomeServiceCard lang service =
  let
    d = (dict lang).services
    copy = d.serviceCopy service.id
  in
    el "div" [ class_ "flex flex-col justify-between p-6 rounded-lg bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 shadow-2xs space-y-6" ]
      [ el "div" [ class_ "space-y-4" ]
          [ el "div" [ class_ "aspect-16/10 overflow-hidden rounded-md bg-zinc-100 dark:bg-zinc-800 border border-zinc-200/80 dark:border-zinc-800" ]
              [ el "img"
                  [ class_ "h-full w-full object-cover"
                  , src service.imageUrl
                  , alt copy.title
                  , width_ service.imageWidth
                  , height_ service.imageHeight
                  , loading_ "lazy"
                  , decoding_ "async"
                  ]
                  []
              ]
          , el "h3" [ class_ "font-display text-lg font-bold text-zinc-950 dark:text-white" ] [ text copy.title ]
          , el "p" [ class_ "text-sm text-zinc-600 dark:text-zinc-400 leading-relaxed font-normal" ] [ text copy.description ]
          ]
      , el "div" [ class_ "pt-4 border-t border-zinc-100 dark:border-zinc-800 flex items-center justify-between" ]
          [ el "span" [ class_ "inline-flex px-2 py-0.5 rounded text-xs font-mono font-semibold bg-zinc-100 text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300" ]
              [ text (formatPrice (langTag lang) service.price) ]
          , el "a"
              [ href bookingUrl
              , target_ "_blank"
              , rel_ "noopener noreferrer"
              , class_ "text-xs font-semibold text-emerald-700 hover:text-emerald-800 dark:text-emerald-400 dark:hover:text-emerald-300 transition-colors"
              ]
              [ text (d.bookButton <> " →") ]
          ]
      ]
