-- | Hub page — actionCard grid archetype
module App.Ui.Layout.HubPage
  ( HubPageBlueprint
  , hubPage
  ) where

import Prelude

import App.Html (Html)
import App.Ui.Layout.ActionCard (ActionCardProps, actionCard)
import App.Ui.Layout.Grid (grid3)
import App.Ui.Layout.PageSection (pageSection)
import App.Ui.Layout.SectionHeader (Align(..))
import Data.Maybe (Maybe)

type HubPageBlueprint =
  { category :: Maybe String
  , title :: String
  , subtitle :: Maybe String
  , cards :: Array ActionCardProps
  }

hubPage :: HubPageBlueprint -> Html
hubPage page =
  pageSection
    { header:
        { eyebrow: page.category
        , title: page.title
        , subtitle: page.subtitle
        , align: Left
        }
    , content: grid3 (map actionCard page.cards)
    , banded: false
    }
