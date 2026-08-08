-- | Contact page — entry point
module App.Features.Contact.Page where

import App.Features.Contact.View (renderContact)
import App.Html (Html)
import App.Layout.Page (staticPage)
import Data.I18n (Lang)
import Effect.Aff (Aff)
import App.Error (AppError)
import Data.Either (Either)

render :: Lang -> Aff (Either AppError Html)
render lang = staticPage (renderContact lang)
