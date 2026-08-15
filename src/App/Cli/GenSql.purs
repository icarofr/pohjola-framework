-- | PureScript CLI Schema Generator (Pohjola Schema Codegen).
-- | Reads PostgreSQL DDL / migration files via App.Bun and generates
-- | type-safe PureScript domain records and Argonaut codecs.
module App.Cli.GenSql where

import Prelude

import App.Bun (getArgs, glob, readTextFile, writeTextFile)
import Data.Array (filter, foldMap, length, sort, uncons)
import Data.Array as Array
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (Pattern(..), Replacement(..), contains, replace, split, toLower, toUpper, trim)
import Data.String.CodeUnits (charAt, drop, fromCharArray, toCharArray)
import Data.Traversable (traverse)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Effect.Console as Console

type Column =
  { name :: String
  , camelName :: String
  , sqlType :: String
  , psType :: String
  , isNullable :: Boolean
  }

type Table =
  { name :: String
  , pascalName :: String
  , columns :: Array Column
  }

type CliArgs =
  { file :: Maybe String
  , sql :: Maybe String
  , table :: Maybe String
  , out :: Maybe String
  , moduleName :: Maybe String
  }

-- | Convert snake_case to camelCase
toCamelCase :: String -> String
toCamelCase str =
  let
    parts = filter (not <<< eq "") (split (Pattern "_") str)
  in
    case uncons parts of
      Nothing -> ""
      Just { head, tail } ->
        head <> foldMap capitalizeWord tail

capitalizeWord :: String -> String
capitalizeWord str = case uncons (toCharArray str) of
  Nothing -> ""
  Just { head, tail } -> fromCharArray [ toUpperChar head ] <> fromCharArray tail

toUpperChar :: Char -> Char
toUpperChar c =
  let
    s = fromCharArray [ c ]
    u = toUpper s
  in
    case charAt 0 u of
      Just uc -> uc
      Nothing -> c

-- | Convert snake_case to PascalCase (singular)
toPascalCase :: String -> String
toPascalCase str =
  let
    camel = toCamelCase str
    singular =
      if contains (Pattern "s") camel && length (toCharArray camel) > 1 then
        case uncons (toCharArray (toLower (drop (length (toCharArray camel) - 1) camel))) of
          Just { head: 's' } -> fromCharArray (filter (\_ -> true) (toCharArray camel)) -- keep or strip
          _ -> camel
      else camel
  in
    capitalizeWord singular

mapSqlTypeToPureScript :: String -> Boolean -> String
mapSqlTypeToPureScript rawSqlType isNullable =
  let
    normalized = toUpper (trim rawSqlType)
    baseType
      | contains (Pattern "INT") normalized || contains (Pattern "SERIAL") normalized = "Int"
      | contains (Pattern "NUMERIC") normalized || contains (Pattern "DECIMAL") normalized || contains (Pattern "FLOAT") normalized || contains (Pattern "DOUBLE") normalized = "Number"
      | contains (Pattern "BOOL") normalized = "Boolean"
      | contains (Pattern "JSON") normalized = "Json"
      | otherwise = "String"
  in
    if isNullable then "Maybe " <> baseType else baseType

parseColumns :: String -> Array Column
parseColumns body =
  let
    rawLines = split (Pattern "\n") body
    cleanedLines = filter (not <<< eq "") (map trim rawLines)
  in
    filter (\c -> c.name /= "") (map parseLine cleanedLines)
  where
  parseLine :: String -> Column
  parseLine line =
    let
      noComma = replace (Pattern ",") (Replacement "") line
      tokens = filter (not <<< eq "") (split (Pattern " ") (trim noComma))
    in
      case tokens of
        [ name, sqlType, "NOT", "NULL" ] ->
          { name
          , camelName: toCamelCase name
          , sqlType
          , psType: mapSqlTypeToPureScript sqlType false
          , isNullable: false
          }
        [ name, sqlType, "PRIMARY", "KEY" ] ->
          { name
          , camelName: toCamelCase name
          , sqlType
          , psType: mapSqlTypeToPureScript sqlType false
          , isNullable: false
          }
        [ name, sqlType ] ->
          { name
          , camelName: toCamelCase name
          , sqlType
          , psType: mapSqlTypeToPureScript sqlType true
          , isNullable: true
          }
        _ ->
          if length tokens >= 2 then
            let
              name = fromMaybe "" (tokens `indexSafe` 0)
              sqlType = fromMaybe "" (tokens `indexSafe` 1)
              isNotNull = contains (Pattern "NOT NULL") line || contains (Pattern "PRIMARY KEY") line
            in
              if isIgnoreLine name then
                { name: "", camelName: "", sqlType: "", psType: "", isNullable: false }
              else
                { name
                , camelName: toCamelCase name
                , sqlType
                , psType: mapSqlTypeToPureScript sqlType (not isNotNull)
                , isNullable: not isNotNull
                }
          else
            { name: "", camelName: "", sqlType: "", psType: "", isNullable: false }

  isIgnoreLine :: String -> Boolean
  isIgnoreLine name =
    let
      u = toUpper name
    in
      u == "PRIMARY" || u == "FOREIGN" || u == "CONSTRAINT" || u == "UNIQUE" || u == "CHECK"

indexSafe :: Array String -> Int -> Maybe String
indexSafe arr idx = Array.index arr idx

