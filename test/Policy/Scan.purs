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
  , findFilesMatching
  , findForbiddenInFiles
  , findForeignImportsOutsideAllowlist
  , findRawAlpineOutsideAlpine
  , findRawInSrc
  , findScriptsOutsideAllowlist
  , findUnknownUiClassTokens
  , pursFilesUnder
  ) where

import Prelude

import App.Bun (glob, readTextFile)
import Data.Array (concat, drop, elem, filter, last, length, mapMaybe, nub, uncons)
import Data.Char (toCharCode)
import Data.Either (Either(..))
import Data.Foldable (all, any)
import Data.Maybe (Maybe(..))
import Data.String as String
import Data.String.Common (split) as Common
import Data.String.CodeUnits (fromCharArray, stripPrefix, toCharArray) as CodeUnits
import Data.String.Pattern (Pattern(..))
import Data.Traversable (for)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)

pursFilesUnder :: String -> Effect (Array String)
pursFilesUnder dir = glob (dir <> "/**/*.purs")

findFilesMatching :: String -> Effect (Array String)
findFilesMatching pattern = glob pattern

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

-- | Class tokens in App.Ui quoted strings that are not on the closed allowlist.
findUnknownUiClassTokens :: Array String -> String -> Aff (Array String)
findUnknownUiClassTokens allowlist root = do
  files <- liftEffect $ pursFilesUnder root
  results <- for files \file -> do
    content <- readTextFile file
    pure case content of
      Right c -> filter (\tok -> not (elem tok allowlist)) (classTokensInSource c)
      Left _ -> []
  pure (nub (concat results))

classTokensInSource :: String -> Array String
classTokensInSource source =
  let
    chunks = drop 1 (Common.split (Pattern "class_ \"") source)
  in
    nub (concat (map classChunkTokens chunks))

classChunkTokens :: String -> Array String
classChunkTokens chunk =
  case String.indexOf (Pattern "\"") chunk of
    Nothing -> []
    Just i -> tokensFromQuoted (String.take i chunk)

tokensFromQuoted :: String -> Array String
tokensFromQuoted quoted =
  let
    parts = filter (_ /= "") (Common.split (Pattern " ") quoted)
  in
    if all isExtractedClassToken parts then
      parts
    else
      []

isExtractedClassToken :: String -> Boolean
isExtractedClassToken tok =
  not (startsWith "aria-" tok)
    && not (endsWithDash tok)
    && isClassCharset tok
    && hasLetter tok
    &&
      ( containsSubstring "-" tok
          || containsSubstring ":" tok
          || containsSubstring "/" tok
          || containsSubstring "[" tok
          || elem tok unhyphenatedClassWords
      )

hasLetter :: String -> Boolean
hasLetter s =
  any
    ( \c ->
        let
          n = toCharCode c
        in
          n >= 97 && n <= 122
    )
    (CodeUnits.toCharArray s)

unhyphenatedClassWords :: Array String
unhyphenatedClassWords =
  [ "absolute"
  , "alert"
  , "avatar"
  , "badge"
  , "block"
  , "border"
  , "btn"
  , "card"
  , "collapse"
  , "container"
  , "contents"
  , "divider"
  , "fieldset"
  , "fixed"
  , "flex"
  , "grid"
  , "grow"
  , "hero"
  , "hidden"
  , "inline"
  , "input"
  , "menu"
  , "modal"
  , "navbar"
  , "prose"
  , "shrink"
  , "stat"
  , "stats"
  , "sticky"
  , "tab"
  , "tabs"
  , "textarea"
  , "toast"
  , "truncate"
  , "uppercase"
  ]

startsWith :: String -> String -> Boolean
startsWith prefix s =
  case CodeUnits.stripPrefix (Pattern prefix) s of
    Just _ -> true
    Nothing -> false

endsWithDash :: String -> Boolean
endsWithDash s =
  last (CodeUnits.toCharArray s) == Just '-'

isClassCharset :: String -> Boolean
isClassCharset tok =
  tok /= ""
    && all isClassChar (CodeUnits.toCharArray tok)

isClassChar :: Char -> Boolean
isClassChar c =
  let
    n = toCharCode c
  in
    (n >= 48 && n <= 57)
      || (n >= 97 && n <= 122)
      || n == 45
      || n == 58
      || n == 47
      || n == 91
      || n == 93
