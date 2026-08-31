-- | Site chrome lives in App.Ui.Templates.SiteShell (not this module).
module App.Layout.Header where

import App.Html (Html, text)
import Data.I18n (Lang)
import Data.Route (Route)

render :: Lang -> Route -> Html
render _ _ = text ""
