-- | Central UI module — re-exports all primitives and layout archetypes
module App.Ui
  ( module App.Ui.Layout.Types
  , module App.Ui.Layout.Hero
  , module App.Ui.Layout.SectionHeader
  , module App.Ui.Layout.Grid
  , module App.Ui.Layout.ActionCard
  , module App.Ui.Layout.TeaserCard
  , module App.Ui.Layout.ConversionCta
  , module App.Ui.Layout.LandingPage
  , module App.Ui.Layout.EditorialPage
  , module App.Ui.Layout.ArticlePage
  , module App.Ui.Layout.PageSection
  , module App.Ui.Layout.HubPage
  , module App.Ui.Layout.FeedPage
  , module App.Ui.Button
  , module App.Ui.Badge
  , module App.Ui.Alert
  , module App.Ui.Stat
  , module App.Ui.EmptyState
  , module App.Ui.Avatar
  , module App.Ui.Prose
  , module App.Ui.TextTone
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
import App.Ui.Layout.TeaserCard (TeaserCardProps, teaserCard)
import App.Ui.Layout.ConversionCta (ConversionCtaProps, conversionCta)
import App.Ui.Layout.ArticlePage (ArticlePageBlueprint, articlePage)
import App.Ui.Layout.EditorialPage (EditorialPageBlueprint, editorialPage, editorialParagraphs)
import App.Ui.Layout.Grid (grid2, grid3, grid4)
import App.Ui.Layout.Hero (HeroAction, HeroProps, hero)
import App.Ui.Layout.FeedPage (FeedPageBlueprint, feedPage)
import App.Ui.Layout.HubPage (HubPageBlueprint, hubPage)
import App.Ui.Layout.LandingPage (LandingPageBlueprint, LandingPageSection, landingPage)
import App.Ui.Layout.PageSection (PageSectionProps, conversionSection, pageSection)
import App.Ui.Layout.SectionHeader (Align(..), SectionHeaderProps, innerPageHeader, sectionHeader)
import App.Ui.Layout.Types (ActionTarget(..))
import App.Ui.Stat (StatItem, statCard, statGrid)
import App.Ui.Avatar (AvatarSize(..), avatarPlaceholder)
import App.Ui.Prose (prose)
import App.Ui.TextTone
import Data.Maybe (Maybe)

type PageHeaderProps =
  { category :: Maybe String
  , title :: String
  , subtitle :: Maybe String
  }

-- | Standard rigid page header — frozen inner-page recipe (no layout shift on nav)
pageHeader :: PageHeaderProps -> Html
pageHeader props =
  innerPageHeader
    { eyebrow: props.category
    , title: props.title
    , subtitle: props.subtitle
    }

-- | Standard rigid page layout wrapper
pageLayout :: { header :: Html, content :: Html } -> Html
pageLayout props =
  container "max-w-5xl" "py-16 sm:py-24 space-y-12"
    [ props.header
    , props.content
    ]
