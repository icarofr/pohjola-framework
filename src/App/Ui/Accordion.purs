-- | Accessible accordion — DaisyUI collapse + Alpine (research/daisyui collapse docs)
module App.Ui.Accordion
  ( AccordionItem
  , renderAccordion
  ) where

import Prelude

import App.Alpine (Flag(..), ariaExpandedFlag, classWhenFlag, onClick, toggleFlag, xCloak, xDataFlag, xShowFlag)
import App.Html (Html, ariaControls, attr, class_, el, id_, text, type_)

type AccordionItem =
  { id :: String
  , title :: String
  , content :: Html
  , defaultOpen :: Boolean
  }

renderAccordion :: Array AccordionItem -> Html
renderAccordion items =
  el "div" [ class_ "space-y-2" ] (map renderItem items)
  where
  renderItem item =
    let
      panelId = "panel_" <> item.id
    in
      el "div"
        [ xDataFlag AccordionOpen item.defaultOpen
        , class_ "collapse collapse-arrow bg-base-100 border border-base-300"
        , classWhenFlag "collapse-open" AccordionOpen
        ]
        [ el "button"
            [ type_ "button"
            , class_ "collapse-title text-lg font-medium"
            , onClick (toggleFlag AccordionOpen)
            , ariaExpandedFlag AccordionOpen
            , ariaControls panelId
            ]
            [ text item.title ]
        , el "div"
            [ id_ panelId
            , xShowFlag AccordionOpen
            , xCloak
            , class_ "collapse-content"
            , attr "role" "region"
            ]
            [ item.content ]
        ]
