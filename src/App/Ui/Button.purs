-- | Button primitive — Tailwind UI inspired variants, type-safe via sum types
module App.Ui.Button where

import Prelude

import App.Alpine (spaLink)
import App.Html (Html, class_, el, href, rel_, target_, text)
import Data.I18n (Lang)
import Data.Route (Route)

data Variant = Primary | Secondary | Outline | Ghost | Inverted
data Size = Sm | Md | Lg

renderVariant :: Variant -> String
renderVariant = case _ of
  Primary -> "bg-emerald-700 text-white shadow-xs hover:bg-emerald-800 focus-visible:outline-emerald-700 dark:bg-emerald-500 dark:text-gray-950 dark:font-bold dark:shadow-none dark:hover:bg-emerald-400 dark:focus-visible:outline-emerald-400"
  Secondary -> "bg-white text-gray-900 shadow-xs ring-1 ring-gray-300 hover:bg-gray-50 dark:bg-gray-800 dark:text-gray-100 dark:shadow-none dark:ring-gray-700 dark:hover:bg-gray-700"
  Outline -> "bg-transparent text-gray-900 ring-1 ring-gray-300 hover:bg-gray-50 dark:text-gray-100 dark:ring-gray-700 dark:hover:bg-gray-800"
  Ghost -> "text-gray-800 hover:bg-gray-100 hover:text-gray-900 dark:text-gray-200 dark:hover:bg-gray-800 dark:hover:text-white"
  Inverted -> "bg-white text-gray-900 shadow-xs hover:bg-gray-100 focus-visible:outline-white dark:bg-white dark:text-gray-900 dark:hover:bg-gray-100"

renderSize :: Size -> String
renderSize = case _ of
  Sm -> "px-2.5 py-1.5 text-xs font-semibold"
  Md -> "px-3.5 py-2 text-sm font-semibold"
  Lg -> "px-4 py-2.5 text-sm sm:text-base font-semibold"

baseClass :: String
baseClass = "inline-flex items-center justify-center rounded-md font-semibold transition-all focus-visible:outline-2 focus-visible:outline-offset-2 cursor-pointer select-none"

-- | Internal link styled as a button.
buttonLink :: { variant :: Variant, size :: Size, lang :: Lang, route :: Route, extraClass :: String } -> String -> Html
buttonLink props label =
  spaLink props.lang props.route
    [ class_ (baseClass <> " " <> renderVariant props.variant <> " " <> renderSize props.size <> " " <> props.extraClass) ]
    [ text label ]

-- | Render an external link styled as a button
buttonLinkExternal :: { variant :: Variant, size :: Size, href :: String, extraClass :: String } -> String -> Html
buttonLinkExternal props label =
  el "a"
    [ href props.href
    , target_ "_blank"
    , rel_ "noopener noreferrer"
    , class_ (baseClass <> " " <> renderVariant props.variant <> " " <> renderSize props.size <> " " <> props.extraClass)
    ]
    [ text label ]
