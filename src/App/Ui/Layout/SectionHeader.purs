-- | Rigid, unbreakable section header template with slot constraints
module App.Ui.Layout.SectionHeader where

import Prelude

import App.Html (Html, class_, el, text)
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

-- | Render a section header with strict spacing and hierarchy guarantees.
-- | Enforces at most ONE single eyebrow tag and proportional line heights.
sectionHeader :: SectionHeaderProps -> Html
sectionHeader props =
  let
    alignClass = case props.align of
      Center -> "text-center items-center mx-auto"
      Left -> "text-left items-start"
  in
    el "div" [ class_ ("flex flex-col max-w-3xl mb-12 sm:mb-16 space-y-4 " <> alignClass) ]
      [ case props.eyebrow of
          Just eb -> Badge.badge Badge.Primary eb
          Nothing -> text ""
      , el "h2" [ class_ "font-display text-3xl sm:text-4xl lg:text-5xl font-extrabold tracking-tight text-zinc-950 dark:text-white leading-[1.1]" ]
          [ text props.title ]
      , case props.subtitle of
          Just sub -> el "p" [ class_ "text-base sm:text-lg text-zinc-600 dark:text-zinc-400 font-normal leading-relaxed max-w-2xl" ] [ text sub ]
          Nothing -> text ""
      ]
