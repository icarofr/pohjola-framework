-- | Home page — page-level rendering, orchestrates Components/
module App.Features.Home.View where

import Prelude

import App.Features.Home.Components.CTA (renderCTA)
import App.Features.Home.Components.Hero (renderHero)
import App.Features.Home.Components.Metrics (renderMetrics)
import App.Features.Home.Components.Services (renderServices)
import App.Html (Html)
import Data.I18n (Lang)

renderHome :: Lang -> Html
renderHome lang = renderHero lang <> renderMetrics lang <> renderServices lang <> renderCTA lang

