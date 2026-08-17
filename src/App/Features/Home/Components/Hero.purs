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
    el "section" [ class_ "relative pt-16 pb-20 sm:pt-24 sm:pb-28 lg:pt-28 lg:pb-32 border-b border-zinc-200 dark:border-zinc-800 bg-linear-to-b from-white to-zinc-50/50 dark:from-zinc-950 dark:to-zinc-900/30" ]
      [ container "max-w-7xl" ""
          [ el "div" [ class_ "grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center" ]
              [ -- Left Column: Headline & Action
                el "div" [ class_ "lg:col-span-7 space-y-8" ]
                  [ el "div" [ class_ "flex items-center gap-2" ]
                      [ Badge.badge Badge.Primary "POHJOLA 2026"
                      , Badge.badge Badge.Neutral "PURE SCRIPT • BUN • ALPINE"
                      ]
                  , el "h1" [ class_ "font-display text-4xl sm:text-6xl lg:text-7xl font-extrabold tracking-tighter text-zinc-950 dark:text-white leading-[1.05]" ]
                      [ text d.hero.headline ]
                  , el "p" [ class_ "text-lg sm:text-xl text-zinc-600 dark:text-zinc-300 max-w-xl font-normal leading-relaxed" ]
                      [ text d.hero.body ]
                  , el "div" [ class_ "flex flex-wrap items-center gap-4 pt-2" ]
                      [ buttonLink { variant: Primary, size: Lg, lang, route: About, extraClass: "" } d.hero.ctaLabel
                      , buttonLinkExternal { variant: Outline, size: Lg, href: bookingUrl, extraClass: "" } "GitHub Core →"
                      ]
                  ]

              -- Right Column: Interactive Architecture Terminal Box
              , el "div" [ class_ "lg:col-span-5" ]
                  [ el "div" [ class_ "rounded-lg border border-zinc-800 bg-zinc-950 p-6 shadow-2xl font-mono text-xs text-zinc-300 space-y-4" ]
                      [ -- Terminal Title Bar
                        el "div" [ class_ "flex items-center justify-between pb-3 border-b border-zinc-800 text-zinc-500" ]
                          [ el "div" [ class_ "flex items-center gap-1.5" ]
                              [ el "span" [ class_ "size-2.5 rounded-full bg-red-500/80 inline-block" ] []
                              , el "span" [ class_ "size-2.5 rounded-full bg-amber-500/80 inline-block" ] []
                              , el "span" [ class_ "size-2.5 rounded-full bg-emerald-500/80 inline-block" ] []
                              ]
                          , el "span" [ class_ "text-[11px] font-mono tracking-widest text-zinc-500" ] [ text "pohjola.sh --verify" ]
                          ]
                      -- Code lines
                      , el "div" [ class_ "space-y-2 text-zinc-300" ]
                          [ el "div" [ class_ "flex items-center gap-2" ]
                              [ el "span" [ class_ "text-emerald-400" ] [ text "✓" ]
                              , el "span" [ class_ "text-zinc-400" ] [ text "PureScript compiler:" ]
                              , el "span" [ class_ "text-emerald-400 font-semibold" ] [ text "0 errors (totality verified)" ]
                              ]
                          , el "div" [ class_ "flex items-center gap-2" ]
                              [ el "span" [ class_ "text-emerald-400" ] [ text "✓" ]
                              , el "span" [ class_ "text-zinc-400" ] [ text "Tailwind v4 + DaisyUI:" ]
                              , el "span" [ class_ "text-teal-300 font-semibold" ] [ text "86ms CSS compilation" ]
                              ]
                          , el "div" [ class_ "flex items-center gap-2" ]
                              [ el "span" [ class_ "text-emerald-400" ] [ text "✓" ]
                              , el "span" [ class_ "text-zinc-400" ] [ text "Security CSP:" ]
                              , el "span" [ class_ "text-zinc-200 font-semibold" ] [ text "Pinned byte-exact nonce" ]
                              ]
                          , el "div" [ class_ "flex items-center gap-2" ]
                              [ el "span" [ class_ "text-emerald-400" ] [ text "✓" ]
                              , el "span" [ class_ "text-zinc-400" ] [ text "Client Bundle:" ]
                              , el "span" [ class_ "text-emerald-400 font-semibold" ] [ text "0 kB custom JS shipped" ]
                              ]
                          ]
                      -- Quick clone box
                      , el "div" [ class_ "pt-4 border-t border-zinc-800/80" ]
                          [ el "div" [ class_ "flex items-center justify-between bg-zinc-900 px-3.5 py-2.5 rounded border border-zinc-800" ]
                              [ el "div" [ class_ "flex items-center gap-2" ]
                                  [ el "span" [ class_ "text-emerald-400 font-bold select-none" ] [ text "$" ]
                                  , el "span" [ class_ "text-zinc-200 select-all" ] [ text "git clone git@github.com:icarofr/pohjola-framework.git" ]
                                  ]
                              ]
                          ]
                      ]
                  ]
              ]
          ]
      ]
