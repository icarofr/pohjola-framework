-- | FFI example: Node.js crypto.randomUUID
-- |
-- | Idiomatic PS FFI pattern: typed signature in .purs, minimal .js, newtype wrapper.
-- | The .purs signature IS the contract. For JS functions returning objects,
-- | return `Effect Foreign` and decode with `purescript-foreign` (same decode-at-boundary
-- | pattern as HTTP JSON). See guide §14.
module App.Crypto where

import Prelude

import Data.Newtype (class Newtype)
import Effect (Effect)

-- | UUID newtype — prevents confusing a UUID with any other String
newtype Uuid = Uuid String

derive instance newtypeUuid :: Newtype Uuid _
derive newtype instance showUuid :: Show Uuid
derive newtype instance eqUuid :: Eq Uuid
derive newtype instance ordUuid :: Ord Uuid

-- | Generate a cryptographically random UUID.
-- | FFI returns a String (primitive — no Foreign decoding needed).
-- | For JS functions returning objects, use `Effect Foreign` + `purescript-foreign`.
foreign import randomUUIDImpl :: Effect String

randomUUID :: Effect Uuid
randomUUID = map Uuid randomUUIDImpl
