-- | Shared in-page headers — one recipe for title/subtitle rhythm across templates.
module App.Ui.Templates.PageHeader
  ( CenteredHeader
  , renderBand
  , renderBreadcrumbs
  , renderCentered
  , renderDetail
  ) where

import Prelude

import App.Html (Html, attr, class_, el, text)
import App.Ui.Breadcrumbs as Breadcrumbs
import App.Ui.Container as Container
import App.Ui.Templates.Contract as Contract
import App.Ui.Templates.Types (BreadcrumbItem)
import Data.Array (length)
import Data.I18n (Lang)
import Data.Route (Route)

type CenteredHeader =
  { title :: String
  , subtitle :: String
  }

headingClass :: String
headingClass = "text-4xl font-bold sm:text-5xl"

leadClass :: String
leadClass = "mt-4 text-lg opacity-70"

-- | Breadcrumb row above a page header (Hub, Editorial).
renderBreadcrumbs :: String -> Lang -> Route -> Array BreadcrumbItem -> Html
renderBreadcrumbs markerName lang route items =
  if length items == 0 then
    el "span" [] []
  else
    el "div"
      [ class_ "my-4"
      , attr Contract.marker markerName
      ]
      [ Breadcrumbs.breadcrumbs lang route items ]

-- | Centered page title + lead (Hub, Feed, Schedule).
renderCentered :: CenteredHeader -> Html
renderCentered slots =
  el "header"
    [ class_ "mx-auto max-w-2xl text-center"
    , attr Contract.marker Contract.pageHeaderCentered
    ]
    [ el "h1" [ class_ headingClass ] [ text slots.title ]
    , el "p" [ class_ leadClass ] [ text slots.subtitle ]
    ]

-- | Left-aligned title band with bottom border (Editorial hero).
renderBand :: Array Html -> String -> Html
renderBand prefix title =
  el "div" [ attr Contract.marker Contract.editorialHero ]
    [ el "header"
        [ class_ "border-b border-base-200 bg-base-100"
        , attr Contract.marker Contract.pageHeaderBand
        ]
        [ Container.container "max-w-6xl" "px-4 py-16 sm:px-6 sm:py-20"
            ( prefix
                <>
                  [ el "h1" [ class_ ("max-w-3xl " <> headingClass) ]
                      [ text title ]
                  ]
            )
        ]
    ]

-- | Article detail header — eyebrow prefix + unified h1 scale.
renderDetail :: String -> Array Html -> String -> Html
renderDetail markerName prefix title =
  el "div" [ attr Contract.marker markerName ]
    [ el "header"
        [ class_ "max-w-3xl"
        , attr Contract.marker Contract.pageHeaderDetail
        ]
        ( prefix
            <>
              [ el "h1" [ class_ ("mt-4 " <> headingClass) ] [ text title ] ]
        )
    ]
