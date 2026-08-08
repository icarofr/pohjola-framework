-- | Example domain type with Generic snake_case decoding.
-- |
-- | Bare record with camelCase fields. Adding a field = add it to the record.
-- | No codec, no newtype, no unwrap. decodeRecordSnake handles the rest.
-- |
-- |   type Product = { id :: Int, name :: String, price :: Number }
-- |   decodeRecordSnake json :: Either _ Product
-- |
-- | For types where JSON shape ≠ domain shape (e.g. M2M junctions),
-- | use a Raw type + normalise function. This module is an intentional
-- | exemplar for template users — see AGENTS.md "Exemplar modules".
module Data.Example where

import Data.Maybe (Maybe)

type Product =
  { id :: Int
  , name :: String
  , description :: Maybe String
  , price :: Number
  , inStock :: Maybe Boolean
  }