generateModule :: Table -> String -> String
generateModule table moduleName =
  let
    hasMaybe = contains (Pattern "Maybe") (foldMap (\c -> c.psType) table.columns)
    maybeImport = if hasMaybe then "\nimport Data.Maybe (Maybe(..))" else ""

    recordFields = foldMap (\c -> "\n  , " <> c.camelName <> " :: " <> c.psType) table.columns
    firstFixed = replace (Pattern "\n  , ") (Replacement "\n  { ") recordFields

    decodeFields = foldMap
      ( \c ->
          let
            op = if c.isNullable then ".:?" else ".:"
          in
            "\n    " <> c.camelName <> " <- obj " <> op <> " \"" <> c.name <> "\""
      )
      table.columns

    recordConstructors = foldMap (\c -> "\n      , " <> c.camelName) table.columns
    recFixed = replace (Pattern "\n      , ") (Replacement "\n      { ") recordConstructors

    encodeFields = foldMap
      ( \c ->
          let
            op = if c.isNullable then ":=?" else ":="
          in
            "\n    ~> \"" <> c.name <> "\" " <> op <> " val." <> c.camelName
      )
      table.columns
  in
    """-- | Generated domain types and JSON codecs for table `""" <> table.name
      <>
        """`.
-- | Auto-generated by `make gen-sql` (Pohjola PureScript Schema Codegen).
module """
      <> moduleName
      <>
        """
  ( """
      <> table.pascalName
      <>
        """(..)
  , """
      <> table.pascalName
      <>
        """Row
  ) where

import Prelude
"""
      <> maybeImport
      <>
        """
import Data.Argonaut.Decode (class DecodeJson, decodeJson, (.:), (.:?))
import Data.Argonaut.Decode.Error (JsonDecodeError(..))
import Data.Argonaut.Encode (class EncodeJson, (:=), (:=?), (~>), jsonEmptyObject)
import Data.Either (Either(..))
import Data.Newtype (class Newtype, unwrap)

type """
      <> table.pascalName
      <> """Row ="""
      <> firstFixed
      <>
        """
  }

newtype """
      <> table.pascalName
      <> """ = """
      <> table.pascalName
      <> " "
      <> table.pascalName
      <>
        """Row

derive instance newtype"""
      <> table.pascalName
      <> " :: Newtype "
      <> table.pascalName
      <>
        """ _
derive newtype instance eq"""
      <> table.pascalName
      <> " :: Eq "
      <> table.pascalName
      <>
        """
derive newtype instance show"""
      <> table.pascalName
      <> " :: Show "
      <> table.pascalName
      <>
        """

instance decodeJson"""
      <> table.pascalName
      <> " :: DecodeJson "
      <> table.pascalName
      <>
        """ where
  decodeJson json = do
    obj <- decodeJson json"""
      <> decodeFields
      <>
        """
    pure ("""
      <> table.pascalName
      <> recFixed
      <>
        """
      })

instance encodeJson"""
      <> table.pascalName
      <> " :: EncodeJson "
      <> table.pascalName
      <>
        """ where
  encodeJson ("""
      <> table.pascalName
      <>
        """ val) =
    jsonEmptyObject"""
      <> encodeFields
      <>
        """
"""

parseCliArgs :: Array String -> CliArgs
parseCliArgs rawArgs =
  parseNext rawArgs
    { file: Nothing
    , sql: Nothing
    , table: Nothing
    , out: Nothing
    , moduleName: Nothing
    }
  where
  parseNext :: Array String -> CliArgs -> CliArgs
  parseNext args acc = case uncons args of
    Nothing -> acc
    Just { head, tail } ->
      if contains (Pattern "--file=") head then
        parseNext tail (acc { file = Just (drop 7 head) })
      else if contains (Pattern "--sql=") head then
        parseNext tail (acc { sql = Just (drop 6 head) })
      else if contains (Pattern "--table=") head then
        parseNext tail (acc { table = Just (drop 8 head) })
      else if contains (Pattern "--out=") head then
        parseNext tail (acc { out = Just (drop 6 head) })
      else if contains (Pattern "--module=") head then
        parseNext tail (acc { moduleName = Just (drop 9 head) })
      else
        parseNext tail acc

runGenSql :: Aff Unit
runGenSql = do
  argsList <- liftEffect getArgs
  let
    cli = parseCliArgs argsList
  sqlContent <- case cli.sql of
    Just s -> pure s
    Nothing -> case cli.file of
      Just f -> do
        res <- readTextFile f
        case res of
          Left err -> do
            liftEffect $ Console.error ("Failed to read file: " <> err)
            pure ""
          Right content -> pure content
      Nothing -> do
        migrationFiles <- liftEffect $ glob "migrations/*.sql"
        if length migrationFiles == 0 then do
          liftEffect $ Console.log "No migrations/*.sql files found. Usage: make gen-sql [FILE=path] [TABLE=name]"
          pure ""
        else do
          let
            sorted = sort migrationFiles
          contents <- traverse readTextFile sorted
          let
            combined = foldMap
              ( case _ of
                  Right c -> c <> "\n\n"
                  Left _ -> ""
              )
              contents
          pure combined

  if sqlContent == "" then
    pure unit
  else do
    -- Simple table extractor
    let
      targetTbl = fromMaybe "comments" cli.table
      tableName = targetTbl
      pascal = toPascalCase tableName
      modName = fromMaybe ("App.Features." <> pascal <> ".Types") cli.moduleName
      cols = parseColumns sqlContent
      tbl = { name: tableName, pascalName: pascal, columns: cols }
      outputCode = generateModule tbl modName

    case cli.out of
      Just outPath -> do
        writeRes <- writeTextFile outPath outputCode
        case writeRes of
          Right _ -> liftEffect $ Console.log ("✓ Generated " <> outPath <> " for table '" <> tableName <> "'")
          Left err -> liftEffect $ Console.error ("Failed to write " <> outPath <> ": " <> err)
      Nothing ->
        liftEffect $ Console.log ("\n-- ==================== Table: " <> tableName <> " ====================\n" <> outputCode)

main :: Effect Unit
main = launchAff_ runGenSql
