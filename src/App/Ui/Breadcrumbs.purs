-- | DaisyUI breadcrumbs — vendor/daisyui/skills/daisyui/components/breadcrumbs.md
module App.Ui.Breadcrumbs
  ( breadcrumbs
  ) where

import Prelude

import App.Alpine (navLink)
import App.Html (Html, attr, class_, el, href, text)
import App.Ui.Templates.Contract as Contract
import App.Ui.Templates.Types (ActionTarget(..), BreadcrumbItem)
import Data.I18n (Lang)
import Data.Maybe (Maybe(..))
import Data.Route (Route)

breadcrumbs :: Lang -> Route -> Array BreadcrumbItem -> Html
breadcrumbs _ _ [] = el "span" [] []
breadcrumbs lang current items =
  el "nav"
    [ class_ "breadcrumbs text-sm"
    , attr Contract.marker Contract.hubBreadcrumbs
    ]
    [ el "ul" [] (map (renderItem lang current) items) ]

renderItem :: Lang -> Route -> BreadcrumbItem -> Html
renderItem _ current { label, target } =
  el "li" [] case target of
    Nothing ->
      [ text label ]
    Just (Internal { lang: linkLang, route }) ->
      [ navLink { lang: linkLang, current, target: route }
          [ class_ "link link-hover" ]
          [ text label ]
      ]
    Just (External { href: url }) ->
      [ el "a" [ href url, class_ "link link-hover" ] [ text label ] ]
