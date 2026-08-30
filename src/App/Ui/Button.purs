-- | Button intents — map to Daisy classes in this module only (ADR-012).
-- | ButtonSecondary is a neutral/outline CTA, not Daisy accent secondary.
module App.Ui.Button where

import Prelude

import App.Alpine (spaLink)
import App.Html (Html, class_, el, href, rel_, target_, text)
import Data.I18n (Lang)
import Data.Route (Route)

data ButtonVariant = ButtonPrimary | ButtonSecondary | ButtonOutline | ButtonGhost | ButtonInverted | ButtonLink
type Variant = ButtonVariant

data Size = Sm | Md | Lg

renderVariant :: ButtonVariant -> String
renderVariant = case _ of
  ButtonPrimary -> "btn-primary"
  ButtonSecondary -> "btn-outline"
  ButtonOutline -> "btn-outline"
  ButtonGhost -> "btn-ghost"
  ButtonInverted -> "btn-neutral"
  ButtonLink -> "btn-link"

renderSize :: Size -> String
renderSize = case _ of
  Sm -> "btn-sm text-xs"
  Md -> "btn-md text-sm"
  Lg -> "btn-lg text-base"

baseClass :: String
baseClass = "btn"

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
