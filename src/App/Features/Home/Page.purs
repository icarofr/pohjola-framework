-- | Home page — entry point
module App.Features.Home.Page where

import App.Error (AppError)
import App.Features.Home.View (renderHome)
import App.Form (FormStatus)
import App.Html (Html)
import App.Layout.Page (staticPage)
import Data.Either (Either)
import Data.I18n (Lang)
import Data.Maybe (Maybe)
import Effect.Aff (Aff)

render :: Lang -> Maybe FormStatus -> Aff (Either AppError Html)
render lang status = staticPage (renderHome lang status)
