-- | Toast notification — DaisyUI toast + alert (research/daisyui toast docs)
module App.Ui.Toast
  ( ToastProps
  , renderToast
  ) where

import App.Alpine (Flag(..), onClick, setFlag, xCloak, xDataFlag, xShowFlag)
import App.Html (Html, ariaLabel, attr, class_, el, id_, text, type_)

type ToastProps =
  { id :: String
  , message :: String
  , isSuccess :: Boolean
  }

renderToast :: ToastProps -> Html
renderToast props =
  let
    alertClass =
      if props.isSuccess then
        "alert alert-success"
      else
        "alert alert-error"
  in
    el "div" [ class_ "toast toast-end toast-bottom" ]
      [ el "div"
          [ id_ props.id
          , xDataFlag ToastVisible true
          , xShowFlag ToastVisible
          , xCloak
          , class_ alertClass
          , attr "role" "status"
          ]
          [ el "span" [] [ text props.message ]
          , el "button"
              [ type_ "button"
              , class_ "btn btn-sm btn-circle btn-ghost"
              , onClick (setFlag ToastVisible false)
              , ariaLabel "Dismiss notification"
              ]
              [ text "✕" ]
          ]
      ]
