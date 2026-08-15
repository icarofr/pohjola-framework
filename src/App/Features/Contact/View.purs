-- | Community & Contributing page — direct GitHub bug tracker, discussions, and repository hubs
module App.Features.Contact.View where

import App.Alpine (xAutofocus)
import App.Html (Html, attr, class_, el, href, rel_, target_, text)
import App.Ui.Container (container)
import Data.I18n (Lang, dict)

renderContact :: Lang -> Html
renderContact lang =
  let
    d = (dict lang).contact
    navDict = (dict lang).nav
  in
    container "max-w-7xl" "py-12 sm:py-16 lg:py-20"
      [ container "max-w-2xl" "text-center"
          [ el "p" [ class_ "text-xs font-mono font-semibold uppercase tracking-widest text-emerald-700 dark:text-emerald-400" ]
              [ text navDict.contact ]
          , el "h1" [ class_ "mt-2 font-display text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl dark:text-white", xAutofocus, attr "tabindex" "-1" ]
              [ text d.title ]
          , el "p" [ class_ "mt-4 text-base/7 text-gray-600 dark:text-gray-300 font-normal" ]
              [ text d.subtitle ]
          ]
      , el "div" [ class_ "mt-12 grid grid-cols-1 gap-8 md:grid-cols-3" ]
          [ -- Card 1: Issues & Bug Reports
            el "div" [ class_ "flex flex-col justify-between rounded-2xl bg-white p-7 shadow-xs ring-1 ring-gray-200 hover:shadow-md hover:ring-emerald-500/30 dark:bg-gray-900/60 dark:ring-white/10 dark:hover:ring-emerald-400/30 transition-all" ]
              [ el "div" []
                  [ el "div" [ class_ "size-10 rounded-xl bg-emerald-50 dark:bg-emerald-500/10 flex items-center justify-center text-emerald-600 dark:text-emerald-400 font-bold text-lg mb-5" ]
                      [ el "svg"
                          [ class_ "size-5"
                          , attr "viewBox" "0 0 24 24"
                          , attr "fill" "none"
                          , attr "stroke" "currentColor"
                          , attr "stroke-width" "2"
                          ]
                          [ el "path"
                              [ attr "stroke-linecap" "round"
                              , attr "stroke-linejoin" "round"
                              , attr "d" "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                              ]
                              []
                          ]
                      ]
                  , el "h2" [ class_ "font-display text-lg font-bold tracking-tight text-gray-900 dark:text-white" ]
                      [ text d.issuesTitle ]
                  , el "p" [ class_ "mt-2.5 text-sm/6 text-gray-600 dark:text-gray-400 font-normal" ]
                      [ text d.issuesText ]
                  ]
              , el "div" [ class_ "mt-6 pt-4 border-t border-gray-100 dark:border-white/5" ]
                  [ el "a"
                      [ href "https://github.com/icarofr/pohjola-framework/issues"
                      , target_ "_blank"
                      , rel_ "noopener noreferrer"
                      , class_ "inline-flex items-center gap-x-1 text-sm font-semibold text-emerald-600 hover:text-emerald-500 dark:text-emerald-400 dark:hover:text-emerald-300 transition-colors"
                      ]
                      [ text d.issuesButton
                      , el "span" [ attr "aria-hidden" "true" ] [ text " →" ]
                      ]
                  ]
              ]

          -- Card 2: Discussions & Q&A
          , el "div" [ class_ "flex flex-col justify-between rounded-2xl bg-white p-7 shadow-xs ring-1 ring-gray-200 hover:shadow-md hover:ring-emerald-500/30 dark:bg-gray-900/60 dark:ring-white/10 dark:hover:ring-emerald-400/30 transition-all" ]
              [ el "div" []
                  [ el "div" [ class_ "size-10 rounded-xl bg-emerald-50 dark:bg-emerald-500/10 flex items-center justify-center text-emerald-600 dark:text-emerald-400 font-bold text-lg mb-5" ]
                      [ el "svg"
                          [ class_ "size-5"
                          , attr "viewBox" "0 0 24 24"
                          , attr "fill" "none"
                          , attr "stroke" "currentColor"
                          , attr "stroke-width" "2"
                          ]
                          [ el "path"
                              [ attr "stroke-linecap" "round"
                              , attr "stroke-linejoin" "round"
                              , attr "d" "M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                              ]
                              []
                          ]
                      ]
                  , el "h2" [ class_ "font-display text-lg font-bold tracking-tight text-gray-900 dark:text-white" ]
                      [ text d.discussionsTitle ]
                  , el "p" [ class_ "mt-2.5 text-sm/6 text-gray-600 dark:text-gray-400 font-normal" ]
                      [ text d.discussionsText ]
                  ]
              , el "div" [ class_ "mt-6 pt-4 border-t border-gray-100 dark:border-white/5" ]
                  [ el "a"
                      [ href "https://github.com/icarofr/pohjola-framework/discussions"
                      , target_ "_blank"
                      , rel_ "noopener noreferrer"
                      , class_ "inline-flex items-center gap-x-1 text-sm font-semibold text-emerald-600 hover:text-emerald-500 dark:text-emerald-400 dark:hover:text-emerald-300 transition-colors"
                      ]
                      [ text d.discussionsButton
                      , el "span" [ attr "aria-hidden" "true" ] [ text " →" ]
                      ]
                  ]
              ]

          -- Card 3: Source Code & Invariants
          , el "div" [ class_ "flex flex-col justify-between rounded-2xl bg-white p-7 shadow-xs ring-1 ring-gray-200 hover:shadow-md hover:ring-emerald-500/30 dark:bg-gray-900/60 dark:ring-white/10 dark:hover:ring-emerald-400/30 transition-all" ]
              [ el "div" []
                  [ el "div" [ class_ "size-10 rounded-xl bg-emerald-50 dark:bg-emerald-500/10 flex items-center justify-center text-emerald-600 dark:text-emerald-400 font-bold text-lg mb-5" ]
                      [ el "svg"
                          [ class_ "size-5"
                          , attr "viewBox" "0 0 24 24"
                          , attr "fill" "none"
                          , attr "stroke" "currentColor"
                          , attr "stroke-width" "2"
                          ]
                          [ el "path"
                              [ attr "stroke-linecap" "round"
                              , attr "stroke-linejoin" "round"
                              , attr "d" "M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"
                              ]
                              []
                          ]
                      ]
                  , el "h2" [ class_ "font-display text-lg font-bold tracking-tight text-gray-900 dark:text-white" ]
                      [ text d.sourceTitle ]
                  , el "p" [ class_ "mt-2.5 text-sm/6 text-gray-600 dark:text-gray-400 font-normal" ]
                      [ text d.sourceText ]
                  ]
              , el "div" [ class_ "mt-6 pt-4 border-t border-gray-100 dark:border-white/5" ]
                  [ el "a"
                      [ href "https://github.com/icarofr/pohjola-framework"
                      , target_ "_blank"
                      , rel_ "noopener noreferrer"
                      , class_ "inline-flex items-center gap-x-1 text-sm font-semibold text-emerald-600 hover:text-emerald-500 dark:text-emerald-400 dark:hover:text-emerald-300 transition-colors"
                      ]
                      [ text d.sourceButton
                      , el "span" [ attr "aria-hidden" "true" ] [ text " →" ]
                      ]
                  ]
              ]
          ]
      ]
