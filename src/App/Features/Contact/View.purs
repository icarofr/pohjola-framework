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
    container "max-w-7xl" "py-12 sm:py-16 lg:py-20"
      [ el "div" [ class_ "text-center max-w-2xl mx-auto mb-10 sm:mb-12" ]
          [ el "div" [ class_ "mb-4 flex justify-center" ]
              [ Badge.badge Badge.Neutral navDict.contact ]
          , el "h1" [ class_ "font-display text-4xl sm:text-5xl font-extrabold tracking-tight text-gray-900 dark:text-white leading-tight" ]
              [ text d.title ]
          , el "p" [ class_ "mt-4 text-base sm:text-lg text-gray-600 dark:text-gray-300 leading-relaxed max-w-xl mx-auto font-normal" ]
              [ text d.subtitle ]
          ]
      , el "div" [ class_ "grid grid-cols-1 gap-8 md:grid-cols-3" ]
          [ -- Card 1: Issues & Bug Reports
            card $ cardBody
              ( el "div" [ class_ "flex flex-col justify-between h-full" ]
                  [ el "div" []
                      [ el "div" [ class_ "mb-4" ]
                          [ Badge.badge Badge.Error "Issues" ]
                      , el "h2" [ class_ "font-display text-lg font-bold tracking-tight text-gray-900 dark:text-white" ]
                          [ text d.issuesTitle ]
                      , el "p" [ class_ "mt-2.5 text-sm/6 text-gray-600 dark:text-gray-400 font-normal" ]
                          [ text d.issuesText ]
                      ]
                  , el "div" [ class_ "mt-6 pt-4 border-t border-gray-100 dark:border-white/5" ]
                      [ buttonLinkExternal { variant: Secondary, size: Sm, href: "https://github.com/icarofr/pohjola-framework/issues", extraClass: "w-full" } d.issuesButton
                      ]
                  ]
              )

          -- Card 2: Discussions & Q&A
          , card $ cardBody
              ( el "div" [ class_ "flex flex-col justify-between h-full" ]
                  [ el "div" []
                      [ el "div" [ class_ "mb-4" ]
                          [ Badge.badge Badge.Tertiary "Discussions" ]
                      , el "h2" [ class_ "font-display text-lg font-bold tracking-tight text-gray-900 dark:text-white" ]
                          [ text d.discussionsTitle ]
                      , el "p" [ class_ "mt-2.5 text-sm/6 text-gray-600 dark:text-gray-400 font-normal" ]
                          [ text d.discussionsText ]
                      ]
                  , el "div" [ class_ "mt-6 pt-4 border-t border-gray-100 dark:border-white/5" ]
                      [ buttonLinkExternal { variant: Secondary, size: Sm, href: "https://github.com/icarofr/pohjola-framework/discussions", extraClass: "w-full" } d.discussionsButton
                      ]
                  ]
              )

          -- Card 3: Source Code & Invariants
          , card $ cardBody
              ( el "div" [ class_ "flex flex-col justify-between h-full" ]
                  [ el "div" []
                      [ el "div" [ class_ "mb-4" ]
                          [ Badge.badge Badge.Primary "Repository" ]
                      , el "h2" [ class_ "font-display text-lg font-bold tracking-tight text-gray-900 dark:text-white" ]
                          [ text d.sourceTitle ]
                      , el "p" [ class_ "mt-2.5 text-sm/6 text-gray-600 dark:text-gray-400 font-normal" ]
                          [ text d.sourceText ]
                      ]
                  , el "div" [ class_ "mt-6 pt-4 border-t border-gray-100 dark:border-white/5" ]
                      [ buttonLinkExternal { variant: Secondary, size: Sm, href: "https://github.com/icarofr/pohjola-framework", extraClass: "w-full" } d.sourceButton
                      ]
                  ]
              )
          ]
      ]

