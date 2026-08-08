-- | Generic JSON decoding with camelCase → snake_case field name transform.
-- |
-- | Idiomatic Haskell approach: one `camelToSnake` function shared across all
-- | types. Adding a field to a record is the only change needed — no per-field
-- | codec boilerplate.
-- |
-- | Usage:
-- |   type Team = { id :: Int, name :: String, shortName :: Maybe String }
-- |   decodeRecordSnake json :: Either _ Team
-- |
-- | For newtypes that need custom logic (e.g. M2M junction unwrapping):
-- |   newtype Event = Event { ... }
-- |   instance DecodeJson Event where
-- |     decodeJson = map Event <<< decodeRecordSnake
module Data.Codec.Argonaut.Snake where

import Prelude

import Data.Argonaut.Core (Json, isNull, toObject)
import Data.Argonaut.Decode.Class (class DecodeJson, decodeJson)
import Data.Argonaut.Decode.Error (JsonDecodeError(..))
import Data.Bifunctor (lmap)
import Data.Char (toCharCode, fromCharCode)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Either (Either(..))
import Data.Array (uncons, cons)
import Data.String.CodeUnits (fromCharArray, toCharArray)
import Data.Symbol (class IsSymbol, reflectSymbol)
import Foreign.Object (Object)
import Foreign.Object as FO
import Prim.Row as Row
import Prim.RowList as RL
import Record as Record
import Type.Proxy (Proxy(..))

-- | Convert camelCase to snake_case: "shortName" → "short_name"
camelToSnake :: String -> String
camelToSnake = fromCharArray <<< go <<< toCharArray
  where
  go arr = case uncons arr of
    Nothing -> []
    Just { head: c, tail: rest } ->
      cons (toLowerC c) (goSnake rest)

  goSnake arr = case uncons arr of
    Nothing -> []
    Just { head: c, tail: rest }
      | isUpperC c -> cons '_' (cons (toLowerC c) (goSnake rest))
      | otherwise -> cons (toLowerC c) (goSnake rest)

  isUpperC c = c >= 'A' && c <= 'Z'
  toLowerC c = if isUpperC c then fromMaybe c (fromCharCode (toCharCode c + 32)) else c

-- | Generic decode class — like GDecodeJson but applies camelToSnake to field names
class GDecodeJsonSnake (row :: Row Type) (list :: RL.RowList Type) | list -> row where
  gDecodeJsonSnake :: Object Json -> Proxy list -> Either JsonDecodeError (Record row)

instance gDecodeJsonSnakeNil :: GDecodeJsonSnake () RL.Nil where
  gDecodeJsonSnake _ _ = Right {}

instance gDecodeJsonSnakeCons ::
  ( DecodeJsonFieldSnake value
  , GDecodeJsonSnake rowTail tail
  , IsSymbol field
  , Row.Cons field value rowTail row
  , Row.Lacks field rowTail
  ) =>
  GDecodeJsonSnake row (RL.Cons field value tail) where
  gDecodeJsonSnake object _ = do
    let
      _field = Proxy :: Proxy field
      fieldName = camelToSnake (reflectSymbol _field)
      fieldValue = FO.lookup fieldName object
    case decodeJsonFieldSnake fieldValue of
      Just fieldVal -> do
        val <- lmap (AtKey fieldName) fieldVal
        rest <- gDecodeJsonSnake object (Proxy :: Proxy tail)
        Right $ Record.insert _field val rest
      Nothing ->
        Left $ AtKey fieldName MissingValue

-- | Like DecodeJsonField but handles null → Nothing for Maybe fields
class DecodeJsonFieldSnake a where
  decodeJsonFieldSnake :: Maybe Json -> Maybe (Either JsonDecodeError a)

instance decodeFieldSnakeMaybe ::
  DecodeJson a =>
  DecodeJsonFieldSnake (Maybe a) where
  decodeJsonFieldSnake Nothing = Just $ Right Nothing
  decodeJsonFieldSnake (Just j) | isNull j = Just $ Right Nothing
  decodeJsonFieldSnake (Just j) = Just $ decodeJson j

else instance decodeFieldSnakeId ::
  DecodeJson a =>
  DecodeJsonFieldSnake a where
  decodeJsonFieldSnake j = decodeJson <$> j

-- | Decode a JSON object into a Record with camelCase fields from snake_case JSON keys.
-- | Works on bare record types — no newtype wrapper needed.
decodeRecordSnake :: forall row list. RL.RowToList row list => GDecodeJsonSnake row list => Json -> Either JsonDecodeError (Record row)
decodeRecordSnake json =
  case toObject json of
    Just object -> gDecodeJsonSnake object (Proxy :: Proxy list)
    Nothing -> Left $ TypeMismatch "Object"
