-- | Form page — DaisyUI fieldset inputs via App.Ui.Form (templates only).
module App.Ui.Templates.Form
  ( renderForm
  ) where

import Prelude

import App.Html (Html, attr, class_, el)
import App.Ui.Container as Container
import App.Ui.Form as UiForm
import App.Ui.Templates.Contract as Contract
import App.Ui.Templates.PageHeader as PageHeader
import App.Ui.Templates.Types (FormField(..), FormSlots)
import Data.I18n (Lang)
import Data.Maybe (Maybe(..))
import Data.Route (Route)

renderForm :: Lang -> Route -> FormSlots -> Html
renderForm lang route slots =
  el "section"
    [ class_ "py-16 sm:py-20"
    , attr Contract.marker Contract.formPage
    ]
    [ Container.container "max-w-2xl" "px-4 sm:px-6"
        [ PageHeader.render lang route
            ( PageHeader.pageHeaderSlots slots.title slots.subtitle slots.breadcrumbs
            )
        , el "div" [ class_ "mt-12" ]
            [ UiForm.formContainer
                { action: slots.action
                , method: "POST"
                , lang
                , honeypotName: "website"
                }
                ( map renderField slots.fields
                    <> [ UiForm.submitButton slots.submitLabel ]
                )
            ]
        ]
    ]

renderField :: FormField -> Html
renderField = case _ of
  FormText field ->
    UiForm.textField
      { id: field.name
      , name: field.name
      , label: field.label
      , inputType: "text"
      , required: field.required
      , placeholder: Nothing
      }
  FormEmail field ->
    UiForm.emailField
      { id: field.name
      , name: field.name
      , label: field.label
      , inputType: "email"
      , required: field.required
      , placeholder: Nothing
      }
  FormTextarea field ->
    UiForm.textareaField
      { id: field.name
      , name: field.name
      , label: field.label
      , rows: field.rows
      , required: field.required
      , placeholder: Nothing
      }
