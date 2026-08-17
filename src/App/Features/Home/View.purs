-- | Home page view — clean, mature functional web framework presentation
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
          { eyebrow: Nothing
          , title: d.hero.headline
          , body: d.hero.body
          , primaryAction: { label: d.hero.ctaLabel, target: Ui.Internal { lang, route: About } }
          , secondaryAction: Just { label: "GitHub Repository →", target: Ui.External { href: bookingUrl } }
          }

      -- Architectural Foundation
      , el "section" [ class_ "py-16 bg-base-200/50 border-b border-base-300" ]
          [ container "max-w-5xl" ""
              [ Ui.grid3
                  [ renderInvariantCard "Type Totality" "PureScript ADTs and exhaustive pattern matching guarantee that runtime exceptions are eliminated at compile time."
                  , renderInvariantCard "Bun Runtime" "Native Bun server implementation rendering sub-millisecond SSR responses with zero Node.js runtime overhead."
                  , renderInvariantCard "Alpine Interactivity" "Lightweight client-side interactivity delivered through typed, verified constructors without custom JavaScript."
                  ]
              ]
          ]

      -- Features / Capabilities Section
      , el "section" [ class_ "py-16 sm:py-24 border-b border-base-300" ]
          [ container "max-w-5xl" "space-y-10"
              [ Ui.pageHeader
                  { category: Nothing
                  , title: d.services.sectionTitle
                  , subtitle: Nothing
                  }
              , Ui.grid3 (map (renderServiceActionCard lang) services)
              ]
          ]

      -- Quickstart Code Strip
      , el "section" [ class_ "py-12 bg-base-200 border-b border-base-300" ]
          [ container "max-w-5xl" "flex flex-col md:flex-row items-center justify-between gap-6"
              [ el "div" [ class_ "space-y-1 text-center md:text-left" ]
                  [ el "p" [ class_ "text-sm font-semibold text-base-content" ] [ text "Getting Started" ]
                  , el "p" [ class_ "text-xs text-base-content/70" ] [ text "Clone the starter repository and run the local development server." ]
                  ]
              , el "div" [ class_ "mockup-code bg-neutral text-neutral-content text-xs font-mono py-3 px-4 shadow-md w-full md:w-auto" ]
                  [ el "pre" [ class_ "text-success select-all" ]
                      [ el "code" [] [ text "git clone https://github.com/icarofr/pohjola-framework.git my-app" ] ]
                  ]
              ]
          ]

      -- CTA Section
      , Ui.conversionCta
          { heading: d.cta.heading
          , body: d.cta.body
          , action: { label: d.cta.ctaLabel, target: Ui.Internal { lang, route: About } }
          }
      ]

renderInvariantCard :: String -> String -> Html
renderInvariantCard title desc =
  el "div" [ class_ "card bg-base-100 shadow-md border border-base-200" ]
    [ el "div" [ class_ "card-body p-6 space-y-2" ]
        [ el "h3" [ class_ "card-title text-base font-bold text-base-content" ] [ text title ]
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
      { tag: Nothing
      , imageUrl: Just { url: service.imageUrl, alt: copy.title, width: service.imageWidth, height: service.imageHeight }
      , title: copy.title
      , description: copy.description
      , action: { label: d.bookButton <> " →", target: Ui.External { href: bookingUrl } }
      }
