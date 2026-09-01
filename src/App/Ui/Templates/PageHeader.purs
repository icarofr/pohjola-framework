-- | Shared in-page headers — DaisyUI breadcrumbs + divider, left-aligned title stack.
-- | Hero is reserved for Landing only (vendor/daisyui/.../hero.md).
module App.Ui.Templates.PageHeader
  ( PageHeaderSlots
  , breadcrumbHere
  , breadcrumbLink
  , breadcrumbHome
  , pageHeaderSlots
  , render
  , renderDetail
  ) where

import Prelude

import App.Html (Html, attr, class_, el, text)
import App.Ui.Breadcrumbs as Breadcrumbs
import App.Ui.Divider as Divider
import App.Ui.TextTone as TextTone
import App.Ui.Templates.Contract as Contract
import App.Ui.Templates.Types (ActionTarget(..), BreadcrumbItem)
import Data.Array (length)
import Data.I18n (Lang)
import Data.Maybe (Maybe(..), maybe)
import Data.Route (Route(..))

type PageHeaderSlots =
  { title :: String
  , subtitle :: Maybe String
  , breadcrumbs :: Array BreadcrumbItem
  }

pageHeaderSlots :: String -> Maybe String -> Array BreadcrumbItem -> PageHeaderSlots
pageHeaderSlots title subtitle breadcrumbs =
  { title, subtitle, breadcrumbs }

breadcrumbHome :: Lang -> String -> BreadcrumbItem
breadcrumbHome lang homeLabel =
  { label: homeLabel
  , target: Just (Internal { lang, route: Home })
  }

breadcrumbHere :: String -> BreadcrumbItem
breadcrumbHere label =
  { label, target: Nothing }

breadcrumbLink :: Lang -> Route -> String -> BreadcrumbItem
breadcrumbLink lang route label =
  { label, target: Just (Internal { lang, route }) }

render :: Lang -> Route -> PageHeaderSlots -> Html
render lang route slots =
  renderShell
    [ renderBreadcrumbs lang route slots.breadcrumbs
    , renderBody [] slots
    ]

renderDetail :: Lang -> Route -> Array Html -> PageHeaderSlots -> Html
renderDetail lang route prefix slots =
  renderShell
    [ renderBreadcrumbs lang route slots.breadcrumbs
    , el "div"
        [ class_ "max-w-3xl"
        , attr Contract.marker Contract.pageHeaderBody
        , attr Contract.marker Contract.pageHeaderDetail
        ]
        ( prefix
            <>
              [ el "h1" [ class_ titleClass ] [ text slots.title ]
              , renderSubtitle slots.subtitle
              ]
        )
    ]

renderShell :: Array Html -> Html
renderShell children =
  el "header"
    [ attr Contract.marker Contract.pageHeader
    ]
    (children <> [ el "div" [ class_ "mt-8" ] [ Divider.divider ] ])

renderBody :: Array Html -> PageHeaderSlots -> Html
renderBody prefix slots =
  el "div"
    [ class_ "max-w-3xl"
    , attr Contract.marker Contract.pageHeaderBody
    ]
    ( prefix
        <>
          [ el "h1" [ class_ titleClass ] [ text slots.title ]
          , renderSubtitle slots.subtitle
          ]
    )

titleClass :: String
titleClass = "text-3xl font-bold tracking-tight sm:text-4xl"

renderBreadcrumbs :: Lang -> Route -> Array BreadcrumbItem -> Html
renderBreadcrumbs lang route items =
  if length items == 0 then
    el "span" [] []
  else
    el "div"
      [ class_ "mb-4 max-w-full overflow-x-auto"
      , attr Contract.marker Contract.pageHeaderBreadcrumbs
      ]
      [ Breadcrumbs.breadcrumbs lang route items ]

renderSubtitle :: Maybe String -> Html
renderSubtitle = maybe (el "span" [] []) renderSubtitleText

renderSubtitleText :: String -> Html
renderSubtitleText subtitle =
  el "p" [ class_ ("mt-3 text-lg " <> TextTone.toneClass TextTone.Copy) ]
    [ text subtitle ]
