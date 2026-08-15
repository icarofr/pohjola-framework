-- | Contact page — form
module App.Features.Contact.View where

import App.Alpine (xAutofocus)
import App.Features.Contact.Components.ContactForm (renderContactForm)
import App.Html (Html, attr, class_, el, text)
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
          [ -- Left column: Information & Context
            el "div" [ class_ "flex flex-col justify-start" ]
              [ el "p" [ class_ "text-xs font-semibold uppercase tracking-wider text-indigo-600 dark:text-indigo-400" ]
                  [ text navDict.contact ]
              , el "h1" [ class_ "mt-2 font-display text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl dark:text-white", xAutofocus, attr "tabindex" "-1" ]
                  [ text d.title ]
              , el "p" [ class_ "mt-4 text-base/7 text-gray-600 dark:text-gray-300 font-normal" ]
                  [ text siteInfo.description ]
              , el "dl" [ class_ "mt-8 space-y-4 text-sm/6 text-gray-600 dark:text-gray-300" ]
                  [ el "div" [ class_ "flex gap-x-3" ]
                      [ el "dt" [ class_ "font-semibold text-gray-900 dark:text-white" ] [ text "Email:" ]
                      , el "dd" [] [ text siteInfo.email ]
                      ]
                  ]
              ]
          -- Right column: Elevated Form Card
          , el "div" [ class_ "rounded-2xl bg-white p-8 sm:p-10 shadow-xs ring-1 ring-gray-200 dark:bg-gray-900/60 dark:ring-white/10" ]
              [ renderContactForm lang ]
          ]
      ]
