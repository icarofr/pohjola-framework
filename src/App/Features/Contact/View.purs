-- | Contact page — form + social links
module App.Features.Contact.View where

import App.Alpine (xAutofocus)
import App.Form (apiContactPath)
import App.Html (Html, action_, attr, class_, el, flag, for_, id_, method_, name_, rows_, text, type_)
import App.Ui.Social (renderSocial)
import Data.Content (siteInfo)
import Data.I18n (Lang, dict, langTag)

renderContact :: Lang -> Html
renderContact lang =
  let
    d = (dict lang).contact
  in
    el "div" [ class_ "mx-auto max-w-2xl px-4 py-16 sm:px-6 lg:px-8" ]
      [ el "h1" [ class_ "font-display text-4xl font-bold text-slate-900 dark:text-white", xAutofocus, attr "tabindex" "-1" ]
          [ text d.title ]
      -- Contact form
      , el "form" [ action_ apiContactPath, method_ "POST", class_ "mt-8 space-y-6" ]
          [ el "input"
              [ type_ "hidden"
              , name_ "lang"
              , attr "value" (langTag lang)
              ]
              []
          -- Honeypot field
          , el "div" [ class_ "absolute -left-[9999px]", attr "aria-hidden" "true" ]
              [ el "label" [ for_ "contact-website", class_ "block text-sm font-medium text-slate-700 dark:text-slate-300" ]
                  [ text "Website" ]
              , el "input"
                  [ type_ "text"
                  , id_ "contact-website"
                  , name_ "website"
                  , attr "tabindex" "-1"
                  , attr "autocomplete" "off"
                  ]
                  []
              ]
          , el "div" []
              [ el "label" [ for_ "name", class_ "block text-sm font-medium text-slate-700 dark:text-slate-300" ]
                  [ text d.formName ]
              , el "input"
                  [ type_ "text"
                  , id_ "name"
                  , name_ "name"
                  , flag "required"
                  , class_ "mt-1 block w-full rounded-md border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 px-3 py-2 text-slate-900 dark:text-white shadow-sm focus:border-blue-600 focus:outline-none focus:ring-1 focus:ring-blue-600"
                  ]
                  []
              ]
          , el "div" []
              [ el "label" [ for_ "email", class_ "block text-sm font-medium text-slate-700 dark:text-slate-300" ]
                  [ text d.emailLabel ]
              , el "input"
                  [ type_ "email"
                  , id_ "email"
                  , name_ "email"
                  , flag "required"
                  , class_ "mt-1 block w-full rounded-md border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 px-3 py-2 text-slate-900 dark:text-white shadow-sm focus:border-blue-600 focus:outline-none focus:ring-1 focus:ring-blue-600"
                  ]
                  []
              ]
          , el "div" []
              [ el "label" [ for_ "message", class_ "block text-sm font-medium text-slate-700 dark:text-slate-300" ]
                  [ text d.messageLabel ]
              , el "textarea"
                  [ id_ "message"
                  , name_ "message"
                  , rows_ 4
                  , flag "required"
                  , class_ "mt-1 block w-full rounded-md border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 px-3 py-2 text-slate-900 dark:text-white shadow-sm focus:border-blue-600 focus:outline-none focus:ring-1 focus:ring-blue-600"
                  ]
                  []
              ]
          , el "button"
              [ type_ "submit"
              , class_ "inline-flex items-center justify-center rounded-md bg-blue-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 transition-colors"
              ]
              [ text d.sendLabel ]
          ]
      -- Social links
      , el "div" [ class_ "mt-8 pt-8 border-t border-slate-200 dark:border-slate-800" ]
          [ el "h2" [ class_ "text-lg font-semibold text-slate-900 dark:text-white" ]
              [ text d.socialLabel ]
          , el "div" [ class_ "mt-4 flex space-x-3" ]
              [ renderSocial siteInfo.facebookUrl "facebook"
              , renderSocial siteInfo.instagramUrl "instagram"
              ]
          ]
      ]

