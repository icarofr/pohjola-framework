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
  el "section" [ class_ "py-12 sm:py-16 border-b border-zinc-200 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-900/20" ]
    [ container "max-w-7xl" ""
        [ statGrid
            [ { label: "Runtime Engine"
              , value: "100% Bun"
              , description: Just "Native zero-node runtime"
              }
            , { label: "Type Totality"
              , value: "PureScript"
              , description: Just "0 uncaught exceptions"
              }
            , { label: "Design System"
              , value: "0.00% Drift"
              , description: Just "DESIGN.md + Layr guarded"
              }
            , { label: "JS Shipped"
              , value: "0 kB"
              , description: Just "Alpine typed seams only"
              }
            ]
        ]
    ]
