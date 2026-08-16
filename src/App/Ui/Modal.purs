-- | Accessible Modal Dialog component (ADR-000, ADR-008)
-- |
-- | Zero custom JS — driven by typed Alpine constructors with backdrop click,
-- | Escape key handling, and ARIA dialog semantics.
module App.Ui.Modal
  ( ModalProps
  , renderModal
  ) where

import App.Alpine (Flag(..), onClick, onClickOutside, onKeydownEscapeWindow, setFlag, toggleFlag, xCloak, xDataFlag, xShowFlag)
import App.Html (Html, ariaLabel, attr, class_, el, id_, text, type_)

type ModalProps =
  { id :: String
  , triggerText :: String
  , title :: String
  , content :: Html
  }

-- | Render an accessible modal dialog with backdrop blur and Escape dismiss.
renderModal :: ModalProps -> Html
renderModal props =
  el "div" [ xDataFlag ModalOpen false, class_ "inline-block" ]
    [ -- Trigger button
      el "button"
        [ type_ "button"
        , class_ "inline-flex items-center justify-center rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline-2 focus-visible:outline-blue-600 transition-colors cursor-pointer"
        , onClick (toggleFlag ModalOpen)
        , attr "aria-haspopup" "dialog"
        ]
        [ text props.triggerText ]

    -- Backdrop and Dialog Panel
    , el "div"
        [ id_ props.id
        , xShowFlag ModalOpen
        , xCloak
        , onKeydownEscapeWindow (setFlag ModalOpen false)
        , class_ "fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs"
        , attr "role" "dialog"
        , attr "aria-modal" "true"
        , ariaLabel props.title
        ]
        [ el "div"
            [ class_ "w-full max-w-lg rounded-2xl bg-white dark:bg-slate-900 p-6 shadow-2xl border border-slate-200/80 dark:border-white/10 ring-1 ring-black/5 space-y-4"
            , onClickOutside (setFlag ModalOpen false)
            ]
            [ el "div" [ class_ "flex items-center justify-between border-b border-slate-100 dark:border-white/10 pb-3" ]
                [ el "h3" [ class_ "font-display text-lg font-bold text-slate-900 dark:text-white" ]
                    [ text props.title ]
                , el "button"
                    [ type_ "button"
                    , class_ "rounded-lg p-1.5 text-slate-400 hover:text-slate-600 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-white/10 transition-colors cursor-pointer"
                    , onClick (setFlag ModalOpen false)
                    , ariaLabel "Close dialog"
                    ]
                    [ text "✕" ]
                ]
            , el "div" [ class_ "text-sm text-slate-600 dark:text-slate-300 leading-relaxed" ]
                [ props.content ]
            ]
        ]
    ]
