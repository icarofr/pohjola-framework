-- | Environment variable access via Node.Process (no FFI)
module App.Env where

import Prelude

import Data.Maybe (Maybe, fromMaybe)
import Effect (Effect)
import Node.Process (lookupEnv)

-- | Read an environment variable. Returns "" if not set.
getEnv :: String -> Effect String
getEnv key = fromMaybe "" <$> lookupEnv key

-- | Read an environment variable, returning Maybe.
getEnvMaybe :: String -> Effect (Maybe String)
getEnvMaybe = lookupEnv

-- | Read an environment variable with a default value.
getEnvDefault :: String -> String -> Effect String
getEnvDefault key def = fromMaybe def <$> lookupEnv key
