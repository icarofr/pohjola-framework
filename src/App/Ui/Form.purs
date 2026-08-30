-- | Form controls — DaisyUI fieldset/input/textarea (research/daisyui fieldset docs)
module App.Ui.Form
  ( FormConfig
  , InputProps
  , TextareaProps
  , emailField
  , formContainer
  , honeypotField
  , langField
  , renderStatusBanner
  , submitButton
  , textField
  , textareaField
  ) where

import Prelude

import App.Form (FormStatus(..))
import App.Html (Html, action_, attr, class_, el, empty, flag, for_, id_, method_, name_, placeholder_, rows_, text, type_)
import Data.I18n (Lang, langTag)
import Data.Maybe (Maybe(..))

inputClass :: String
inputClass = "input w-full"

labelClass :: String
labelClass = "fieldset-label"

buttonClass :: String
buttonClass = "btn btn-primary"

type FormConfig =
  { action :: String
  , method :: String
  , lang :: Lang
  , honeypotName :: String
  , classNames :: Maybe String
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
    [ el "label" [ for_ ("form-" <> name), class_ labelClass ]
        [ text "Website" ]
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
  el "input"
    [ type_ "hidden"
    , name_ "lang"
    , attr "value" (langTag lang)
    ]
    []

inputFieldWith :: String -> InputProps -> Html
inputFieldWith typ props =
  let
    baseAttrs =
      [ type_ typ
      , id_ props.id
      , name_ props.name
      , class_ inputClass
      ]
    reqAttrs = if props.required then [ flag "required" ] else []
    phAttrs = case props.placeholder of
      Just ph -> [ placeholder_ ph ]
      Nothing -> []
    inputAttrs = baseAttrs <> reqAttrs <> phAttrs
  in
    el "fieldset" [ class_ "fieldset" ]
      [ el "label" [ for_ props.id, class_ labelClass ]
          [ text props.label ]
      , el "input" inputAttrs []
      ]

textField :: InputProps -> Html
textField = inputFieldWith "text"

emailField :: InputProps -> Html
emailField = inputFieldWith "email"

textareaField :: TextareaProps -> Html
textareaField props =
  let
    baseAttrs =
      [ id_ props.id
      , name_ props.name
      , rows_ props.rows
      , class_ "textarea w-full"
      ]
    reqAttrs = if props.required then [ flag "required" ] else []
    phAttrs = case props.placeholder of
      Just ph -> [ placeholder_ ph ]
      Nothing -> []
    attrs = baseAttrs <> reqAttrs <> phAttrs
  in
    el "fieldset" [ class_ "fieldset" ]
      [ el "label" [ for_ props.id, class_ labelClass ]
          [ text props.label ]
      , el "textarea" attrs []
      ]

submitButton :: String -> Html
submitButton label =
  el "button"
    [ type_ "submit"
    , class_ buttonClass
    ]
    [ text label ]

renderStatusBanner :: Maybe FormStatus -> String -> String -> Html
renderStatusBanner status successMsg errorMsg = case status of
  Just FormSuccess ->
    el "div" [ class_ "alert alert-success mb-6", attr "role" "status" ]
      [ text successMsg ]
  Just FormError ->
    el "div" [ class_ "alert alert-error mb-6", attr "role" "alert" ]
      [ text errorMsg ]
  _ -> empty

formContainer :: FormConfig -> Array Html -> Html
formContainer cfg children =
  let
    cls = case cfg.classNames of
      Just c -> c
      Nothing -> "space-y-4"
    formChildren = [ langField cfg.lang, honeypotField cfg.honeypotName ] <> children
  in
    el "form" [ action_ cfg.action, method_ cfg.method, class_ cls ] formChildren
