-- | Guarantees page — entry point
module App.Features.Guarantees.Page where

import App.Error (AppError)
import App.Features.Guarantees.View (renderGuarantees)
import App.Form (FormStatus)
import App.Html (Html)
import App.Layout.Page (staticPage)
import Data.Either (Either)
import Data.I18n (Lang)
import Data.Maybe (Maybe)
import Effect.Aff (Aff)

render :: Lang -> Maybe FormStatus -> Aff (Either AppError Html)
render lang status = staticPage (renderGuarantees lang status)
