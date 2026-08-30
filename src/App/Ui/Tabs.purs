-- | Accessible tabs — DaisyUI tabs-box + Alpine (research/daisyui tab docs)
module App.Ui.Tabs
  ( TabItem
  , renderTabs
  ) where

import Prelude

import App.Alpine (Flag(..), ariaSelectedFlag, ariaSelectedNotFlag, onClick, setFlag, xCloak, xDataFlag, xShowFlag, xShowNotFlag)
import App.Html (Html, ariaControls, ariaLabel, attr, class_, el, id_, text, type_)

type TabItem =
  { id :: String
  , label :: String
  , content :: Html
  }

renderTabs :: { tab1 :: TabItem, tab2 :: TabItem } -> Html
renderTabs { tab1, tab2 } =
  el "div" [ xDataFlag TabActive true ]
    [ el "div"
        [ class_ "tabs tabs-box"
        , attr "role" "tablist"
        , ariaLabel "Tabs"
        ]
        [ el "button"
            [ type_ "button"
            , class_ "tab"
            , onClick (setFlag TabActive true)
            , attr "role" "tab"
            , ariaSelectedFlag TabActive
            , ariaControls ("panel_" <> tab1.id)
            ]
            [ text tab1.label ]
        , el "button"
            [ type_ "button"
            , class_ "tab"
            , onClick (setFlag TabActive false)
            , attr "role" "tab"
            , ariaSelectedNotFlag TabActive
            , ariaControls ("panel_" <> tab2.id)
            ]
            [ text tab2.label ]
        ]
    , el "div"
        [ id_ ("panel_" <> tab1.id)
        , xShowFlag TabActive
        , xCloak
        , attr "role" "tabpanel"
        , class_ "tab-content"
        ]
        [ tab1.content ]
    , el "div"
        [ id_ ("panel_" <> tab2.id)
        , xShowNotFlag TabActive
        , xCloak
        , attr "role" "tabpanel"
        , class_ "tab-content"
        ]
        [ tab2.content ]
    ]
