-- | Email address newtype with a smart constructor.
-- | Lifted to Data.Email so Config, Email, and Form share one validated type.
module Data.Email
  ( EmailAddress(..)
  , mkEmailAddress
  , unEmailAddress
  ) where

import Prelude
import Data.Maybe (Maybe(..))
import Data.String.Common (split, trim)
import Data.String.Pattern (Pattern(..))
import Data.String.CodeUnits (length)

newtype EmailAddress = EmailAddress String

derive newtype instance eqEmailAddress :: Eq EmailAddress
derive newtype instance showEmailAddress :: Show EmailAddress

-- | Deliberately simple: trimmed, exactly one "@", non-empty local and domain.
mkEmailAddress :: String -> Maybe EmailAddress
mkEmailAddress input =
  let
    trimmed = trim input
  in
    case split (Pattern "@") trimmed of
      [ local, domain ] | length local > 0 && length domain > 0 -> Just (EmailAddress trimmed)
      _ -> Nothing

unEmailAddress :: EmailAddress -> String
unEmailAddress (EmailAddress s) = s
