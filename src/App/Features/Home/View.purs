-- | Home page view — fills Landing template slots only.
module App.Features.Home.View where

import App.Form (FormStatus)
import App.Html (Html)
import App.Ui.Templates.Render (renderPage)
import App.Ui.Templates.Types
  ( ActionTarget(..)
  , FeatureTriple
  , LandingSlots
  , PageTemplate(..)
  , landingFeatures
  , landingSlots
  )
import Data.Content (bookingUrl, services)
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe)
import Data.Route (Route(..))

renderHome :: Lang -> Maybe FormStatus -> Html
renderHome lang status =
  renderPage lang Home status (Landing (homeSlots lang))

homeSlots :: Lang -> LandingSlots
homeSlots lang =
  let
    d = dict lang
    features = serviceFeatureTriple lang
  in
    landingSlots
      { eyebrow: d.hero.eyebrow
      , headline: d.hero.headline
      , body: d.hero.body
      , ctaLabel: d.hero.ctaLabel
      , secondaryLabel: d.hero.secondaryLabel
      , primaryTarget: External { href: bookingUrl }
      , secondaryTarget: External { href: bookingUrl }
      }
      ( landingFeatures
          d.services.sectionEyebrow
          d.services.sectionHeadline
          d.services.sectionIntro
          features.one
          features.two
          features.three
      )
      { heading: d.cta.heading
      , body: d.cta.body
      , ctaLabel: d.cta.ctaLabel
      , target: External { href: bookingUrl }
      }

serviceFeatureTriple :: Lang -> FeatureTriple
serviceFeatureTriple lang =
  let
    copy = (dict lang).services.serviceCopy
    toFeature service =
      { title: (copy service.id).title, description: (copy service.id).description }
  in
    { one: toFeature services.one
    , two: toFeature services.two
    , three: toFeature services.three
    }
