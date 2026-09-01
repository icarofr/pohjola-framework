-- | Shared in-page headers — one recipe for title/subtitle rhythm across templates.
module App.Ui.Templates.PageHeader
  ( CenteredHeader
  , renderBand
  , renderCentered
  ) where

import Prelude

import App.Html (Html, attr, class_, el, text)
import App.Ui.Container as Container
import App.Ui.Templates.Contract as Contract

type CenteredHeader =
  { title :: String
  , subtitle :: String
  }

-- | Centered page title + lead (Hub, Feed, Schedule).
renderCentered :: CenteredHeader -> Html
renderCentered slots =
  el "header"
    [ class_ "mx-auto max-w-2xl text-center"
    , attr Contract.marker Contract.pageHeaderCentered
    ]
    [ el "h1" [ class_ "text-4xl font-bold sm:text-5xl" ] [ text slots.title ]
    , el "p" [ class_ "mt-4 text-lg opacity-70" ] [ text slots.subtitle ]
    ]

-- | Left-aligned title band with bottom border (Editorial hero).
renderBand :: Array Html -> String -> Html
renderBand prefix title =
  el "header"
    [ class_ "border-b border-base-200 bg-base-100"
    , attr Contract.marker Contract.pageHeaderBand
    ]
    [ Container.container "max-w-6xl" "px-4 py-16 sm:px-6 sm:py-20"
        ( prefix
            <>
              [ el "h1" [ class_ "max-w-3xl text-4xl font-bold sm:text-5xl" ]
                  [ text title ]
              ]
        )
    ]
