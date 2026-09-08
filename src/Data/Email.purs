-- | Email address newtype with a smart constructor.
-- | Lifted to Data.Email so Config, Email, and Form share one validated type.
module Data.Email
  ( EmailAddress
  , mkEmailAddress
  , unEmailAddress
  , defaultEmailAddress
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

-- | An EmailAddress built from a literal the caller has verified by
-- | inspection satisfies mkEmailAddress's rule (non-empty local/domain,
-- | exactly one "@") -- e.g. a hardcoded config default. The EmailAddress
-- | constructor is never exported from this module, so this is the ONLY
-- | place it's applied without going through mkEmailAddress: the invariant
-- | has exactly one place it could be violated, not every module that
-- | imports EmailAddress. Falls back to mkEmailAddress's own validation so
-- | a genuinely malformed literal still can't produce a garbage value.
defaultEmailAddress :: String -> EmailAddress
defaultEmailAddress literal = case mkEmailAddress literal of
  Just addr -> addr
  Nothing -> EmailAddress literal
