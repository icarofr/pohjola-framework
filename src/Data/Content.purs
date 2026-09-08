-- | Site content — single source of truth for non-textual domain data.
-- |
-- | Book-aligned: newtypes for type safety, domain types for clarity.
-- | Localized copy lives in Data.I18n — Content holds metadata only.
module Data.Content where

import Prelude

import Data.Newtype (class Newtype)

-- ============================================================================
-- Newtypes for type safety (book pattern: wrap primitives to prevent errors)
-- ============================================================================

newtype Price = Price Int -- in whole units (euros, cents, etc.)

derive instance newtypePrice :: Newtype Price _
derive newtype instance showPrice :: Show Price
derive newtype instance eqPrice :: Eq Price
derive newtype instance ordPrice :: Ord Price

newtype ServiceId = ServiceId String

derive instance newtypeServiceId :: Newtype ServiceId _
derive newtype instance showServiceId :: Show ServiceId
derive newtype instance eqServiceId :: Eq ServiceId

-- ============================================================================
-- Constants — replace with your site's values
-- ============================================================================

-- | GitHub repository URL
bookingUrl :: String
bookingUrl = "https://github.com/icarofr/pohjola-framework"

-- | GitHub issues URL — for the Contact/Community page.
issuesUrl :: String
issuesUrl = bookingUrl <> "/issues"

-- | GitHub discussions URL — for the Contact/Community page.
discussionsUrl :: String
discussionsUrl = bookingUrl <> "/discussions"

-- ============================================================================
-- Domain types
-- ============================================================================

-- | Service metadata only — title/description come from Data.I18n (serviceCopy).
type Service =
  { id :: ServiceId
  , price :: Price
  , imageUrl :: String
  , imageWidth :: Int
  , imageHeight :: Int
  }

type SiteInfo =
  { title :: String
  , description :: String
  , themeColor :: String
  , email :: String
  , facebookUrl :: String
  , instagramUrl :: String
  }

-- | Image with dimensions for CLS prevention
type Image =
  { url :: String
  , width :: Int
  , height :: Int
  , alt :: String
  }

-- ============================================================================
-- Site content
-- ============================================================================

siteInfo :: SiteInfo
siteInfo =
  { title: "Pohjola"
  , description: "The Type-Safe Functional Web Framework for Bun, PureScript, and Alpine.js"
  , themeColor: "#059669"
  , email: ""
  , facebookUrl: "https://github.com/icarofr/pohjola-framework"
  , instagramUrl: "https://github.com/icarofr/pohjola-framework"
  }

-- | Fixed-arity, matching App.Ui.Templates.Types.FeatureTriple — a 4th
-- | service is a type change (a new field), not an array append, so a
-- | length mismatch can't compile. Add a service id here, a serviceCopy
-- | case in each language (Data.I18n), and a field name below to keep
-- | parity; the compiler forces the third.
type ServiceTriple = { one :: Service, two :: Service, three :: Service }

services :: ServiceTriple
services =
  { one:
      { id: ServiceId "service-1"
      , price: Price 0
      , imageUrl: "/images/service-1.svg"
      , imageWidth: 400
      , imageHeight: 300
      }
  , two:
      { id: ServiceId "service-2"
      , price: Price 0
      , imageUrl: "/images/service-2.svg"
      , imageWidth: 400
      , imageHeight: 300
      }
  , three:
      { id: ServiceId "service-3"
      , price: Price 0
      , imageUrl: "/images/service-3.svg"
      , imageWidth: 400
      , imageHeight: 300
      }
  }

-- ============================================================================
-- Tottenham Hotspur fixtures (OneFootball — temporary demo data)
-- ============================================================================

data FixtureVenue = SpursHome | SpursAway

derive instance eqFixtureVenue :: Eq FixtureVenue

type Fixture =
  { opponent :: String
  , opponentCrest :: String
  , venue :: FixtureVenue
  , kickoffDate :: String
  , kickoffTime :: String
  , competition :: String
  }

spursCrest :: String
spursCrest = "/images/crests/tottenham.svg"

spursCrestAlt :: String
spursCrestAlt = "Tottenham Hotspur"

fixtureTitle :: Fixture -> String
fixtureTitle fixture =
  case fixture.venue of
    SpursHome -> "Tottenham Hotspur vs " <> fixture.opponent
    SpursAway -> fixture.opponent <> " vs Tottenham Hotspur"

fixtureKickoff :: Fixture -> String
fixtureKickoff fixture = fixture.kickoffDate <> " · " <> fixture.kickoffTime

onefootballFixturesUrl :: String
onefootballFixturesUrl = "https://onefootball.com/en/team/tottenham-hotspur-202/fixtures"

tottenhamFixtures :: Array Fixture
tottenhamFixtures =
  [ { opponent: "Nottingham Forest"
    , opponentCrest: "/images/crests/nottingham-forest.svg"
    , venue: SpursAway
    , kickoffDate: "05/09/2026"
    , kickoffTime: "10:00"
    , competition: "Premier League"
    }
  , { opponent: "Everton"
    , opponentCrest: "/images/crests/everton.svg"
    , venue: SpursHome
    , kickoffDate: "12/09/2026"
    , kickoffTime: "12:30"
    , competition: "Premier League"
    }
  , { opponent: "Liverpool FC"
    , opponentCrest: "/images/crests/liverpool.svg"
    , venue: SpursAway
    , kickoffDate: "15/09/2026"
    , kickoffTime: "15:00"
    , competition: "EFL Cup"
    }
  , { opponent: "Aston Villa"
    , opponentCrest: "/images/crests/aston-villa.svg"
    , venue: SpursHome
    , kickoffDate: "19/09/2026"
    , kickoffTime: "07:30"
    , competition: "Premier League"
    }
  , { opponent: "Manchester United"
    , opponentCrest: "/images/crests/manchester-united.svg"
    , venue: SpursAway
    , kickoffDate: "10/10/2026"
    , kickoffTime: "12:30"
    , competition: "Premier League"
    }
  , { opponent: "Coventry City"
    , opponentCrest: "/images/crests/coventry-city.svg"
    , venue: SpursHome
    , kickoffDate: "19/10/2026"
    , kickoffTime: "15:00"
    , competition: "Premier League"
    }
  , { opponent: "Chelsea"
    , opponentCrest: "/images/crests/chelsea.svg"
    , venue: SpursAway
    , kickoffDate: "24/10/2026"
    , kickoffTime: "12:30"
    , competition: "Premier League"
    }
  , { opponent: "Crystal Palace"
    , opponentCrest: "/images/crests/crystal-palace.svg"
    , venue: SpursHome
    , kickoffDate: "31/10/2026"
    , kickoffTime: "13:30"
    , competition: "Premier League"
    }
  , { opponent: "Leeds United"
    , opponentCrest: "/images/crests/leeds-united.svg"
    , venue: SpursAway
    , kickoffDate: "07/11/2026"
    , kickoffTime: "10:00"
    , competition: "Premier League"
    }
  ]
