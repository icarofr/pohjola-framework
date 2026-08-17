-- | Home page view — strictly assembled via rigid App.Ui component contracts
module App.Features.Home.View where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui as Ui
import App.Ui.Container (container)
import Data.Content (Service, bookingUrl, formatPrice, services)
import Data.I18n (Lang, dict, langTag)
import Data.Maybe (Maybe(..))
import Data.Route (Route(..))

renderHome :: Lang -> Html
renderHome lang =
  let
    d = dict lang
  in
    el "div" [ class_ "flex flex-col w-full" ]
      [ -- Hero Section
        Ui.hero
          { eyebrow: Just "POHJOLA FRAMEWORK 2026"
          , title: d.hero.headline
          , body: d.hero.body
          , primaryAction: { label: d.hero.ctaLabel, target: Ui.Internal { lang, route: About } }
          , secondaryAction: Just { label: "GitHub Repository →", target: Ui.External { href: bookingUrl } }
          }

      -- Invariant Guarantees Strip
      , el "section" [ class_ "py-16 sm:py-20 border-b border-zinc-200 dark:border-zinc-800 bg-zinc-50 dark:bg-zinc-900/30" ]
          [ container "max-w-5xl" ""
              [ Ui.grid3
                  [ renderInvariantBlock "01 // TOTALITY" "Zero Runtime Errors" "Exhaustive type-level guarantees with PureScript ADTs. Every failure path is explicitly handled in the compiler."
                  , renderInvariantBlock "02 // NATIVE BUN" "Sub-millisecond SSR" "High-speed server rendering executed directly on Bun.serve with zero Node.js overhead and instant restarts."
                  , renderInvariantBlock "03 // ISOMORPHIC" "Alpine Interactivity" "Zero custom JavaScript build steps. Interactivity is delivered through verified, typed Alpine.js seams."
                  ]
              ]
          ]

      -- Features / Capabilities Section
      , el "section" [ class_ "py-20 sm:py-28 border-b border-zinc-200 dark:border-zinc-800" ]
          [ container "max-w-5xl" "space-y-12"
              [ Ui.pageHeader
                  { category: Just "CORE MODULES"
                  , title: d.services.sectionTitle
                  , subtitle: Nothing
                  }
              , Ui.grid3 (map (renderServiceActionCard lang) services)
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
      , Ui.conversionCta
          { heading: d.cta.heading
          , body: d.cta.body
          , action: { label: d.cta.ctaLabel, target: Ui.Internal { lang, route: About } }
          }
      ]

renderInvariantBlock :: String -> String -> String -> Html
renderInvariantBlock tag title desc =
  el "div" [ class_ "space-y-2 p-6 rounded-lg bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 shadow-2xs" ]
    [ el "span" [ class_ "text-xs font-mono font-bold text-emerald-700 dark:text-emerald-400" ] [ text tag ]
    , el "h3" [ class_ "font-display text-lg font-bold text-zinc-950 dark:text-white" ] [ text title ]
    , el "p" [ class_ "text-sm text-zinc-600 dark:text-zinc-400 leading-relaxed font-normal" ] [ text desc ]
    ]

renderServiceActionCard :: Lang -> Service -> Html
renderServiceActionCard lang service =
  let
    d = (dict lang).services
    copy = d.serviceCopy service.id
  in
    Ui.actionCard
      { tag: Just { text: formatPrice (langTag lang) service.price, variant: Ui.BadgeSecondary }
      , imageUrl: Just { url: service.imageUrl, alt: copy.title, width: service.imageWidth, height: service.imageHeight }
      , title: copy.title
      , description: copy.description
      , action: { label: d.bookButton <> " →", target: Ui.External { href: bookingUrl } }
      }
