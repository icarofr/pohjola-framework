-- | Closed landing blueprint — hero + page sections + conversion
module App.Ui.Layout.LandingPage
  ( LandingPageBlueprint
  , LandingPageSection
  , landingPage
  ) where

import App.Html (Html, el, text)
import App.Ui.Layout.ConversionCta (ConversionCtaProps, conversionCta)
import App.Ui.Layout.Hero (HeroProps, hero)
import App.Ui.Layout.PageSection (pageSection)
import App.Ui.Layout.SectionHeader (Align(..))
import Data.Maybe (Maybe(..))

type LandingPageSection =
  { title :: String
  , subtitle :: Maybe String
  , content :: Html
  }

type LandingPageBlueprint =
  { hero :: HeroProps
  , primarySection :: LandingPageSection
  , secondarySection :: Maybe LandingPageSection
  , conversion :: ConversionCtaProps
  }

landingSection :: LandingPageSection -> Boolean -> Html
landingSection sec banded =
  pageSection
    { header:
        { eyebrow: Nothing
        , title: sec.title
        , subtitle: sec.subtitle
        , align: Center
        }
    , content: sec.content
    , banded: banded
    }

landingPage :: LandingPageBlueprint -> Html
landingPage page =
  el "div" []
    [ hero page.hero
    , landingSection page.primarySection false
    , case page.secondarySection of
        Just sec -> landingSection sec true
        Nothing -> text ""
    , conversionCta page.conversion
    ]
