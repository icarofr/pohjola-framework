-- | Accessible Tabs component (ADR-000, ADR-008)
-- |
-- | Tab navigation with ARIA semantics, keyboard navigation, and panel switching.
module App.Ui.Tabs
  ( TabItem
  , renderTabs
  ) where

import Prelude

import App.Alpine (Flag(..), onClick, setFlag, xCloak, xDataFlag, xShowFlag, xShowNotFlag)
import App.Html (Html, ariaControls, ariaLabel, attr, class_, el, id_, text, type_)

type TabItem =
  { id :: String
  , label :: String
  , content :: Html
  }

-- | Render an accessible two-panel tab control.
renderTabs :: { tab1 :: TabItem, tab2 :: TabItem } -> Html
renderTabs { tab1, tab2 } =
  el "div" [ xDataFlag TabActive true, class_ "space-y-4" ]
    [ -- Tab List
      el "div"
        [ class_ "flex space-x-1 rounded-xl bg-slate-100 dark:bg-white/5 p-1 border border-slate-200/80 dark:border-white/10"
        , attr "role" "tablist"
        , ariaLabel "Tabs"
        ]
        [ el "button"
            [ type_ "button"
            , class_ "flex-1 rounded-lg px-3 py-2 text-xs font-semibold font-mono transition-colors text-slate-700 dark:text-slate-300 hover:text-blue-600 dark:hover:text-white hover:bg-white/50 dark:hover:bg-white/10 cursor-pointer"
            , onClick (setFlag TabActive true)
            , attr "role" "tab"
            , ariaControls ("panel_" <> tab1.id)
            ]
            [ text tab1.label ]
        , el "button"
            [ type_ "button"
            , class_ "flex-1 rounded-lg px-3 py-2 text-xs font-semibold font-mono transition-colors text-slate-700 dark:text-slate-300 hover:text-blue-600 dark:hover:text-white hover:bg-white/50 dark:hover:bg-white/10 cursor-pointer"
            , onClick (setFlag TabActive false)
            , attr "role" "tab"
            , ariaControls ("panel_" <> tab2.id)
            ]
            [ text tab2.label ]
        ]

    -- Tab Panels
    , el "div" [ class_ "rounded-2xl border border-slate-200/80 dark:border-white/10 bg-white dark:bg-slate-900 p-6" ]
        [ el "div"
            [ id_ ("panel_" <> tab1.id)
            , xShowFlag TabActive
            , xCloak
            , attr "role" "tabpanel"
            , class_ "text-sm text-slate-600 dark:text-slate-300 leading-relaxed"
            ]
            [ tab1.content ]
        , el "div"
            [ id_ ("panel_" <> tab2.id)
            , xShowNotFlag TabActive
            , xCloak
            , attr "role" "tabpanel"
            , class_ "text-sm text-slate-600 dark:text-slate-300 leading-relaxed"
            ]
            [ tab2.content ]
        ]
    ]
