-- | Complete, rigid, unbreakable UI system for Pohjola (MUI-grade component contract)
module App.Ui
  ( module App.Ui.Layout.Types
  , module App.Ui.Layout.Hero
  , module App.Ui.Layout.SectionHeader
  , module App.Ui.Layout.Grid
  , module App.Ui.Layout.ActionCard
  , module App.Ui.Layout.ConversionCta
  , module App.Ui.Button
  , module App.Ui.Badge
  , module App.Ui.Alert
  , module App.Ui.Stat
  , module App.Ui.EmptyState
  , pageLayout
  , pageHeader
  ) where

import Prelude

import App.Html (Html)
import App.Ui.Alert (AlertVariant(..), alert)
import App.Ui.Badge (BadgeVariant(..), badge)
import App.Ui.Button (Size(..), Variant(..), buttonLink, buttonLinkExternal)
import App.Ui.Container (container)
import App.Ui.EmptyState (emptyState)
import App.Ui.Layout.ActionCard (actionCard)
import App.Ui.Layout.ConversionCta (conversionCta)
import App.Ui.Layout.Grid (grid2, grid3, grid4)
import App.Ui.Layout.Hero (hero)
import App.Ui.Layout.SectionHeader (Align(..), sectionHeader)
import App.Ui.Layout.Types (ActionTarget(..))
import App.Ui.Stat (statCard, statGrid)
import Data.Maybe (Maybe(..))

type PageHeaderProps =
  { category :: Maybe String
  , title :: String
  , subtitle :: Maybe String
  }

-- | Standard rigid page header
pageHeader :: PageHeaderProps -> Html
pageHeader props =
  sectionHeader
    { eyebrow: props.category
    , title: props.title
    , subtitle: props.subtitle
    , align: Left
    }

type PageLayoutProps =
  { header :: Html
  , content :: Html
  }

-- | Standard rigid page layout wrapper (locks width and responsive vertical rhythm)
pageLayout :: PageLayoutProps -> Html
pageLayout props =
  container "max-w-5xl" "py-16 sm:py-24 space-y-12"
    [ props.header
    , props.content
    ]
