-- | DaisyUI button — vendor/daisyui/skills/daisyui/components/button.md
module App.Ui.Button where

import Prelude

import App.Alpine (spaLink)
import App.Html (Html, class_, el, href, rel_, target_, text)
import Data.I18n (Lang)
import Data.Route (Route)

data ButtonVariant
  = ButtonPrimary
  | ButtonNeutral
  | ButtonOutline
  | ButtonGhost
  | ButtonLink

data Size = Sm | Md | Lg

renderVariant :: ButtonVariant -> String
renderVariant = case _ of
  ButtonPrimary -> "btn-primary"
  ButtonNeutral -> "btn-neutral"
  ButtonOutline -> "btn-outline"
  ButtonGhost -> "btn-ghost"
  ButtonLink -> "btn-link"

renderSize :: Size -> String
renderSize = case _ of
  Sm -> "btn-sm"
  Md -> "btn-md"
  Lg -> "btn-lg"

btnClass :: ButtonVariant -> Size -> String
btnClass v s = "btn " <> renderVariant v <> " " <> renderSize s

buttonLink :: { variant :: ButtonVariant, size :: Size, lang :: Lang, route :: Route } -> String -> Html
buttonLink props label =
  spaLink props.lang props.route
    [ class_ (btnClass props.variant props.size) ]
    [ text label ]

buttonLinkExternal :: { variant :: ButtonVariant, size :: Size, href :: String } -> String -> Html
buttonLinkExternal props label =
  el "a"
    [ href props.href
    , target_ "_blank"
    , rel_ "noopener noreferrer"
    , class_ (btnClass props.variant props.size)
    ]
    [ text label ]
