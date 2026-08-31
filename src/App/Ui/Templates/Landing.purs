-- | Landing page — DaisyUI hero, card grid, primary CTA band.
module App.Ui.Templates.Landing
  ( renderLanding
  ) where

import Prelude

import App.Html (Html, attr, class_, el, text)
import App.Ui.Badge as Badge
import App.Ui.Button as Button
import App.Ui.Button (Size(..))
import App.Ui.Card as Card
import App.Ui.Container as Container
import App.Ui.Templates.ActionLink as ActionLink
import App.Ui.Templates.Contract as Contract
import App.Ui.Templates.Types
  ( LandingCtaSlots
  , LandingFeatureSlots
  , LandingHeroSlots
  , LandingSlots
  , ServiceFeature
  , featureItems
  )

renderLanding :: LandingSlots -> Html
renderLanding slots =
  renderHero slots.hero
    <> renderFeatureSection slots.features
    <> renderFinalCta slots.cta

renderHero :: LandingHeroSlots -> Html
renderHero hero =
  el "section"
    [ class_ "hero min-h-[28rem] bg-base-200"
    , attr Contract.marker Contract.landingHero
    ]
    [ el "div" [ class_ "hero-content text-center" ]
        [ el "div" [ class_ "max-w-3xl" ]
            [ Badge.badge Badge.BadgeNeutral hero.eyebrow
            , el "h1" [ class_ "mt-6 text-4xl font-bold tracking-tight sm:text-5xl" ]
                [ text hero.headline ]
            , el "p" [ class_ "mt-6 text-lg opacity-80" ] [ text hero.body ]
            , el "div" [ class_ "mt-10 flex flex-wrap justify-center gap-3" ]
                [ ActionLink.actionTarget Button.ButtonPrimary Md hero.primaryTarget hero.ctaLabel
                , ActionLink.actionTarget Button.ButtonOutline Md hero.secondaryTarget hero.secondaryLabel
                ]
            ]
        ]
    ]

renderFeatureSection :: LandingFeatureSlots -> Html
renderFeatureSection section =
  el "section"
    [ class_ "py-16 sm:py-20"
    , attr Contract.marker Contract.landingFeatures
    ]
    [ Container.container "max-w-6xl" "px-4 sm:px-6"
        [ el "div" [ class_ "mx-auto max-w-2xl text-center" ]
            [ Badge.badge Badge.BadgePrimary section.eyebrow
            , el "h2" [ class_ "mt-4 text-3xl font-bold sm:text-4xl" ]
                [ text section.headline ]
            , el "p" [ class_ "mt-4 opacity-70" ] [ text section.body ]
            ]
        , el "div" [ class_ "mt-12 grid gap-6 md:grid-cols-3" ]
            (map renderFeatureItem (featureItems section.items))
        ]
    ]

renderFeatureItem :: ServiceFeature -> Html
renderFeatureItem feature =
  el "div" [ attr Contract.marker Contract.landingFeatureItem ]
    [ Card.card Card.defaultCardOptions
        [ Card.cardBody
            [ Card.cardTitle feature.title
            , Card.cardText feature.description
            ]
        ]
    ]

renderFinalCta :: LandingCtaSlots -> Html
renderFinalCta cta =
  el "section"
    [ class_ "bg-primary text-primary-content"
    , attr Contract.marker Contract.landingCta
    ]
    [ Container.container "max-w-3xl" "px-4 py-16 text-center sm:px-6"
        [ el "h2" [ class_ "text-3xl font-bold sm:text-4xl" ] [ text cta.heading ]
        , el "p" [ class_ "mt-4 opacity-80" ] [ text cta.body ]
        , el "div" [ class_ "mt-8" ]
            [ ActionLink.actionTarget Button.ButtonOutline Md cta.target cta.ctaLabel ]
        ]
    ]
