-- | Section header — frozen inner-page title block (stable across AJAX nav)
module App.Ui.Layout.SectionHeader
  ( Align(..)
  , SectionHeaderProps
  , innerPageHeader
  , innerPageHeaderClass
  , sectionHeader
  ) where

import Prelude

import App.Html (Html, class_, el, text)
import App.Ui.Badge (BadgeVariant(..))
import App.Ui.Badge as Badge
import App.Ui.TextTone (TextTone(..), toneClass)
import Data.Maybe (Maybe(..), maybe)

data Align = Left | Center

derive instance eqAlign :: Eq Align

type SectionHeaderProps =
  { eyebrow :: Maybe String
  , title :: String
  , subtitle :: Maybe String
  , align :: Align
  }

-- | Frozen inner-page header — left aligned, reserved eyebrow/subtitle slots (UiSpec).
innerPageHeaderClass :: String
innerPageHeaderClass = "flex flex-col gap-3 items-start text-left"

eyebrowSlotClass :: String
eyebrowSlotClass = "min-h-6 flex items-center"

subtitleSlotClass :: String
subtitleSlotClass = "text-lg min-h-7"

innerPageHeader :: { eyebrow :: Maybe String, title :: String, subtitle :: Maybe String } -> Html
innerPageHeader props =
  sectionHeader
    { eyebrow: props.eyebrow
    , title: props.title
    , subtitle: props.subtitle
    , align: Left
    }

sectionHeader :: SectionHeaderProps -> Html
sectionHeader props =
  let
    shellClass =
      case props.align of
        Center -> "flex flex-col gap-3 items-center text-center"
        Left -> innerPageHeaderClass
  in
    el "div" [ class_ shellClass ]
      [ el "div" [ class_ eyebrowSlotClass ]
          [ case props.eyebrow of
              Just eb -> Badge.badge BadgePrimary eb
              Nothing -> text ""
          ]
      , el "h1" [ class_ "text-3xl font-bold tracking-tight" ] [ text props.title ]
      , el "p" [ class_ (subtitleSlotClass <> " " <> toneClass Copy) ]
          [ text (maybe "" identity props.subtitle) ]
      ]
