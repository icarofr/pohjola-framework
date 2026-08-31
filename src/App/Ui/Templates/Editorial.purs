-- | Editorial page — page hero, mission copy, values grid.
module App.Ui.Templates.Editorial
  ( renderEditorial
  ) where

import Prelude

import App.Html (Html, attr, class_, el, text)
import App.Ui.Container as Container
import App.Ui.Templates.Contract as Contract
import App.Ui.Templates.Types (EditorialSlots, ValueItem, ValuesSlots, valueItems)

renderEditorial :: EditorialSlots -> Html
renderEditorial slots =
  renderHero slots.heading
    <> renderMission slots.mission
    <> renderValues slots.values

renderHero :: String -> Html
renderHero heading =
  el "section"
    [ class_ "border-b border-base-200 bg-base-100"
    , attr Contract.marker Contract.editorialHero
    ]
    [ Container.container "max-w-6xl" "px-4 py-16 sm:px-6 sm:py-20"
        [ el "h1" [ class_ "max-w-3xl text-4xl font-bold sm:text-5xl" ]
            [ text heading ]
        ]
    ]

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
