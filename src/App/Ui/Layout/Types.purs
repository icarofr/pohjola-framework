-- | Shared layout types and action targets
module App.Ui.Layout.Types where

import Prelude

import Data.I18n (Lang)
import Data.Route (Route)

-- | Unified action target for all layout templates
data ActionTarget
  = Internal { lang :: Lang, route :: Route }
  | External { href :: String }

derive instance eqActionTarget :: Eq ActionTarget
