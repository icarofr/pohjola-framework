module App.Features.Contact.Components.ContactForm where

import App.Form (apiContactPath)
import App.Html (Html)
import App.Ui.Form (emailField, formContainer, submitButton, textField, textareaField)
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe(..))

renderContactForm :: Lang -> Html
renderContactForm lang =
  let
    d = (dict lang).contact
  in
    formContainer
      { action: apiContactPath
      , method: "POST"
      , lang: lang
      , honeypotName: "website"
      , classNames: Just "space-y-6"
      }
      [ textField
          { id: "name"
          , name: "name"
          , label: d.formName
          , inputType: "text"
          , required: true
          , placeholder: Nothing
          }
      , emailField
          { id: "email"
          , name: "email"
          , label: d.emailLabel
          , inputType: "email"
          , required: true
          , placeholder: Nothing
          }
      , textareaField
          { id: "message"
          , name: "message"
          , label: d.messageLabel
          , rows: 4
          , required: true
          , placeholder: Nothing
          }
      , submitButton d.sendLabel
      ]
