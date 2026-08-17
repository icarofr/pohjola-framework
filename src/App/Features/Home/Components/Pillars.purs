-- | Architecture Pillars section — 3 fundamental invariants of the framework
module App.Features.Home.Components.Pillars where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.Badge as Badge
import App.Ui.Card (card, cardBody)
import App.Ui.Container (container)
import Data.I18n (Lang)

renderPillars :: Lang -> Html
renderPillars _lang =
  el "section" [ class_ "py-16 sm:py-20 border-b border-zinc-200 dark:border-zinc-800" ]
    [ container "max-w-7xl" ""
        [ el "div" [ class_ "max-w-2xl mb-12" ]
            [ el "div" [ class_ "mb-3" ]
                [ Badge.badge Badge.Secondary "CORE INVARIANTS" ]
            , el "h2" [ class_ "font-display text-3xl font-extrabold tracking-tight text-zinc-900 dark:text-white sm:text-4xl" ]
                [ text "Engineered for uncompromising safety." ]
            , el "p" [ class_ "mt-3 text-base text-zinc-600 dark:text-zinc-400 font-normal leading-relaxed" ]
                [ text "Eliminate runtime exceptions, design drift, and client-side hydration waterfalls." ]
            ]
        , el "div" [ class_ "grid grid-cols-1 gap-6 md:grid-cols-3" ]
            [ -- Pillar 1
              card $ cardBody
                ( el "div" [ class_ "flex flex-col justify-between h-full space-y-4" ]
                    [ el "div" []
                        [ el "div" [ class_ "text-xs font-mono text-emerald-700 dark:text-emerald-400 font-bold mb-3" ]
                            [ text "01 // TOTALITY" ]
                        , el "h3" [ class_ "font-display text-xl font-bold text-zinc-900 dark:text-white" ]
                            [ text "Zero Runtime Exceptions" ]
                        , el "p" [ class_ "mt-2.5 text-sm text-zinc-600 dark:text-zinc-400 leading-relaxed font-normal" ]
                            [ text "Errors are typed values wrapped in Either. Exhaustive pattern matching guarantees no unhandled edge cases reach production." ]
                        ]
                    ]
                )

            -- Pillar 2
            , card $ cardBody
                ( el "div" [ class_ "flex flex-col justify-between h-full space-y-4" ]
                    [ el "div" []
                        [ el "div" [ class_ "text-xs font-mono text-teal-700 dark:text-teal-400 font-bold mb-3" ]
                            [ text "02 // HTML ADT" ]
                        , el "h3" [ class_ "font-display text-xl font-bold text-zinc-900 dark:text-white" ]
                            [ text "Guaranteed XSS Immunity" ]
                        , el "p" [ class_ "mt-2.5 text-sm text-zinc-600 dark:text-zinc-400 leading-relaxed font-normal" ]
                            [ text "Pages compile to an algebraic data type. No string concatenation, no unsafe innerHTML, and strictly verified CSP nonces." ]
                        ]
                    ]
                )

            -- Pillar 3
            , card $ cardBody
                ( el "div" [ class_ "flex flex-col justify-between h-full space-y-4" ]
                    [ el "div" []
                        [ el "div" [ class_ "text-xs font-mono text-zinc-700 dark:text-zinc-400 font-bold mb-3" ]
                            [ text "03 // BUN NATIVE" ]
                        , el "h3" [ class_ "font-display text-xl font-bold text-zinc-900 dark:text-white" ]
                            [ text "Instantaneous SSR Speed" ]
                        , el "p" [ class_ "mt-2.5 text-sm text-zinc-600 dark:text-zinc-400 leading-relaxed font-normal" ]
                            [ text "Powered by Bun.serve with zero Node.js overhead. Tailwind v4 and PureScript bundle in less than 100 milliseconds." ]
                        ]
                    ]
                )
            ]
        ]
    ]
