-- | Community & Contributing page — direct GitHub bug tracker, discussions, and repository hubs
module App.Features.Contact.View where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.Badge as Badge
import App.Ui.Button (buttonLinkExternal, Variant(..), Size(..))
import App.Ui.Card (card, cardBody)
import App.Ui.Container (container)
import Data.I18n (Lang, dict)

renderContact :: Lang -> Html
renderContact lang =
  let
    d = (dict lang).contact
    navDict = (dict lang).nav
  in
    container "max-w-7xl" "py-16 sm:py-24 space-y-12"
      [ -- Page Header
        el "div" [ class_ "max-w-2xl space-y-4" ]
          [ el "div" [ class_ "flex items-center gap-2" ]
              [ Badge.badge Badge.Primary navDict.contact
              , Badge.badge Badge.Neutral "ECOSYSTEM"
              ]
          , el "h1" [ class_ "font-display text-4xl sm:text-5xl font-extrabold tracking-tight text-zinc-950 dark:text-white leading-tight" ]
              [ text d.title ]
          , el "p" [ class_ "text-base sm:text-lg text-zinc-600 dark:text-zinc-400 font-normal leading-relaxed" ]
              [ text d.subtitle ]
          ]
      , el "div" [ class_ "grid grid-cols-1 gap-6 md:grid-cols-3" ]
          [ -- Card 1: Issues & Bug Reports
            card $ cardBody
              ( el "div" [ class_ "flex flex-col justify-between h-full space-y-6" ]
                  [ el "div" []
                      [ el "div" [ class_ "mb-4 flex items-center justify-between" ]
                          [ Badge.badge Badge.Error "ISSUES"
                          , el "span" [ class_ "text-xs font-mono text-zinc-400" ] [ text "TRIAGE < 24H" ]
                          ]
                      , el "h2" [ class_ "font-display text-xl font-bold tracking-tight text-zinc-950 dark:text-white" ]
                          [ text d.issuesTitle ]
                      , el "p" [ class_ "mt-2.5 text-sm text-zinc-600 dark:text-zinc-400 font-normal leading-relaxed" ]
                          [ text d.issuesText ]
                      ]
                  , el "div" [ class_ "pt-4 border-t border-zinc-100 dark:border-zinc-800" ]
                      [ buttonLinkExternal { variant: Outline, size: Sm, href: "https://github.com/icarofr/pohjola-framework/issues", extraClass: "w-full" } d.issuesButton
                      ]
                  ]
              )

          -- Card 2: Discussions & Q&A
          , card $ cardBody
              ( el "div" [ class_ "flex flex-col justify-between h-full space-y-6" ]
                  [ el "div" []
                      [ el "div" [ class_ "mb-4 flex items-center justify-between" ]
                          [ Badge.badge Badge.Tertiary "DISCUSSIONS"
                          , el "span" [ class_ "text-xs font-mono text-zinc-400" ] [ text "OPEN RFC" ]
                          ]
                      , el "h2" [ class_ "font-display text-xl font-bold tracking-tight text-zinc-950 dark:text-white" ]
                          [ text d.discussionsTitle ]
                      , el "p" [ class_ "mt-2.5 text-sm text-zinc-600 dark:text-zinc-400 font-normal leading-relaxed" ]
                          [ text d.discussionsText ]
                      ]
                  , el "div" [ class_ "pt-4 border-t border-zinc-100 dark:border-zinc-800" ]
                      [ buttonLinkExternal { variant: Outline, size: Sm, href: "https://github.com/icarofr/pohjola-framework/discussions", extraClass: "w-full" } d.discussionsButton
                      ]
                  ]
              )

          -- Card 3: Source Code & Invariants
          , card $ cardBody
              ( el "div" [ class_ "flex flex-col justify-between h-full space-y-6" ]
                  [ el "div" []
                      [ el "div" [ class_ "mb-4 flex items-center justify-between" ]
                          [ Badge.badge Badge.Primary "CORE REPO"
                          , el "span" [ class_ "text-xs font-mono text-zinc-400" ] [ text "MIT LICENSED" ]
                          ]
                      , el "h2" [ class_ "font-display text-xl font-bold tracking-tight text-zinc-950 dark:text-white" ]
                          [ text d.sourceTitle ]
                      , el "p" [ class_ "mt-2.5 text-sm text-zinc-600 dark:text-zinc-400 font-normal leading-relaxed" ]
                          [ text d.sourceText ]
                      ]
                  , el "div" [ class_ "pt-4 border-t border-zinc-100 dark:border-zinc-800" ]
                      [ buttonLinkExternal { variant: Secondary, size: Sm, href: "https://github.com/icarofr/pohjola-framework", extraClass: "w-full" } d.sourceButton
                      ]
                  ]
              )
          ]
      ]
