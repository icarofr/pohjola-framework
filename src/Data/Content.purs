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
  , themeColor :: String
  }

-- ============================================================================
-- Site content
-- ============================================================================

siteInfo :: SiteInfo
siteInfo =
  { title: "Pohjola"
  , themeColor: "#059669"
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
