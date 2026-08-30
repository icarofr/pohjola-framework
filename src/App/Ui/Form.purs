-- | DaisyUI fieldset + input — research/daisyui-llms.txt Fieldset.
module App.Ui.Form
  ( FormConfig
  , InputProps
  , TextareaProps
  , emailField
  , formContainer
  , honeypotField
  , langField
  , submitButton
  , textField
  , textareaField
  ) where

import Prelude

import App.Html (Html, action_, attr, class_, el, flag, for_, id_, method_, name_, placeholder_, rows_, text, type_)
import Data.I18n (Lang, langTag)
import Data.Maybe (Maybe(..))

type FormConfig =
  { action :: String
  , method :: String
  , lang :: Lang
  , honeypotName :: String
  }

type InputProps =
  { id :: String
  , name :: String
  , label :: String
  , inputType :: String
  , required :: Boolean
  , placeholder :: Maybe String
  }

type TextareaProps =
  { id :: String
  , name :: String
  , label :: String
  , rows :: Int
  , required :: Boolean
  , placeholder :: Maybe String
  }

honeypotField :: String -> Html
honeypotField name =
  el "div" [ class_ "absolute -left-[9999px]", attr "aria-hidden" "true" ]
    [ el "label" [ for_ ("form-" <> name), class_ "label" ] [ text "Website" ]
    , el "input"
        [ type_ "text"
        , id_ ("form-" <> name)
        , name_ name
        , attr "tabindex" "-1"
        , attr "autocomplete" "off"
        ]
        []
    ]

langField :: Lang -> Html
langField lang =
  el "input" [ type_ "hidden", name_ "lang", attr "value" (langTag lang) ] []

textField :: InputProps -> Html
textField = inputFieldWith "text"

emailField :: InputProps -> Html
emailField = inputFieldWith "email"

inputFieldWith :: String -> InputProps -> Html
inputFieldWith typ props =
  el "fieldset" [ class_ "fieldset" ]
    [ el "legend" [ class_ "fieldset-legend" ] [ text props.label ]
    , el "input"
        ( [ type_ typ, id_ props.id, name_ props.name, class_ "input" ]
            <> (if props.required then [ flag "required" ] else [])
            <> case props.placeholder of
              Just ph -> [ placeholder_ ph ]
              Nothing -> []
        )
        []
    ]

textareaField :: TextareaProps -> Html
textareaField props =
  el "fieldset" [ class_ "fieldset" ]
    [ el "legend" [ class_ "fieldset-legend" ] [ text props.label ]
    , el "textarea"
        ( [ id_ props.id, name_ props.name, rows_ props.rows, class_ "textarea" ]
            <> (if props.required then [ flag "required" ] else [])
            <> case props.placeholder of
              Just ph -> [ placeholder_ ph ]
              Nothing -> []
        )
        []
    ]

submitButton :: String -> Html
submitButton label =
  el "button" [ type_ "submit", class_ "btn btn-primary" ] [ text label ]

formContainer :: FormConfig -> Array Html -> Html
formContainer cfg children =
  el "form" [ action_ cfg.action, method_ cfg.method ]
    ([ langField cfg.lang, honeypotField cfg.honeypotName ] <> children)
