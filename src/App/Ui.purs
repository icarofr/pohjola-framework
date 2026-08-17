-- | Central UI module — re-exports all primitives and layout archetypes
module App.Ui
  ( module App.Ui.Layout.Types
  , module App.Ui.Layout.Hero
  , module App.Ui.Layout.SectionHeader
  , module App.Ui.Layout.Grid
  , module App.Ui.Layout.ActionCard
  , module App.Ui.Layout.ConversionCta
  , module App.Ui.Layout.LandingPage
  , module App.Ui.Layout.EditorialPage
  , module App.Ui.Button
  , module App.Ui.Badge
  , module App.Ui.Alert
  , module App.Ui.Stat
  , module App.Ui.EmptyState
  , pageLayout
  , pageHeader
  ) where

import App.Html (Html)
import App.Ui.Alert (AlertVariant(..), alert)
import App.Ui.Badge (BadgeVariant(..), badge)
import App.Ui.Button (ButtonVariant(..), Size(..), buttonLink, buttonLinkExternal)
import App.Ui.Container (container)
import App.Ui.EmptyState (EmptyStateProps, emptyState)
import App.Ui.Layout.ActionCard (ActionCardProps, actionCard)
import App.Ui.Layout.ConversionCta (ConversionCtaProps, conversionCta)
import App.Ui.Layout.EditorialPage (EditorialPageBlueprint, editorialPage)
import App.Ui.Layout.Grid (grid2, grid3, grid4)
import App.Ui.Layout.Hero (HeroAction, HeroProps, hero)
import App.Ui.Layout.LandingPage (LandingPageBlueprint, LandingPageSection, landingPage)
import App.Ui.Layout.SectionHeader (Align(..), SectionHeaderProps, sectionHeader)
import App.Ui.Layout.Types (ActionTarget(..))
import App.Ui.Stat (StatItem, statCard, statGrid)
import Data.Maybe (Maybe)

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
    , align: Center
    }

-- | Standard rigid page layout wrapper
pageLayout :: { header :: Html, content :: Html } -> Html
pageLayout props =
  container "max-w-5xl" "py-16 sm:py-24 space-y-12"
    [ props.header
    , props.content
    ]
