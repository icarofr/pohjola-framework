-- | Decode policy/manifest.json — single source of truth for gate + PolicySpec.
module Test.Policy.Manifest
  ( PolicyManifest
  , ThemePolicy
  , UiClassPolicy
  , loadManifest
  ) where

import Prelude

import App.Bun (readTextFile)
import Data.Argonaut.Decode (decodeJson, printJsonDecodeError)
import Data.Argonaut.Parser (jsonParser)
import Data.Either (Either(..))
import Effect.Aff (Aff)

type ThemePolicy =
  { cssPrimaryHex :: String
  , themeLightName :: String
  , themeDarkName :: String
  , forbiddenDataThemeLiterals :: Array String
  , themeModule :: String
  }

type UiClassPolicy =
  { allowedTokens :: Array String
  , scanRoot :: String
  }

type PolicyManifest =
  { version :: Int
  , ffiAllowlist :: Array String
  , scriptAllowlist :: Array String
  , bannedSubstrings :: Array String
  , featureViewPaths :: Array String
  , forbiddenInFeatureViews :: Array String
  , forbiddenInAppUi :: Array String
  , envReadAllowlist :: Array String
  , theme :: ThemePolicy
  , uiClassPolicy :: UiClassPolicy
  }

loadManifest :: Aff (Either String PolicyManifest)
loadManifest = do
  raw <- readTextFile "policy/manifest.json"
  pure case raw of
    Left err -> Left ("Could not read policy/manifest.json: " <> err)
    Right text ->
      case jsonParser text of
        Left parseErr -> Left ("Invalid policy/manifest.json: " <> parseErr)
        Right json ->
          case decodeJson json of
            Left decodeErr -> Left (printJsonDecodeError decodeErr)
            Right manifest -> Right manifest
