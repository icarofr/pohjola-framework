-- | Button primitive — Nordic Architectural variants, type-safe via sum types
module App.Ui.Button where

import Prelude

import App.Alpine (spaLink)
import App.Html (Html, class_, el, href, rel_, target_, text)
import Data.I18n (Lang)
import Data.Route (Route)

data ButtonVariant = ButtonPrimary | ButtonSecondary | ButtonOutline | ButtonGhost | ButtonInverted
type Variant = ButtonVariant

data Size = Sm | Md | Lg

renderVariant :: ButtonVariant -> String
renderVariant = case _ of
  ButtonPrimary -> "bg-emerald-700 hover:bg-emerald-800 text-white shadow-xs border border-emerald-800/30 focus-visible:outline-emerald-700 dark:bg-emerald-600 dark:hover:bg-emerald-500 active:scale-[0.98]"
  ButtonSecondary -> "bg-zinc-900 hover:bg-zinc-800 text-white shadow-xs border border-zinc-800 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-white active:scale-[0.98]"
  ButtonOutline -> "bg-white dark:bg-zinc-900 text-zinc-900 dark:text-zinc-100 border border-zinc-200 dark:border-zinc-800 hover:bg-zinc-50 dark:hover:bg-zinc-800 shadow-2xs active:scale-[0.98]"
  ButtonGhost -> "text-zinc-700 dark:text-zinc-300 hover:text-zinc-950 dark:hover:text-white hover:bg-zinc-100 dark:hover:bg-zinc-800/60"
  ButtonInverted -> "bg-white text-zinc-950 hover:bg-zinc-100 font-semibold shadow-xs border border-zinc-200/50 active:scale-[0.98]"

renderSize :: Size -> String
renderSize = case _ of
  Sm -> "px-3 py-1.5 text-xs font-semibold"
  Md -> "px-4 py-2 text-sm font-semibold"
  Lg -> "px-5 py-2.5 text-sm sm:text-base font-semibold"

baseClass :: String
baseClass = "inline-flex items-center justify-center rounded-md font-semibold transition-all focus-visible:outline-2 focus-visible:outline-offset-2 cursor-pointer select-none"

-- | Internal link styled as a button
buttonLink :: { variant :: ButtonVariant, size :: Size, lang :: Lang, route :: Route, extraClass :: String } -> String -> Html
buttonLink props label =
  spaLink props.lang props.route
    [ class_ (baseClass <> " " <> renderVariant props.variant <> " " <> renderSize props.size <> " " <> props.extraClass) ]
    [ text label ]

-- | Render an external link styled as a button
buttonLinkExternal :: { variant :: ButtonVariant, size :: Size, href :: String, extraClass :: String } -> String -> Html
buttonLinkExternal props label =
  el "a"
    [ href props.href
    , target_ "_blank"
    , rel_ "noopener noreferrer"
    , class_ (baseClass <> " " <> renderVariant props.variant <> " " <> renderSize props.size <> " " <> props.extraClass)
    ]
    [ text label ]
