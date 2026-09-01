-- | Page template slot contracts — source of truth for data-template markers.
module App.Ui.Templates.Contract
  ( aboutValueCount
  , contactHubCardCount
  , homeFeatureItemCount
  , marker
  , slot
  , siteHeader
  , siteFooter
  , landingHero
  , landingFeatures
  , landingFeatureItem
  , landingCta
  , editorialMission
  , editorialValues
  , hubPage
  , hubCards
  , hubCard
  , feedPage
  , feedGrid
  , feedCard
  , pageHeader
  , pageHeaderBreadcrumbs
  , pageHeaderBody
  , pageHeaderDetail
  , schedulePage
  , scheduleList
  , scheduleRow
  , articlePage
  , articleHeader
  , articleBody
  , articleMeta
  ) where

import Prelude

marker :: String
marker = "data-template"

slot :: String -> String
slot name = marker <> "=\"" <> name <> "\""

siteHeader :: String
siteHeader = "site-header"

siteFooter :: String
siteFooter = "site-footer"

landingHero :: String
landingHero = "landing-hero"

landingFeatures :: String
landingFeatures = "landing-features"

landingFeatureItem :: String
landingFeatureItem = "landing-feature-item"

landingCta :: String
landingCta = "landing-cta"

editorialMission :: String
editorialMission = "editorial-mission"

editorialValues :: String
editorialValues = "editorial-values"

hubPage :: String
hubPage = "hub-page"

hubCards :: String
hubCards = "hub-cards"

hubCard :: String
hubCard = "hub-card"

feedPage :: String
feedPage = "feed-page"

feedGrid :: String
feedGrid = "feed-grid"

feedCard :: String
feedCard = "feed-card"

pageHeader :: String
pageHeader = "page-header"

pageHeaderBreadcrumbs :: String
pageHeaderBreadcrumbs = "page-header-breadcrumbs"

pageHeaderBody :: String
pageHeaderBody = "page-header-body"

pageHeaderDetail :: String
pageHeaderDetail = "page-header-detail"

schedulePage :: String
schedulePage = "schedule-page"

scheduleList :: String
scheduleList = "schedule-list"

scheduleRow :: String
scheduleRow = "schedule-row"

articlePage :: String
articlePage = "article-page"

articleHeader :: String
articleHeader = "article-header"

articleBody :: String
articleBody = "article-body"

articleMeta :: String
articleMeta = "article-meta"

homeFeatureItemCount :: Int
homeFeatureItemCount = 3

contactHubCardCount :: Int
contactHubCardCount = 3

aboutValueCount :: Int
aboutValueCount = 6
