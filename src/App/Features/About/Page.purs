-- | About page — entry point
module App.Features.About.Page where

import App.Features.About.View (renderAbout)
import App.Html (Html)
import App.Layout.Page (staticPage)
import Data.I18n (Lang)
import Effect.Aff (Aff)
import App.Error (AppError)
import Data.Either (Either)

render :: Lang -> Aff (Either AppError Html)
render lang = staticPage (renderAbout lang)
