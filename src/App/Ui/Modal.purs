-- | Accessible modal — DaisyUI modal + Alpine (research/daisyui modal docs)
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

renderModal :: ModalProps -> Html
renderModal props =
  el "div" [ xDataFlag ModalOpen false ]
    [ el "button"
        [ type_ "button"
        , class_ "btn btn-primary"
        , onClick (toggleFlag ModalOpen)
        , attr "aria-haspopup" "dialog"
        ]
        [ text props.triggerText ]
    , el "div"
        [ id_ props.id
        , xShowFlag ModalOpen
        , xCloak
        , onKeydownEscapeWindow (setFlag ModalOpen false)
        , class_ "modal modal-open"
        , attr "role" "dialog"
        , attr "aria-modal" "true"
        , ariaLabel props.title
        ]
        [ el "div"
            [ class_ "modal-box"
            , onClickOutside (setFlag ModalOpen false)
            ]
            [ el "h3" [ class_ "text-lg font-bold" ] [ text props.title ]
            , props.content
            , el "div" [ class_ "modal-action" ]
                [ el "button"
                    [ type_ "button"
                    , class_ "btn"
                    , onClick (setFlag ModalOpen false)
                    , ariaLabel "Close dialog"
                    ]
                    [ text "Close" ]
                ]
            ]
        , el "button"
            [ type_ "button"
            , class_ "modal-backdrop"
            , onClick (setFlag ModalOpen false)
            , ariaLabel "Close dialog"
            ]
            []
        ]
    ]
