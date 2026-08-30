-- | Page section — vertical rhythm without hero grid (DESIGN.md layout)
module App.Ui.Layout.PageSection
  ( PageSectionProps
  , pageSection
  , conversionSection
  ) where

import Prelude

import App.Html (Html, class_, el)
import App.Ui.Button (ButtonVariant(..), Size(..), buttonLink, buttonLinkExternal)
import App.Ui.Container (container)
import App.Ui.Layout.SectionHeader (Align(..), SectionHeaderProps, sectionHeader)
import App.Ui.Layout.Types (ActionTarget(..))
import Data.Maybe (Maybe(..))

type PageSectionProps =
  { header :: SectionHeaderProps
  , content :: Html
  , banded :: Boolean
  }

pageSection :: PageSectionProps -> Html
pageSection props =
  let
    bandClass =
      if props.banded then
        "bg-base-200"
      else
        "bg-base-100"
  in
    el "section" [ class_ (bandClass <> " py-16 sm:py-24") ]
      [ container "max-w-5xl" "space-y-12 w-full"
          [ sectionHeader props.header
          , props.content
          ]
      ]

conversionSection
  :: { heading :: String
     , body :: String
     , action :: { label :: String, target :: ActionTarget }
     }
  -> Html
conversionSection props =
  pageSection
    { header:
        { eyebrow: Nothing
        , title: props.heading
        , subtitle: Just props.body
        , align: Center
        }
    , content:
        el "div" [ class_ "flex justify-center" ]
          [ case props.action.target of
              Internal t ->
                buttonLink
                  { variant: ButtonPrimary
                  , size: Lg
                  , lang: t.lang
                  , route: t.route
                  , extraClass: ""
                  }
                  props.action.label
              External t ->
                buttonLinkExternal
                  { variant: ButtonPrimary
                  , size: Lg
                  , href: t.href
                  , extraClass: ""
                  }
                  props.action.label
          ]
    , banded: true
    }
