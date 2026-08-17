-- | Pure DaisyUI SectionHeader layout template
module App.Ui.Layout.SectionHeader where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.Badge (BadgeVariant(..))
import App.Ui.Badge as Badge
import Data.Maybe (Maybe(..))

data Align = Left | Center

derive instance eqAlign :: Eq Align

type SectionHeaderProps =
  { eyebrow :: Maybe String
  , title :: String
  , subtitle :: Maybe String
  , align :: Align
  }

-- | Render a section header using DaisyUI typography and spacing
sectionHeader :: SectionHeaderProps -> Html
sectionHeader props =
  let
    alignClass = case props.align of
      Center -> "text-center items-center mx-auto"
      Left -> "text-left items-start"
  in
    el "div" [ class_ ("flex flex-col max-w-3xl mb-10 sm:mb-12 space-y-3 " <> alignClass) ]
      [ case props.eyebrow of
          Just eb -> Badge.badge BadgePrimary eb
          Nothing -> text ""
      , el "h2" [ class_ "text-3xl sm:text-4xl font-extrabold tracking-tight text-base-content leading-tight" ]
          [ text props.title ]
      , case props.subtitle of
          Just sub -> el "p" [ class_ "text-base sm:text-lg text-base-content/75 font-normal leading-relaxed max-w-2xl" ] [ text sub ]
          Nothing -> text ""
      ]
