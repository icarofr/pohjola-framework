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
  , FeedSlots
  , FeedCard
  , ArticleSlots
  , landingSlots
  , landingFeatures
  , hubSlots
  , hubCardTriple
  , editorialSlots
  , valuesSlots
  , valueSextuple
  , valuesSlotsFromArray
  , imageTriple
  , imageTripleFromArray
  , feedSlots
  , articleSlots
  , featureItems
  , valueItems
  , hubCards
  , imageUrls
  ) where

import Prelude

import Data.I18n (Lang)
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
  | Article ArticleSlots

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
  , mission :: MissionSlots
  , values :: ValuesSlots
  }

type HubCard =
  { title :: String
  , description :: String
  , buttonLabel :: String
  , target :: ActionTarget
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
  , posts :: Array FeedCard
  }

type ArticleSlots =
  { metaTag :: String
  , title :: String
  , authorName :: String
  , date :: String
  , body :: String
  , backLabel :: String
  }

landingFeatures ::
  String ->
  String ->
  String ->
  ServiceFeature ->
  ServiceFeature ->
  ServiceFeature ->
  LandingFeatureSlots
landingFeatures eyebrow headline body one two three =
  { eyebrow
  , headline
  , body
  , items: { one, two, three }
  }

landingSlots ::
  LandingHeroSlots ->
  LandingFeatureSlots ->
  LandingCtaSlots ->
  LandingSlots
landingSlots hero features cta =
  { hero, features, cta }

valueSextuple ::
  ValueItem ->
  ValueItem ->
  ValueItem ->
  ValueItem ->
  ValueItem ->
  ValueItem ->
  ValueSextuple
valueSextuple one two three four five six =
  { one, two, three, four, five, six }

valuesSlots :: String -> String -> ValueSextuple -> ValuesSlots
valuesSlots heading intro items =
  { heading, intro, items }

imageTriple :: String -> String -> String -> ImageTriple
imageTriple one two three =
  { one, two, three }

editorialSlots ::
  String ->
  MissionSlots ->
  ValuesSlots ->
  EditorialSlots
editorialSlots heading mission values =
  { heading, mission, values }

hubCardTriple :: HubCard -> HubCard -> HubCard -> HubCardTriple
hubCardTriple one two three =
  { one, two, three }

hubSlots :: String -> String -> HubCardTriple -> HubSlots
hubSlots title subtitle cards =
  { title, subtitle, cards }

feedSlots :: String -> String -> Array FeedCard -> FeedSlots
feedSlots title subtitle posts =
  { title, subtitle, posts }

articleSlots ::
  String ->
  String ->
  String ->
  String ->
  String ->
  String ->
  ArticleSlots
articleSlots metaTag title authorName date body backLabel =
  { metaTag, title, authorName, date, body, backLabel }

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

valuesSlotsFromArray :: String -> String -> Array ValueItem -> ValuesSlots
valuesSlotsFromArray heading intro items =
  case items of
    [ one, two, three, four, five, six ] ->
      valuesSlots heading intro (valueSextuple one two three four five six)
    _ ->
      valuesSlots heading intro
        ( valueSextuple
            emptyValue
            emptyValue
            emptyValue
            emptyValue
            emptyValue
            emptyValue
        )

emptyValue :: ValueItem
emptyValue = { title: "", description: "" }

imageTripleFromArray :: Array String -> ImageTriple
imageTripleFromArray urls =
  case urls of
    [ one, two, three ] ->
      imageTriple one two three
    _ ->
      imageTriple "" "" ""
