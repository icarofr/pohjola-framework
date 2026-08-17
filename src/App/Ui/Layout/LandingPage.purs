-- | Closed Landing Page Blueprint — enforces rigid rhythm, bounded sections, and slot safety
module App.Ui.Layout.LandingPage
  ( LandingPageBlueprint
  , LandingPageSection
  , landingPage
  ) where

import App.Html (Html, class_, el, text)
import App.Ui.Container (container)
import App.Ui.Layout.ConversionCta (ConversionCtaProps, conversionCta)
import App.Ui.Layout.Hero (HeroProps, hero)
import App.Ui.Layout.SectionHeader (Align(..), sectionHeader)
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

-- | Render a landing page blueprint enforcing rigid layout geometry and slot order
landingPage :: LandingPageBlueprint -> Html
landingPage page =
  el "div" [ class_ "flex flex-col w-full" ]
    [ hero page.hero
    , el "section" [ class_ "py-16 sm:py-24 border-y border-base-300 bg-base-200/40" ]
        [ container "max-w-5xl" "space-y-10"
            [ sectionHeader
                { eyebrow: Nothing
                , title: page.primarySection.title
                , subtitle: page.primarySection.subtitle
                , align: Center
                }
            , page.primarySection.content
            ]
        ]
    , case page.secondarySection of
        Just sec ->
          el "section" [ class_ "py-16 sm:py-24 border-b border-base-300" ]
            [ container "max-w-5xl" "space-y-10"
                [ sectionHeader
                    { eyebrow: Nothing
                    , title: sec.title
                    , subtitle: sec.subtitle
                    , align: Center
                    }
                , sec.content
                ]
            ]
        Nothing -> text ""
    , conversionCta page.conversion
    ]
