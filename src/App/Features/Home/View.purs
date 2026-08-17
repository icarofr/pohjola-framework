-- | Home page view — completely rebuilt using pure DaisyUI component contracts
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
      , el "section" [ class_ "py-16 bg-base-200/50 border-b border-base-300" ]
          [ container "max-w-5xl" ""
              [ Ui.grid3
                  [ renderInvariantCard "01 // TOTALITY" "Zero Runtime Errors" "Exhaustive type-level guarantees with PureScript ADTs. Every failure path is explicitly handled in the compiler."
                  , renderInvariantCard "02 // NATIVE BUN" "Sub-millisecond SSR" "High-speed server rendering executed directly on Bun.serve with zero Node.js overhead and instant restarts."
                  , renderInvariantCard "03 // ISOMORPHIC" "Alpine Interactivity" "Zero custom JavaScript build steps. Interactivity is delivered through verified, typed Alpine.js seams."
                  ]
              ]
          ]

      -- Features / Capabilities Section
      , el "section" [ class_ "py-16 sm:py-24 border-b border-base-300" ]
          [ container "max-w-5xl" "space-y-10"
              [ Ui.pageHeader
                  { category: Just "CORE MODULES"
                  , title: d.services.sectionTitle
                  , subtitle: Nothing
                  }
              , Ui.grid3 (map (renderServiceActionCard lang) services)
              ]
          ]

      -- Quickstart Code Strip (DaisyUI Mockup Code)
      , el "section" [ class_ "py-12 bg-base-200 border-b border-base-300" ]
          [ container "max-w-5xl" "flex flex-col md:flex-row items-center justify-between gap-6"
              [ el "div" [ class_ "space-y-1 text-center md:text-left" ]
                  [ el "p" [ class_ "text-sm font-bold text-base-content font-mono" ] [ text "QUICKSTART TEMPLATE" ]
                  , el "p" [ class_ "text-xs text-base-content/70 font-mono" ] [ text "Scaffold a production-ready Pohjola application in seconds." ]
                  ]
              , el "div" [ class_ "mockup-code bg-neutral text-neutral-content text-xs font-mono py-3 px-4 shadow-md w-full md:w-auto" ]
                  [ el "pre" [ class_ "text-success select-all" ]
                      [ el "code" [] [ text "$ git clone https://github.com/icarofr/pohjola-framework.git my-app" ] ]
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

renderInvariantCard :: String -> String -> String -> Html
renderInvariantCard tag title desc =
  el "div" [ class_ "card bg-base-100 shadow-md border border-base-200" ]
    [ el "div" [ class_ "card-body p-6 space-y-2" ]
        [ el "span" [ class_ "badge badge-sm badge-primary font-mono" ] [ text tag ]
        , el "h3" [ class_ "card-title text-base font-bold text-base-content" ] [ text title ]
        , el "p" [ class_ "text-sm text-base-content/75 leading-relaxed font-normal" ] [ text desc ]
        ]
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
