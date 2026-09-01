-- | Editorial page — page hero, mission copy, values grid.
module App.Ui.Templates.Editorial
  ( renderEditorial
  ) where

import Prelude

import App.Html (Html, attr, class_, el, text)
import App.Ui.Breadcrumbs as Breadcrumbs
import App.Ui.Container as Container
import App.Ui.Templates.Contract as Contract
import App.Ui.Templates.PageHeader as PageHeader
import App.Ui.Templates.Types
  ( BreadcrumbItem
  , EditorialSlots
  , ValueItem
  , ValuesSlots
  , valueItems
  )
import Data.Array (length)
import Data.I18n (Lang)
import Data.Route (Route)

renderEditorial :: Lang -> Route -> EditorialSlots -> Html
renderEditorial lang route slots =
  renderHero lang route slots.heading slots.breadcrumbs
    <> renderMission slots.mission
    <> renderValues slots.values

renderHero :: Lang -> Route -> String -> Array BreadcrumbItem -> Html
renderHero lang route heading breadcrumbs =
  PageHeader.renderBand
    [ maybeBreadcrumbs lang route breadcrumbs ]
    heading

maybeBreadcrumbs :: Lang -> Route -> Array BreadcrumbItem -> Html
maybeBreadcrumbs lang route items =
  if length items == 0 then
    el "span" [] []
  else
    el "div"
      [ class_ "my-4"
      , attr Contract.marker Contract.editorialBreadcrumbs
      ]
      [ Breadcrumbs.breadcrumbs lang route items ]

renderMission
  :: { heading :: String
     , lead :: String
     , body :: String
     }
  -> Html
renderMission mission =
  el "section"
    [ class_ "py-16 sm:py-20"
    , attr Contract.marker Contract.editorialMission
    ]
    [ Container.container "max-w-6xl" "px-4 sm:px-6"
        [ el "div" [ class_ "max-w-3xl" ]
            [ el "h2" [ class_ "text-3xl font-bold" ] [ text mission.heading ]
            , el "p" [ class_ "mt-6 text-xl opacity-80" ] [ text mission.lead ]
            , el "p" [ class_ "mt-6 text-base opacity-70" ] [ text mission.body ]
            ]
        ]
    ]

renderValues :: ValuesSlots -> Html
renderValues values =
  el "section"
    [ class_ "border-t border-base-200 py-16 sm:py-20"
    , attr Contract.marker Contract.editorialValues
    ]
    [ Container.container "max-w-6xl" "px-4 sm:px-6"
        [ el "div" [ class_ "max-w-2xl" ]
            [ el "h2" [ class_ "text-3xl font-bold" ] [ text values.heading ]
            , el "p" [ class_ "mt-4 opacity-70" ] [ text values.intro ]
            ]
        , el "dl" [ class_ "mt-12 grid gap-10 sm:grid-cols-2 lg:grid-cols-3" ]
            (map renderValueItem (valueItems values.items))
        ]
    ]

renderValueItem :: ValueItem -> Html
renderValueItem item =
  el "div" []
    [ el "dt" [ class_ "font-semibold" ] [ text item.title ]
    , el "dd" [ class_ "mt-2 text-sm opacity-70" ] [ text item.description ]
    ]
