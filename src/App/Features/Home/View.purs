-- | Home page view — strictly rendered via closed LandingPage blueprint
module App.Features.Home.View where

import Prelude

import App.Html (Html)
import App.Ui as Ui
import Data.Content (Service, bookingUrl, services)
import Data.I18n (Lang, dict)
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
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
          , secondaryAction: Just { label: d.hero.secondaryLabel, target: Ui.Internal { lang, route: PostList } }
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
          , action: { label: d.cta.ctaLabel, target: Ui.External { href: bookingUrl } }
          }
      }

renderServiceCard :: Lang -> Service -> Html
renderServiceCard lang service =
  let
    copy = (dict lang).services.serviceCopy service.id
  in
    Ui.actionCard
      { tag: Nothing
      , imageUrl: Just { url: service.imageUrl, alt: copy.title, width: service.imageWidth, height: service.imageHeight }
      , title: copy.title
      , description: copy.description
      , action: { label: copy.actionLabel, target: serviceTarget lang service }
      }

serviceTarget :: Lang -> Service -> Ui.ActionTarget
serviceTarget lang service = case unwrap service.id of
  "service-1" -> Ui.Internal { lang, route: About }
  "service-2" -> Ui.Internal { lang, route: PostList }
  "service-3" -> Ui.Internal { lang, route: Contact }
  _ -> Ui.Internal { lang, route: About }
