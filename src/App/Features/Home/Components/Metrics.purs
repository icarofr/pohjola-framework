-- | Metrics / Guarantees section — displays framework invariants
module App.Features.Home.Components.Metrics where

import Prelude

import App.Html (Html, class_, el)
import App.Ui.Container (container)
import App.Ui.Stat (statGrid)
import Data.I18n (Lang)
import Data.Maybe (Maybe(..))

renderMetrics :: Lang -> Html
renderMetrics _lang =
  el "section" [ class_ "py-10 sm:py-12 border-b border-gray-200/80 dark:border-white/5 bg-base-100/50" ]
    [ container "max-w-7xl" ""
        [ statGrid
            [ { label: "Runtime Speed"
              , value: "100% Bun"
              , description: Just "Native zero-node runtime"
              }
            , { label: "Type Safety"
              , value: "PureScript"
              , description: Just "Totality & exhaustive ADT"
              }
            , { label: "Design Drift"
              , value: "0.00%"
              , description: Just "DESIGN.md + Layr guarded"
              }
            , { label: "JavaScript Shipped"
              , value: "0 kB"
              , description: Just "Alpine typed seams only"
              }
            ]
        ]
    ]
