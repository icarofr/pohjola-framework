-- | Home page — entry point
module App.Features.Home.Page where

import App.Error (AppError)
import App.Features.Home.View (renderHome)
import App.Html (Html)
import App.Layout.Page (staticPage)
import Data.Either (Either)
import Data.I18n (Lang)
import Effect.Aff (Aff)

render :: Lang -> Aff (Either AppError Html)
render lang = staticPage (renderHome lang)
