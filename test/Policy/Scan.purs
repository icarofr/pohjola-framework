-- | Shared source scanners for policy enforcement (PolicySpec).
module Test.Policy.Scan
  ( containsBanned
  , containsForeignImport
  , containsRawAlpine
  , containsRawWord
  , containsSubstring
  , featureOfModule
  , featureOfPath
  , findBannedInSrc
  , findCrossFeatureImports
  , findEnvReadsOutsideAllowlist
  , findExtraFiles
  , findFeatureViewsMissingTemplateRender
  , findFeaturesMissingView
  , findFilesMatching
  , findForbiddenAuthImports
  , findForbiddenImportsInFiles
  , findForbiddenInFiles
  , findForeignImportsOutsideAllowlist
  , findHardcodedTextInFiles
  , findRawAlpineOutsideAlpine
  , findRawInSrc
  , findScriptsOutsideAllowlist
  , findTextToneViolations
  , pursFilesUnder
  , withoutPolicyExclusions
  ) where

import Prelude

import App.Bun (exists, glob, readTextFile)
import Data.Array (concat, elem, filter, length, mapMaybe, uncons)
import Data.Char (toCharCode)
import Data.Either (Either(..))
import Data.Foldable (any)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String.Common (split) as Common
import Data.String.CodeUnits (fromCharArray, stripPrefix, stripSuffix, toCharArray) as CodeUnits
import Data.String.Pattern (Pattern(..))
import Data.Traversable (for)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)

pursFilesUnder :: String -> Effect (Array String)
pursFilesUnder dir = glob (dir <> "/**/*.purs")

findFilesMatching :: String -> Effect (Array String)
findFilesMatching pattern = glob pattern

withoutPolicyExclusions :: Array String -> Array String -> Array String
withoutPolicyExclusions exclusions files =
  filter (\f -> not (elem f exclusions)) files

containsSubstring :: String -> String -> Boolean
containsSubstring needle haystack =
  length (Common.split (Pattern needle) haystack) > 1

containsRawWord :: String -> Boolean
containsRawWord str =
  let
    spaced = CodeUnits.fromCharArray (map spaceOut (CodeUnits.toCharArray str))
  in
    any (\w -> w == "raw" || w == "Raw") (Common.split (Pattern " ") spaced)
  where
  spaceOut c = if isWordChar c then c else ' '

isWordChar :: Char -> Boolean
isWordChar c =
  let
    n = toCharCode c
  in
    (n >= 48 && n <= 57)
      || (n >= 65 && n <= 90)
      || (n >= 97 && n <= 122)
      || n == 95

containsBanned :: Array String -> String -> Boolean
containsBanned patterns str =
  any (\b -> containsSubstring b str) patterns

containsRawAlpine :: String -> Boolean
containsRawAlpine str =
  let
    banned = [ "attr \"x-", "attr \"@", "attr \":", "flag \"x-" ]
  in
    any (\b -> containsSubstring b str) banned

containsForeignImport :: String -> Boolean
containsForeignImport str =
  containsSubstring "foreign import" str

findRawInSrc :: String -> Aff (Array String)
findRawInSrc root = do
  files <- liftEffect $ pursFilesUnder root
  results <- for files \file -> do
    content <- readTextFile file
    pure case content of
      Right c -> if containsRawWord c then Just file else Nothing
      Left _ -> Nothing
  pure (mapMaybe identity results)

findBannedInSrc :: Array String -> String -> Aff (Array String)
findBannedInSrc patterns root = do
  files <- liftEffect $ pursFilesUnder root
  results <- for files \file -> do
    content <- readTextFile file
    pure case content of
      Right c -> if containsBanned patterns c then Just file else Nothing
      Left _ -> Nothing
  pure (mapMaybe identity results)

findForeignImportsOutsideAllowlist :: Array String -> String -> Aff (Array String)
findForeignImportsOutsideAllowlist allowlist root = do
  files <- liftEffect $ pursFilesUnder root
  results <- for files \file -> do
    if any (_ == file) allowlist then pure Nothing
    else do
      content <- readTextFile file
      pure case content of
        Right c -> if containsForeignImport c then Just file else Nothing
        Left _ -> Nothing
  pure (mapMaybe identity results)

findScriptsOutsideAllowlist :: Array String -> String -> Aff (Array String)
findScriptsOutsideAllowlist allowlist root = do
  files <- liftEffect $ pursFilesUnder root
  results <- for files \file -> do
    if any (_ == file) allowlist then pure Nothing
    else do
      content <- readTextFile file
      pure case content of
        Right c -> if containsSubstring "el \"script\"" c then Just file else Nothing
        Left _ -> Nothing
  pure (mapMaybe identity results)

findRawAlpineOutsideAlpine :: String -> Aff (Array String)
findRawAlpineOutsideAlpine root = do
  files <- liftEffect $ pursFilesUnder root
  results <- for files \file -> do
    if file == "src/App/Alpine.purs" then pure Nothing
    else do
      content <- readTextFile file
      pure case content of
        Right c -> if containsRawAlpine c then Just file else Nothing
        Left _ -> Nothing
  pure (mapMaybe identity results)

findEnvReadsOutsideAllowlist :: Array String -> String -> Aff (Array String)
findEnvReadsOutsideAllowlist allowlist root = do
  files <- liftEffect $ pursFilesUnder root
  results <- for files \file -> do
    if any (_ == file) allowlist then pure Nothing
    else do
      content <- readTextFile file
      pure case content of
        Right c ->
          if containsSubstring "Node.Process" c || containsSubstring "lookupEnv" c then
            Just file
          else
            Nothing
        Left _ -> Nothing
  pure (mapMaybe identity results)

