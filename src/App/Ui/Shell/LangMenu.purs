-- | Language menu — DaisyUI popover dropdown (no Daisy locale primitive).
module App.Ui.Shell.LangMenu
  ( LangMenuProps
  , langMenu
  , langMenuPopoverId
  ) where

import Prelude

import App.Html (Html, attr, class_, el, flag, href, id_, style_, text, type_)
import App.Layout.Icons (globeIcon)
import Data.I18n (Lang(..))
import Data.Route (Route, routeUrl)

type LangMenuProps =
  { currentLang :: Lang
  , currentRoute :: Route
  , ariaLabel :: String
  , currentLangLabel :: String
  }

langMenuPopoverId :: String
langMenuPopoverId = "header-lang-menu"

langMenu :: LangMenuProps -> Html
langMenu props =
  el "div" []
    [ el "button"
        [ type_ "button"
        , attr "popovertarget" langMenuPopoverId
        , style_ "anchor-name:--header-lang"
        , class_ "btn btn-ghost btn-sm gap-2"
        , attr "aria-label" props.ariaLabel
        ]
        [ globeIcon, text props.currentLangLabel ]
    , el "ul"
        [ class_ "dropdown menu w-40"
        , flag "popover"
        , id_ langMenuPopoverId
        , style_ "position-anchor:--header-lang"
        ]
        [ el "li" [] [ el "a" [ href (routeUrl En props.currentRoute) ] [ text "English" ] ]
        , el "li" [] [ el "a" [ href (routeUrl Fr props.currentRoute) ] [ text "Français" ] ]
        ]
    ]
