-- | Contact page — form + social links
module App.Features.Contact.View where

import App.Alpine (xAutofocus)
import App.Features.Contact.Components.ContactForm (renderContactForm)
import App.Html (Html, attr, class_, el, text)
import App.Ui.Container (container)
import App.Ui.Social (renderSocial)
import Data.Content (siteInfo)
import Data.I18n (Lang, dict)

renderContact :: Lang -> Html
renderContact lang =
  let
    d = (dict lang).contact
  in
    container "max-w-2xl" "py-16"
      [ el "h1" [ class_ "font-display text-4xl font-bold text-slate-900 dark:text-white", xAutofocus, attr "tabindex" "-1" ]
          [ text d.title ]
      , renderContactForm lang
      , el "div" [ class_ "mt-8 pt-8 border-t border-slate-200 dark:border-slate-800" ]
          [ el "h2" [ class_ "text-lg font-semibold text-slate-900 dark:text-white" ]
              [ text d.socialLabel ]
          , el "div" [ class_ "mt-4 flex space-x-3" ]
              [ renderSocial siteInfo.facebookUrl "facebook"
              , renderSocial siteInfo.instagramUrl "instagram"
              ]
          ]
      ]

