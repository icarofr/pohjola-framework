-- | DaisyUI theme-controller + swap (research/daisyui theme-controller docs).
module App.Ui.Shell.ThemeControl
  ( ThemeControlProps
  , themeControl
  , themeSwapClass
  ) where

import Prelude

import App.Html (Html, attr, class_, el, id_, type_)
import App.Layout.Icons (moonIcon, sunIcon)
import App.Theme (daisyThemeDark, siteThemeToggleId)

type ThemeControlProps = { ariaLabel :: String }

themeSwapClass :: String
themeSwapClass = "swap swap-rotate btn btn-ghost btn-circle"

themeControl :: ThemeControlProps -> Html
themeControl props =
  el "label" [ class_ themeSwapClass, attr "aria-label" props.ariaLabel ]
    [ el "input"
        [ type_ "checkbox"
        , class_ "theme-controller"
        , id_ siteThemeToggleId
        , attr "value" daisyThemeDark
        ]
        []
    , el "span" [ class_ "swap-off" ] [ sunIcon ]
    , el "span" [ class_ "swap-on" ] [ moonIcon ]
    ]
