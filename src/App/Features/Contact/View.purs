-- | Contact page — direct message form and GitHub bug tracker links
module App.Features.Contact.View where

import Prelude

import App.Alpine (xAutofocus)
import App.Features.Contact.Components.ContactForm (renderContactForm)
import App.Html (Html, attr, class_, el, href, rel_, target_, text)
import App.Ui.Container (container)
import Data.Content (siteInfo)
import Data.I18n (Lang, dict)

renderContact :: Lang -> Html
renderContact lang =
  let
    d = (dict lang).contact
    navDict = (dict lang).nav
  in
    container "max-w-7xl" "py-16 sm:py-24"
      [ el "div" [ class_ "grid grid-cols-1 gap-x-12 gap-y-12 lg:grid-cols-2" ]
          [ -- Left column: Information, Direct Email & GitHub Issues
            el "div" [ class_ "flex flex-col justify-start" ]
              [ el "p" [ class_ "text-xs font-semibold uppercase tracking-wider text-emerald-600 dark:text-emerald-400" ]
                  [ text navDict.contact ]
              , el "h1" [ class_ "mt-2 font-display text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl dark:text-white", xAutofocus, attr "tabindex" "-1" ]
                  [ text d.title ]
              , el "p" [ class_ "mt-4 text-base/7 text-gray-600 dark:text-gray-300 font-normal" ]
                  [ text d.subtitle ]
              , el "dl" [ class_ "mt-6 space-y-4 text-sm/6 text-gray-600 dark:text-gray-300" ]
                  [ el "div" [ class_ "flex gap-x-3 items-center" ]
                      [ el "dt" [ class_ "font-semibold text-gray-900 dark:text-white" ] [ text "Direct Email:" ]
                      , el "dd" []
                          [ el "a"
                              [ href ("mailto:" <> siteInfo.email)
                              , class_ "font-mono text-emerald-600 hover:text-emerald-500 dark:text-emerald-400 dark:hover:text-emerald-300 transition-colors"
                              ]
                              [ text siteInfo.email ]
                          ]
                      ]
                  ]
              -- GitHub Issues & Bug Reports Card
              , el "div" [ class_ "mt-8 rounded-2xl bg-gray-50 p-6 border border-gray-200 dark:bg-gray-900/50 dark:border-white/10" ]
                  [ el "h3" [ class_ "text-sm font-bold text-gray-900 dark:text-white" ]
                      [ text d.bugReportTitle ]
                  , el "p" [ class_ "mt-2 text-xs/5 text-gray-600 dark:text-gray-400 font-normal" ]
                      [ text d.bugReportText ]
                  , el "div" [ class_ "mt-4" ]
                      [ el "a"
                          [ href "https://github.com/icarofr/pohjola-framework/issues"
                          , target_ "_blank"
                          , rel_ "noopener noreferrer"
                          , class_ "inline-flex items-center gap-x-1.5 rounded-md bg-gray-900 px-3 py-1.5 text-xs font-semibold text-white shadow-xs hover:bg-gray-800 dark:bg-white/10 dark:hover:bg-white/20 transition-colors"
                          ]
                          [ text d.bugReportButton
                          , el "span" [ attr "aria-hidden" "true" ] [ text " →" ]
                          ]
                      ]
                  ]
              ]
          -- Right column: Elevated Form Card
          , el "div" [ class_ "rounded-2xl bg-white p-8 sm:p-10 shadow-xs ring-1 ring-gray-200 dark:bg-gray-900/60 dark:ring-white/10" ]
              [ renderContactForm lang ]
          ]
      ]
