-- | Closed page template algebra — agents fill slot records only.
module App.Ui.Templates.Types
  ( ActionTarget(..)
  , PageTemplate(..)
  , LandingSlots
  , LandingHeroSlots
  , LandingFeatureSlots
  , LandingCtaSlots
  , ServiceFeature
  , FeatureTriple
  , ValueSextuple
  , ImageTriple
  , HubCardTriple
  , EditorialSlots
  , MissionSlots
  , ValuesSlots
  , ValueItem
  , HubSlots
  , HubCard
  , BreadcrumbItem
  , FeedSlots
  , FeedCard
  , ScheduleSlots
  , ScheduleMatch
  , ScheduleCrest
  , ArticleSlots
  , FormField(..)
  , FormSlots
  , landingSlots
  , landingFeatures
  , hubSlots
  , hubCardTriple
  , editorialSlots
  , valuesSlots
  , valueSextuple
  , emptyValue
  , imageTriple
  , feedSlots
  , scheduleSlots
  , articleSlots
  , formSlots
  , featureItems
  , valueItems
  , hubCards
  , imageUrls
  ) where

import Prelude

import Data.I18n (Lang)
import Data.Maybe (Maybe)
import Data.Route (Route)

data ActionTarget
  = Internal { lang :: Lang, route :: Route }
  | External { href :: String }

derive instance eqActionTarget :: Eq ActionTarget

data PageTemplate
  = Landing LandingSlots
  | Editorial EditorialSlots
  | Hub HubSlots
  | Feed FeedSlots
  | Schedule ScheduleSlots
  | Article ArticleSlots
  | Form FormSlots

type LandingHeroSlots =
  { eyebrow :: String
  , headline :: String
  , body :: String
  , ctaLabel :: String
  , secondaryLabel :: String
  , primaryTarget :: ActionTarget
  , secondaryTarget :: ActionTarget
  }

type ServiceFeature = { title :: String, description :: String }

type LandingFeatureSlots =
  { eyebrow :: String
  , headline :: String
  , body :: String
  , items :: FeatureTriple
  }

type FeatureTriple =
  { one :: ServiceFeature
  , two :: ServiceFeature
  , three :: ServiceFeature
  }

type LandingCtaSlots =
  { heading :: String
  , body :: String
  , ctaLabel :: String
  , target :: ActionTarget
  }

type LandingSlots =
  { hero :: LandingHeroSlots
  , features :: LandingFeatureSlots
  , cta :: LandingCtaSlots
  }

type MissionSlots =
  { heading :: String
  , lead :: String
  , body :: String
  }

type ValueItem = { title :: String, description :: String }

type ValuesSlots =
  { heading :: String
  , intro :: String
  , items :: ValueSextuple
  }

type ValueSextuple =
  { one :: ValueItem
  , two :: ValueItem
  , three :: ValueItem
  , four :: ValueItem
  , five :: ValueItem
  , six :: ValueItem
  }

type ImageTriple =
  { one :: String
  , two :: String
  , three :: String
  }

type EditorialSlots =
  { heading :: String
  , subtitle :: Maybe String
  , mission :: MissionSlots
  , values :: ValuesSlots
  , breadcrumbs :: Array BreadcrumbItem
  }

type HubCard =
  { title :: String
  , description :: String
  , buttonLabel :: String
  , target :: ActionTarget
  }

type BreadcrumbItem =
  { label :: String
  , target :: Maybe ActionTarget
  }

type HubCardTriple =
  { one :: HubCard
  , two :: HubCard
  , three :: HubCard
  }

type HubSlots =
  { title :: String
  , subtitle :: String
  , cards :: HubCardTriple
  , breadcrumbs :: Array BreadcrumbItem
  }

type FeedCard =
  { imageUrl :: String
  , imageAlt :: String
  , date :: String
  , category :: String
  , title :: String
  , excerpt :: String
  , authorName :: String
  , authorRole :: String
  , target :: ActionTarget
  }

type FeedSlots =
  { title :: String
  , subtitle :: String
  , breadcrumbs :: Array BreadcrumbItem
  , posts :: Array FeedCard
  }

type ScheduleCrest =
  { src :: String
  , alt :: String
  }

