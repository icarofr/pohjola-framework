-- | Reusable form UI components with built-in accessibility, styling, and honeypot protection.
-- |
-- | Provides high-level form-building blocks (inspired by Tailwind UI):
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

-- | Standard Tailwind styles matching Tailwind UI v4 form controls.
inputClass :: String
inputClass = "mt-1.5 block w-full rounded-md bg-white px-3.5 py-2 text-base text-gray-900 outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline-2 focus:-outline-offset-2 focus:outline-emerald-600 sm:text-sm/6 dark:bg-white/5 dark:text-white dark:outline-white/10 dark:placeholder:text-gray-500 dark:focus:outline-emerald-500 transition-all"

labelClass :: String
labelClass = "block text-sm/6 font-medium text-gray-900 dark:text-white"

buttonClass :: String
buttonClass = "inline-flex items-center justify-center rounded-md bg-emerald-700 px-4 py-2.5 text-sm font-semibold text-white shadow-xs hover:bg-emerald-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-700 dark:bg-emerald-500 dark:text-gray-950 dark:font-bold dark:shadow-none dark:hover:bg-emerald-400 dark:focus-visible:outline-emerald-400 transition-all cursor-pointer select-none"

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
    el "div" [ class_ "rounded-lg bg-green-50 p-4 border border-green-200 dark:bg-green-500/10 dark:border-green-500/20 text-green-800 dark:text-green-200 text-sm font-medium mb-6 shadow-xs flex items-center gap-2" ]
      [ text successMsg ]
  Just FormError ->
    el "div" [ class_ "rounded-lg bg-red-50 p-4 border border-red-200 dark:bg-red-500/10 dark:border-red-500/20 text-red-800 dark:text-red-200 text-sm font-medium mb-6 shadow-xs flex items-center gap-2" ]
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
