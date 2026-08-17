-- | Home page view — strictly rendered via closed LandingPage blueprint
module App.Features.Home.View where

import Prelude

import App.Html (Html)
import App.Ui as Ui
import Data.Content (Service, bookingUrl, services)
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe(..))
import Data.Route (Route(..))

renderHome :: Lang -> Html
renderHome lang =
  let
    d = dict lang
  in
    Ui.landingPage
      { hero:
          { eyebrow: Nothing
          , title: d.hero.headline
          , body: d.hero.body
          , primaryAction: { label: d.hero.ctaLabel, target: Ui.Internal { lang, route: About } }
          , secondaryAction: Just { label: d.contact.sourceButton, target: Ui.External { href: bookingUrl } }
          }
      , primarySection:
          { title: d.services.sectionTitle
          , subtitle: Nothing
          , content: Ui.grid3 (map (renderServiceCard lang) services)
          }
      , secondarySection: Nothing
      , conversion:
          { heading: d.cta.heading
          , body: d.cta.body
          , action: { label: d.cta.ctaLabel, target: Ui.Internal { lang, route: About } }
          }
      }

renderServiceCard :: Lang -> Service -> Html
renderServiceCard lang service =
  let
    d = (dict lang).services
    copy = d.serviceCopy service.id
  in
    Ui.actionCard
      { tag: Nothing
      , imageUrl: Just { url: service.imageUrl, alt: copy.title, width: service.imageWidth, height: service.imageHeight }
      , title: copy.title
      , description: copy.description
      , action: { label: d.bookButton <> " →", target: Ui.Internal { lang, route: About } }
      }