type ScheduleMatch =
  { home :: ScheduleCrest
  , away :: ScheduleCrest
  , vsLabel :: String
  , title :: String
  , kickoff :: String
  , competition :: String
  , detail :: String
  , target :: ActionTarget
  }

type ScheduleSlots =
  { title :: String
  , subtitle :: String
  , breadcrumbs :: Array BreadcrumbItem
  , matches :: Array ScheduleMatch
  }

type ArticleSlots =
  { metaTag :: String
  , title :: String
  , authorName :: String
  , date :: String
  , body :: String
  , breadcrumbs :: Array BreadcrumbItem
  }

data FormField
  = FormText { name :: String, label :: String, required :: Boolean }
  | FormEmail { name :: String, label :: String, required :: Boolean }
  | FormTextarea { name :: String, label :: String, required :: Boolean, rows :: Int }

derive instance eqFormField :: Eq FormField

type FormSlots =
  { title :: String
  , subtitle :: Maybe String
  , breadcrumbs :: Array BreadcrumbItem
  , action :: String
  , submitLabel :: String
  , fields :: Array FormField
  }

landingFeatures
  :: String
  -> String
  -> String
  -> ServiceFeature
  -> ServiceFeature
  -> ServiceFeature
  -> LandingFeatureSlots
landingFeatures eyebrow headline body one two three =
  { eyebrow
  , headline
  , body
  , items: { one, two, three }
  }

landingSlots
  :: LandingHeroSlots
  -> LandingFeatureSlots
  -> LandingCtaSlots
  -> LandingSlots
landingSlots hero features cta =
  { hero, features, cta }

valueSextuple
  :: ValueItem
  -> ValueItem
  -> ValueItem
  -> ValueItem
  -> ValueItem
  -> ValueItem
  -> ValueSextuple
valueSextuple one two three four five six =
  { one, two, three, four, five, six }

valuesSlots :: String -> String -> ValueSextuple -> ValuesSlots
valuesSlots heading intro items =
  { heading, intro, items }

emptyValue :: ValueItem
emptyValue = { title: "", description: "" }

imageTriple :: String -> String -> String -> ImageTriple
imageTriple one two three =
  { one, two, three }

editorialSlots
  :: String
  -> Maybe String
  -> MissionSlots
  -> ValuesSlots
  -> Array BreadcrumbItem
  -> EditorialSlots
editorialSlots heading subtitle mission values breadcrumbs =
  { heading, subtitle, mission, values, breadcrumbs }

hubCardTriple :: HubCard -> HubCard -> HubCard -> HubCardTriple
hubCardTriple one two three =
  { one, two, three }

hubSlots :: String -> String -> HubCardTriple -> Array BreadcrumbItem -> HubSlots
hubSlots title subtitle cards breadcrumbs =
  { title, subtitle, cards, breadcrumbs }

feedSlots :: String -> String -> Array BreadcrumbItem -> Array FeedCard -> FeedSlots
feedSlots title subtitle breadcrumbs posts =
  { title, subtitle, breadcrumbs, posts }

scheduleSlots :: String -> String -> Array BreadcrumbItem -> Array ScheduleMatch -> ScheduleSlots
scheduleSlots title subtitle breadcrumbs matches =
  { title, subtitle, breadcrumbs, matches }

articleSlots
  :: String
  -> String
  -> String
  -> String
  -> String
  -> Array BreadcrumbItem
  -> ArticleSlots
articleSlots metaTag title authorName date body breadcrumbs =
  { metaTag, title, authorName, date, body, breadcrumbs }

formSlots
  :: String
  -> Maybe String
  -> Array BreadcrumbItem
  -> String
  -> String
  -> Array FormField
  -> FormSlots
formSlots title subtitle breadcrumbs action submitLabel fields =
  { title, subtitle, breadcrumbs, action, submitLabel, fields }

featureItems :: FeatureTriple -> Array ServiceFeature
featureItems triple =
  [ triple.one, triple.two, triple.three ]

valueItems :: ValueSextuple -> Array ValueItem
valueItems sextuple =
  [ sextuple.one, sextuple.two, sextuple.three, sextuple.four, sextuple.five, sextuple.six ]

hubCards :: HubCardTriple -> Array HubCard
hubCards triple =
  [ triple.one, triple.two, triple.three ]

imageUrls :: ImageTriple -> Array String
imageUrls triple =
  [ triple.one, triple.two, triple.three ]
