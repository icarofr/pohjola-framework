-- | Route and external action links — DaisyUI btn recipes only.
module App.Ui.Templates.ActionLink
  ( actionTarget
  , navAction
  , titleLink
  ) where

import Prelude

import App.Alpine (spaLink)
import App.Html (Attr, Html, class_, el, href, text)
import App.Ui.Button (ButtonVariant, Size, buttonLink, buttonLinkExternal)
import App.Ui.Templates.Types (ActionTarget(..))
import Data.I18n (Lang)
import Data.Route (Route)

actionTarget :: ButtonVariant -> Size -> ActionTarget -> String -> Html
actionTarget variant size target label = case target of
  Internal { lang, route } ->
    buttonLink { variant, size, lang, route } label
  External { href: url } ->
    buttonLinkExternal { variant, size, href: url } label

titleLink :: ActionTarget -> String -> Html
titleLink target label = case target of
  Internal { lang, route } ->
    spaLink lang route [ class_ "link link-hover" ] [ text label ]
  External { href: url } ->
    el "a" [ href url, class_ "link link-hover" ] [ text label ]

navAction :: Lang -> Route -> Array Attr -> Array Html -> Html
navAction lang route attrs children =
  spaLink lang route ([ class_ "btn btn-ghost btn-sm" ] <> attrs) children
