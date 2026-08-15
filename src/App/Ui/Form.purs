-- | Reusable form UI components with built-in accessibility, styling, and honeypot protection.
-- |
-- | Provides high-level form-building blocks (inspired by fullstack DX conventions):
-- | automatic honeypot injection, language threading, Tailwind styling, and status banners.
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

-- | Standard Tailwind styles for consistent form appearance across dark/light modes.
inputClass :: String
inputClass = "mt-1 block w-full rounded-md border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 px-3 py-2 text-slate-900 dark:text-white shadow-sm focus:border-blue-600 focus:outline-none focus:ring-1 focus:ring-blue-600"

labelClass :: String
labelClass = "block text-sm font-medium text-slate-700 dark:text-slate-300"

buttonClass :: String
buttonClass = "inline-flex items-center justify-center rounded-md bg-blue-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 transition-colors"

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

-- | Invisible honeypot field to trap spambots while remaining hidden from real users.
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

-- | Hidden input containing the current language tag.
langField :: Lang -> Html
langField lang =
  el "input"
    [ type_ "hidden"
    , name_ "lang"
    , attr "value" (langTag lang)
    ]
    []

-- | Renders a standard single-line text/email input field with label.
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
    el "div" []
      [ el "label" [ for_ props.id, class_ labelClass ]
          [ text props.label ]
      , el "input" inputAttrs []
      ]

-- | Text input helper.
textField :: InputProps -> Html
textField = inputFieldWith "text"

-- | Email input helper.
emailField :: InputProps -> Html
emailField = inputFieldWith "email"

-- | Multi-line textarea helper with label and rows configuration.
textareaField :: TextareaProps -> Html
textareaField props =
  let
    baseAttrs =
      [ id_ props.id
      , name_ props.name
      , rows_ props.rows
      , class_ inputClass
      ]
    reqAttrs = if props.required then [ flag "required" ] else []
    phAttrs = case props.placeholder of
      Just ph -> [ placeholder_ ph ]
      Nothing -> []
    attrs = baseAttrs <> reqAttrs <> phAttrs
  in
    el "div" []
      [ el "label" [ for_ props.id, class_ labelClass ]
          [ text props.label ]
      , el "textarea" attrs []
      ]

-- | Standard submit button.
submitButton :: String -> Html
submitButton label =
  el "button"
    [ type_ "submit"
    , class_ buttonClass
    ]
    [ text label ]

-- | Renders a success or error banner based on form status.
renderStatusBanner :: Maybe FormStatus -> String -> String -> Html
renderStatusBanner status successMsg errorMsg = case status of
  Just FormSuccess ->
    el "div" [ class_ "rounded-md bg-emerald-50 dark:bg-emerald-950/40 p-4 border border-emerald-200 dark:border-emerald-800 text-emerald-800 dark:text-emerald-200 mb-6" ]
      [ text successMsg ]
  Just FormError ->
    el "div" [ class_ "rounded-md bg-red-50 dark:bg-red-950/40 p-4 border border-red-200 dark:border-red-800 text-red-800 dark:text-red-200 mb-6" ]
      [ text errorMsg ]
  _ -> empty

-- | Container helper that injects language, honeypot, and form attributes automatically.
formContainer :: FormConfig -> Array Html -> Html
formContainer cfg children =
  let
    cls = case cfg.classNames of
      Just c -> c
      Nothing -> "space-y-6"
    formChildren = [ langField cfg.lang, honeypotField cfg.honeypotName ] <> children
  in
    el "form" [ action_ cfg.action, method_ cfg.method, class_ cls ] formChildren
