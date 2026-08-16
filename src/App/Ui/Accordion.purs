-- | Accessible Accordion component (ADR-000, ADR-008)
-- |
-- | Expandable/collapsible accordion panels with full ARIA state binding.
module App.Ui.Accordion
  ( AccordionItem
  , renderAccordion
  ) where

import Prelude

import App.Alpine (Flag(..), ariaExpandedFlag, onClick, toggleFlag, xCloak, xDataFlag, xShowFlag)
import App.Html (Html, ariaControls, attr, class_, el, id_, text, type_)

type AccordionItem =
  { id :: String
  , title :: String
  , content :: Html
  , defaultOpen :: Boolean
  }

-- | Render an accordion group with accessible toggle controls.
renderAccordion :: Array AccordionItem -> Html
renderAccordion items =
  el "div" [ class_ "divide-y divide-slate-200/80 dark:divide-white/10 rounded-2xl border border-slate-200/80 dark:border-white/10 bg-white dark:bg-slate-900 overflow-hidden" ]
    (map renderItem items)
  where
  renderItem item =
    let
      panelId = "panel_" <> item.id
    in
      el "div" [ xDataFlag AccordionOpen item.defaultOpen, class_ "group" ]
        [ el "button"
            [ type_ "button"
            , class_ "flex w-full items-center justify-between px-6 py-4 text-left font-display font-semibold text-slate-900 dark:text-white hover:bg-slate-50 dark:hover:bg-white/5 transition-colors cursor-pointer"
            , onClick (toggleFlag AccordionOpen)
            , ariaExpandedFlag AccordionOpen
            , ariaControls panelId
            ]
            [ el "span" [] [ text item.title ]
            , el "span" [ class_ "text-xs font-mono text-slate-400 dark:text-slate-500" ] [ text "+" ]
            ]
        , el "div"
            [ id_ panelId
            , xShowFlag AccordionOpen
            , xCloak
            , class_ "px-6 pb-4 pt-1 text-sm text-slate-600 dark:text-slate-300 leading-relaxed border-t border-slate-100 dark:border-white/5"
            , attr "role" "region"
            ]
            [ item.content ]
        ]
