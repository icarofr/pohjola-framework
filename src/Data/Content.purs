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

formatPrice :: String -> Price -> String
formatPrice "en" (Price n) = "€" <> show n <> ".00"
formatPrice "fr" (Price n) = show n <> ",00 €"
formatPrice _ (Price n) = show n <> ",00 €"

newtype ServiceId = ServiceId String

derive instance newtypeServiceId :: Newtype ServiceId _
derive newtype instance showServiceId :: Show ServiceId
derive newtype instance eqServiceId :: Eq ServiceId

-- ============================================================================
-- Constants — replace with your site's values
-- ============================================================================

-- | Booking/external action URL
bookingUrl :: String
bookingUrl = "https://example.com/book"

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
  , description: "An opinionated full-stack functional framework in PureScript, Bun, and Alpine.js"
  , themeColor: "#2563eb"
  , email: "contact@example.com"
  , facebookUrl: "https://facebook.com/example"
  , instagramUrl: "https://instagram.com/example"
  }

-- | Service ids referenced by the Dictionary — add a service here AND a
-- | serviceCopy case in each language (Data.I18n) to keep parity.
services :: Array Service
services =
  [ { id: ServiceId "service-1"
    , price: Price 100
    , imageUrl: "/images/service-1.svg"
    , imageWidth: 400
    , imageHeight: 300
    }
  , { id: ServiceId "service-2"
    , price: Price 50
    , imageUrl: "/images/service-2.svg"
    , imageWidth: 400
    , imageHeight: 300
    }
  , { id: ServiceId "service-3"
    , price: Price 75
    , imageUrl: "/images/service-3.svg"
    , imageWidth: 400
    , imageHeight: 300
    }
  ]
