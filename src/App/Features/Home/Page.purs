-- | Home page — entry point, orchestrates sections from View/ submodules
module App.Features.Home.Page where

import Prelude

import App.Features.Home.Components.CTA (renderCTA)
import App.Features.Home.Components.Hero (renderHero)
import App.Features.Home.Components.Services (renderServices)
import App.Html (Html)
import App.Layout.Page (staticPage)
import Data.I18n (Lang)
import Effect.Aff (Aff)
import App.Error (AppError)
import Data.Either (Either)

render :: Lang -> Aff (Either AppError Html)
render lang = staticPage (renderHero lang <> renderServices lang <> renderCTA lang)