findExtraFiles :: Array String -> String -> Aff (Array String)
findExtraFiles allowed pattern = do
  files <- liftEffect $ findFilesMatching pattern
  pure (filter (\f -> not (elem f allowed)) files)

findHardcodedTextInFiles :: String -> Array String -> Aff (Array String)
findHardcodedTextInFiles needle files = do
  results <- for files \file -> do
    content <- readTextFile file
    pure case content of
      Right c ->
        let
          lines = Common.split (Pattern "\n") c
          hits = filter (containsSubstring needle) lines
        in
          if length hits > 0 then Just file else Nothing
      Left _ -> Nothing
  pure (mapMaybe identity results)

findForbiddenImportsInFiles :: Array String -> Array String -> Aff (Array String)
findForbiddenImportsInFiles modules files = do
  results <- for files \file -> do
    content <- readTextFile file
    pure case content of
      Right c ->
        if any (\mod -> containsSubstring ("import " <> mod) c) modules then
          Just file
        else
          Nothing
      Left _ -> Nothing
  pure (mapMaybe identity results)

-- | `import App.Auth.Scaffold` contains substring `import App.Auth`.
-- | Flag lines matching `import App.Auth` that are not `import App.Auth.Scaffold`.
isForbiddenAuthImport :: String -> Boolean
isForbiddenAuthImport line =
  containsSubstring "import App.Auth" line
    && not (containsSubstring "import App.Auth.Scaffold" line)

-- | Ban bare App.Auth imports in Main and Features (scaffold path excluded).
findForbiddenAuthImports :: Aff (Array String)
findForbiddenAuthImports = do
  featureFiles <- liftEffect $ pursFilesUnder "src/App/Features"
  let files = [ "src/App/Main.purs" ] <> featureFiles
  results <- for files \file -> do
    content <- readTextFile file
    pure case content of
      Right c ->
        let
          lines = Common.split (Pattern "\n") c
          hits = filter isForbiddenAuthImport lines
        in
          if length hits > 0 then Just file else Nothing
      Left _ -> Nothing
  pure (mapMaybe identity results)

findTextToneViolations :: String -> Array String -> String -> Aff (Array String)
findTextToneViolations pattern allowlist root = do
  files <- liftEffect $ pursFilesUnder root
  results <- for files \file -> do
    if any (_ == file) allowlist then pure Nothing
    else do
      content <- readTextFile file
      pure case content of
        Right c -> if containsSubstring pattern c then Just file else Nothing
        Left _ -> Nothing
  pure (mapMaybe identity results)

findForbiddenInFiles :: Array String -> Array String -> Aff (Array String)
findForbiddenInFiles patterns files = do
  results <- for files \file -> do
    content <- readTextFile file
    pure case content of
      Right c ->
        if any (\p -> containsSubstring p c) patterns then
          Just file
        else
          Nothing
      Left _ -> Nothing
  pure (mapMaybe identity results)

featureOfModule :: String -> Maybe String
featureOfModule modName = do
  rest <- CodeUnits.stripPrefix (Pattern "App.Features.") modName
  map (_.head) (uncons (Common.split (Pattern ".") rest))

featureOfPath :: String -> Maybe String
featureOfPath path = do
  rest <- CodeUnits.stripPrefix (Pattern "src/App/Features/") path
  map (_.head) (uncons (Common.split (Pattern "/") rest))

findCrossFeatureImports :: String -> Aff (Array String)
findCrossFeatureImports featuresRoot = do
  files <- liftEffect $ pursFilesUnder featuresRoot
  offenders <- for files \file -> do
    content <- readTextFile file
    pure case content of
      Left _ -> []
      Right c -> map (\imp -> file <> ": " <> imp) (crossFeatureImports file c)
  pure (concat offenders)
  where
  crossFeatureImports :: String -> String -> Array String
  crossFeatureImports file content =
    case featureOfPath file of
      Nothing -> []
      Just ownFeature ->
        mapMaybe (siblingImport ownFeature) (Common.split (Pattern "\n") content)

  siblingImport :: String -> String -> Maybe String
  siblingImport ownFeature line =
    case CodeUnits.stripPrefix (Pattern "import App.Features.") line of
      Nothing -> Nothing
      Just rest ->
        if featureOfModule ("App.Features." <> rest) == Just ownFeature then Nothing
        else Just line

findFeatureViewsMissingTemplateRender :: String -> Aff (Array String)
findFeatureViewsMissingTemplateRender featuresRoot = do
  files <- liftEffect $ findFilesMatching (featuresRoot <> "/*/View.purs")
  results <- for files \file -> do
    content <- readTextFile file
    pure case content of
      Right c ->
        if containsSubstring "App.Ui.Templates.Render" c then Nothing
        else Just file
      Left _ -> Just file
  pure (mapMaybe identity results)

findFeaturesMissingView :: String -> Aff (Array String)
findFeaturesMissingView featuresRoot = do
  pages <- liftEffect $ findFilesMatching (featuresRoot <> "/*/Page.purs")
  results <- for pages \pagePath -> do
    let viewPath = (fromMaybe pagePath (CodeUnits.stripSuffix (Pattern "Page.purs") pagePath)) <> "View.purs"
    present <- liftEffect $ exists viewPath
    pure if present then Nothing else Just pagePath
  pure (mapMaybe identity results)
